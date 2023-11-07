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

    pub fn handle(self: *Server) !void {
        const conn = try self.stream_server.accept();
        defer conn.stream.close();

        var buf: [1024]u8 = undefined;
        const msg_size = try conn.stream.read(buf[0..]);

        std.log.info("received: {s}", .{buf[0..msg_size]});

        // try std.testing.expectEqualStrings(client_msg, buf[0..msg_size]);

        // _ = try conn.stream.write(server_msg);
    }
};

test "init + deinit" {
    const allocator = std.testing.allocator;

    var server = try Server.init(allocator, "127.0.0.1:35000");
    defer server.deinit();
}
