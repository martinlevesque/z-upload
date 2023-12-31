const std = @import("std");
const net_util = @import("lib/net.zig");
const file_util = @import("lib/file.zig");
const HostPort = net_util.HostPort;
const Allocator = std.mem.Allocator;

pub const Server = struct {
    stream_server: std.net.StreamServer,
    host_port: HostPort,
    allocator: Allocator,

    pub fn init(allocator: Allocator, listen_to: []const u8) !Server {
        // listen_to: host:port

        var host_port = try HostPort.parse_host_port(allocator, listen_to);
        const ip_array = net_util.str_ip_to_array(host_port.host);

        if (ip_array == null) {
            return error.ServerHostInvalid;
        }

        const address = std.net.Address.initIp4(ip_array.?, host_port.port);

        var server = std.net.StreamServer.init(.{ .reuse_address = true });
        try server.listen(address);

        std.log.info("init listening...", .{});

        return Server{ .allocator = allocator, .host_port = host_port, .stream_server = server };
    }

    pub fn deinit(self: *Server) void {
        self.stream_server.deinit();
        self.host_port.deinit();
    }

    pub fn receive_file(self: *Server, conn_stream: std.net.Stream, server_file_path: []const u8) !void {
        var directory_path = try file_util.folder_given_file(self.allocator, server_file_path);
        defer self.allocator.free(directory_path);

        // ensure create directory
        std.fs.makeDirAbsolute(directory_path) catch {};
        var dir = std.fs.openDirAbsolute(directory_path, .{}) catch {
            return error.ServerFileCreateDirectory;
        };
        defer dir.close();

        var local_file = try std.fs.cwd().createFile(server_file_path, .{});
        defer local_file.close();

        var buffer: [200000]u8 = undefined;
        var read_size: ?usize = null;

        while (read_size == null or read_size.? != 0) {
            read_size = try conn_stream.read(buffer[0..]);

            if (read_size.? > 0) {
                _ = try local_file.write(buffer[0..read_size.?]);
            }
        }
    }

    pub fn deinit_conn_stream(_: *Server, conn_stream: std.net.Stream) void {
        std.log.info("deiniting conn stream.", .{});
        conn_stream.close();
    }

    pub fn process_client(self: *Server, conn_stream: std.net.Stream) !void {
        var recv_auth_key: [1024]u8 = undefined;
        const recv_auth_key_size = try conn_stream.read(recv_auth_key[0..]);

        const server_auth_key = std.os.getenv("Z_UPLOAD_AUTH_KEY");

        if (server_auth_key != null and server_auth_key.?.len > 0) {
            if (!std.mem.eql(u8, recv_auth_key[0..recv_auth_key_size], server_auth_key.?)) {
                _ = try conn_stream.write("invalid-auth-key");
                std.time.sleep(1000000000);
                return error.ServerAuthKeyMismatch;
            }
        }

        _ = try conn_stream.write("recv-auth-key");

        // where the file will be written
        var filepath_to_write: [1024]u8 = undefined;
        const filepath_to_write_size = try conn_stream.read(filepath_to_write[0..]);

        _ = try conn_stream.write("ok");
        std.log.info("status sent ok", .{});

        // then read-write
        const file_to_recv_path = filepath_to_write[0..filepath_to_write_size];
        self.receive_file(conn_stream, file_to_recv_path) catch |err| {
            std.log.err("Unable to receive file {s}. Error: {any}", .{ file_to_recv_path, err });
        };
    }

    pub fn handle_client(self: *Server) !std.Thread {
        const conn = try self.stream_server.accept();

        var thread = try std.Thread.spawn(.{}, Server.process_client, .{ self, conn.stream });

        return thread;
    }
};

test "init + deinit" {
    const allocator = std.testing.allocator;

    var server = try Server.init(allocator, "127.0.0.1:35000");
    defer server.deinit();
}
