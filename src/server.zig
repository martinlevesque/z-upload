const std = @import("std");

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

        var ip_array: [4]u8 = undefined;
        var it = std.mem.split(u8, host, ".");
        var i: usize = 0;

        while (it.next()) |octet| {
            ip_array[i] = try std.fmt.parseUnsigned(u8, octet, 10);
            i += 1;
        }
        const address = std.net.Address.initIp4(ip_array, port);

        var server = std.net.StreamServer.init(.{ .reuse_address = true });
        try server.listen(address);

        return Server{ .host = host, .port = port, .stream_server = server };
    }

    pub fn deinit(self: *Server) void {
        self.stream_server.deinit();
    }
};

test "create" {}
