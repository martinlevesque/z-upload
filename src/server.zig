const std = @import("std");
const net_util = @import("net_util.zig");

pub const Server = struct {
    stream_server: std.net.StreamServer,
    host: []const u8,
    port: u16,

    pub fn init(listen_to: []const u8) !Server {
        // listen_to: host:port

        const pos_port_delimiter = std.mem.indexOf(u8, listen_to, ":");
        var host: []const u8 = undefined;
        var port: u16 = undefined;

        if (pos_port_delimiter != null) {
            host = listen_to[0..pos_port_delimiter.?];

            port = try std.fmt.parseInt(u16, listen_to[pos_port_delimiter.? + 1 ..], 10);
        } else {
            return error.ClientInvalidListenToUri;
        }

        const address = std.net.Address.initIp4(net_util.str_ip_to_array(host), port);

        var server = std.net.StreamServer.init(.{ .reuse_address = true });
        try server.listen(address);

        return Server{ .host = host, .port = port, .stream_server = server };
    }

    pub fn deinit(self: *Server) void {
        self.stream_server.deinit();
    }
};

test "create" {}
