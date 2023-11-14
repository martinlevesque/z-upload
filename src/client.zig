const std = @import("std");
const net_lib = @import("lib/net.zig");
const file_lib = @import("lib/file.zig");
const fs = std.fs;
const HostPort = net_lib.HostPort;
const Allocator = std.mem.Allocator;

pub const Client = struct {
    input_file_path: []const u8,
    remote_uri: []const u8, // example: /media/file.txt@hostname:3456
    host_port: HostPort,
    remote_file_path: []const u8,
    allocator: Allocator,
    connection_stream: ?std.net.Stream,

    pub fn init(allocator: Allocator, input_file_path: []const u8, remote_uri: []const u8) !Client {
        const pos_at = std.mem.indexOf(u8, remote_uri, "@");

        if (pos_at == null) {
            return error.ClientMissingAtSign;
        }

        // setup the remote_file_path part
        const remote_file_path = try allocator.alloc(u8, pos_at.?);
        std.mem.copy(u8, remote_file_path, remote_uri[0..pos_at.?]);

        // host_port part
        var host_port = try HostPort.parse_host_port(allocator, remote_uri[pos_at.? + 1 ..]);

        return Client{
            .connection_stream = null,
            .allocator = allocator,
            .input_file_path = input_file_path,
            .remote_uri = remote_uri,
            .host_port = host_port,
            .remote_file_path = remote_file_path,
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

    pub fn transfer_file(self: *Client, filepath: []const u8) !void {
        var local_file = try std.fs.cwd().openFile(filepath, .{});
        defer local_file.close();

        const read_buffer_size = 200000;
        var buffer_read: [read_buffer_size]u8 = undefined;
        try local_file.seekTo(0);
        var read_bytes: ?usize = null;

        // while read content
        while (read_bytes == null or read_bytes.? != 0) {
            read_bytes = try local_file.read(buffer_read[0..]);

            if (read_bytes.? > 0) {
                _ = try self.connection_stream.?.write(buffer_read[0..read_bytes.?]);
            }
        }
    }

    pub fn process(self: *Client) !void {
        // send our the remote file path
        _ = try self.connection_stream.?.write(self.remote_file_path);

        std.log.info("client has written", .{});
        // read the status
        var status: [1024]u8 = undefined;
        const status_size = try self.connection_stream.?.read(status[0..]);
        std.log.info("status .. {s}", .{status[0..status_size]});

        var file_dir = try file_lib.evaluate_file_dir(self.allocator, self.input_file_path);
        defer file_dir.deinit();

        if (!file_dir.is_dir) {
            // file reading and sending
            std.log.info("Transmitting file {s}...", .{self.input_file_path});
            try self.transfer_file(self.input_file_path);
        } else {
            std.log.info("{s} is a directory...", .{self.input_file_path});
            var it = file_dir.directory.iterate();

            while (try it.next()) |entry| {
                var stat = try file_dir.directory.dir.statFile(entry.name);

                if (stat.kind == .directory) {
                    std.log.info(" [dir!]", .{});
                } else if (stat.kind == .file) {
                    std.log.info(" [file!]", .{});
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
