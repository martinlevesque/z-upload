const std = @import("std");
const net_lib = @import("lib/net.zig");
const file_lib = @import("lib/file.zig");
const fs = std.fs;
const fmt = std.fmt;
const HostPort = net_lib.HostPort;
const Allocator = std.mem.Allocator;

pub const Client = struct {
    input_file_path: []const u8,
    remote_uri: []const u8, // example: /media/file.txt@hostname:3456
    host_port: HostPort,
    remote_file_path: []const u8,
    allocator: Allocator,
    connection_stream: ?std.net.Stream,
    auth_key: ?[]const u8,

    pub fn init(allocator: Allocator, input_file_path: []const u8, remote_uri: []const u8) !Client {
        const pos_at = std.mem.indexOf(u8, remote_uri, "@");

        const env_host_port = std.os.getenv("Z_UPLOAD_HOST_PORT");

        if (pos_at == null and env_host_port == null) {
            return error.ClientMissingAtSign;
        }

        // setup the remote_file_path part
        var remote_file_path: []u8 = undefined;
        var remote_host_port_str: []u8 = undefined;
        defer allocator.free(remote_host_port_str);

        if (pos_at != null) {
            remote_file_path = try allocator.alloc(u8, pos_at.?);
            std.mem.copy(u8, remote_file_path, remote_uri[0..pos_at.?]);

            remote_host_port_str = try allocator.alloc(u8, remote_uri.len - (pos_at.? + 1));
            std.mem.copy(u8, remote_host_port_str, remote_uri[pos_at.? + 1 ..]);
        } else {
            remote_file_path = try allocator.alloc(u8, remote_uri.len);
            std.mem.copy(u8, remote_file_path, remote_uri);

            remote_host_port_str = try allocator.alloc(u8, env_host_port.?.len);
            std.mem.copy(u8, remote_host_port_str, env_host_port.?);
        }

        // host_port part
        var host_port = try HostPort.parse_host_port(allocator, remote_host_port_str);

        return Client{
            .connection_stream = null,
            .allocator = allocator,
            .input_file_path = input_file_path,
            .remote_uri = remote_uri,
            .host_port = host_port,
            .remote_file_path = remote_file_path,
            .auth_key = std.os.getenv("Z_UPLOAD_AUTH_KEY"),
        };
    }

    pub fn deinit(self: *Client) void {
        self.host_port.deinit();
        self.allocator.free(self.remote_file_path);

        if (self.connection_stream != null) {
            defer self.connection_stream.?.close();
        }
    }

    pub fn connect(self: *Client) !void { // std.net.Stream
        const ip_array = net_lib.str_ip_to_array(self.host_port.host);

        if (ip_array == null) {
            return error.HostInvalid;
        }

        const conn_to_address = std.net.Address.initIp4(ip_array.?, self.host_port.port);
        self.connection_stream = try std.net.tcpConnectToAddress(conn_to_address);
    }

    pub fn terminate_connection(self: *Client) void {
        if (self.connection_stream != null) {
            self.connection_stream.?.close();
            self.connection_stream = null;
        }
    }

    pub fn transfer_file(self: *Client, local_filepath: []const u8, remote_filepath: []const u8) !void {
        try self.connect();
        defer self.terminate_connection();

        if (self.auth_key != null) {
            _ = try self.connection_stream.?.write(self.auth_key.?);
        } else {
            _ = try self.connection_stream.?.write("-");
        }

        var status_buf: [1024]u8 = undefined;
        _ = try self.connection_stream.?.read(status_buf[0..]);

        std.log.info("Transferring {s} -> {s}", .{ local_filepath, remote_filepath });

        // send our the remote file path
        _ = try self.connection_stream.?.write(remote_filepath);

        // read the status
        _ = try self.connection_stream.?.read(status_buf[0..]);

        var local_file = try std.fs.cwd().openFile(local_filepath, .{});
        defer local_file.close();
        const stat_file = try local_file.stat();

        const read_buffer_size = 200000;
        var buffer_read: [read_buffer_size]u8 = undefined;
        try local_file.seekTo(0);
        var read_bytes: ?usize = null;
        var total_sent_bytes: usize = 0;
        var last_percentage: f64 = 0.0;

        // while read content
        while (read_bytes == null or read_bytes.? != 0) {
            read_bytes = try local_file.read(buffer_read[0..]);

            if (read_bytes.? > 0) {
                _ = try self.connection_stream.?.write(buffer_read[0..read_bytes.?]);
                total_sent_bytes += read_bytes.?;

                // ratio sent out of stat_file.size
                const percentage = (@as(f64, @floatFromInt(total_sent_bytes)) /
                    @as(f64, @floatFromInt(stat_file.size))) * 100.0;

                if (percentage - last_percentage > 1.0) {
                    std.log.info("sent {d} bytes ({d}%)", .{ total_sent_bytes, percentage });
                    last_percentage = percentage;
                }
            }
        }
    }

    pub fn process(self: *Client) !void {
        var file_dir = try file_lib.evaluate_file_dir(self.allocator, self.input_file_path);
        defer file_dir.deinit();

        if (!file_dir.is_dir) {
            // file reading and sending
            std.log.info("Transmitting file {s}...", .{self.input_file_path});

            var remote_file_dir = try file_lib.evaluate_file_dir(
                self.allocator,
                self.remote_file_path,
            );
            defer remote_file_dir.deinit();

            if (remote_file_dir.is_dir) {
                var remote_filepath = try fmt.allocPrint(
                    self.allocator,
                    "{s}{s}",
                    .{ self.remote_file_path, file_dir.filename.? },
                );
                defer self.allocator.free(remote_filepath);

                try self.transfer_file(self.input_file_path, remote_filepath);
            } else {
                try self.transfer_file(self.input_file_path, self.remote_file_path);
            }
        } else {
            std.log.info("{s} is a directory...", .{self.input_file_path});
            var it = file_dir.directory.iterate();

            while (try it.next()) |entry| {
                var stat = try file_dir.directory.dir.statFile(entry.name);

                if (stat.kind == .directory) {
                    std.log.info("Directory {s} - skipping", .{entry.name});
                } else if (stat.kind == .file) {
                    var remote_filepath = try fmt.allocPrint(
                        self.allocator,
                        "{s}{s}",
                        .{ self.remote_file_path, entry.name },
                    );
                    defer self.allocator.free(remote_filepath);

                    var local_filepath = try fmt.allocPrint(
                        self.allocator,
                        "{s}{s}",
                        .{ self.input_file_path, entry.name },
                    );
                    defer self.allocator.free(local_filepath);

                    try self.transfer_file(local_filepath, remote_filepath);
                }
            }
        }

        std.log.info("client finished.", .{});
    }
};

test "init" {
    const remote_uri = "/media/remote.txt@localhost:3000";
    const local_file_path = "/media/local.txt";
    const allocator = std.testing.allocator;

    var client = try Client.init(allocator, local_file_path, remote_uri);
    defer client.deinit();

    try std.testing.expect(std.mem.eql(u8, client.input_file_path, local_file_path));
    try std.testing.expect(std.mem.eql(u8, client.remote_uri, remote_uri));
    try std.testing.expect(std.mem.eql(u8, client.host_port.host, "localhost"));
}
