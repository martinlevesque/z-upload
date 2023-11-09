const std = @import("std");
const net_util = @import("net_util.zig");
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

    pub fn handle_client(self: *Server) !void {
        const conn = try self.stream_server.accept();
        defer conn.stream.close();

        // where the file will be written
        var filepath_to_write: [1024]u8 = undefined;
        const filepath_to_write_size = try conn.stream.read(filepath_to_write[0..]);

        // file status reporting
        // todo should determine if the file already exist, if so, report remaining todo
        // using head -c 1000 testfile.txt | cksum
        _ = try conn.stream.write("ok");

        // then read
        std.log.info("received filepath: {s}", .{filepath_to_write[0..filepath_to_write_size]});
        var local_file = try std.fs.cwd().createFile(filepath_to_write[0..filepath_to_write_size], .{});
        defer local_file.close();

        var buffer: [1024]u8 = undefined;
        var read_size: ?usize = null;

        while (read_size == null or read_size.? != 0) {
            read_size = try conn.stream.read(buffer[0..]);

            if (read_size.? > 0) {
                _ = try local_file.write(buffer[0..read_size.?]);
            }
        }
    }
};

test "init + deinit" {
    const allocator = std.testing.allocator;

    var server = try Server.init(allocator, "127.0.0.1:35000");
    defer server.deinit();
}
