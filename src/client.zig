const std = @import("std");
const net_util = @import("net_util.zig");
const HostPort = net_util.HostPort;
const Allocator = std.mem.Allocator;

pub const Client = struct {
    input_file_path: []const u8,
    remote_uri: []const u8, // example: /media/file.txt@hostname:3456
    host_port: HostPort,
    allocator: Allocator,
    connection: ?std.net.Stream,

    pub fn init(allocator: Allocator, input_file_path: []const u8, remote_uri: []const u8) !Client {
        const pos_at = std.mem.indexOf(u8, remote_uri, "@");

        if (pos_at == null) {
            return error.ClientMissingAtSign;
        }

        var host_port = try HostPort.parse_host_port(allocator, remote_uri[pos_at.? + 1 ..]);

        return Client{ .connection = null, .allocator = allocator, .input_file_path = input_file_path, .remote_uri = remote_uri, .host_port = host_port };
    }

    pub fn deinit(self: *Client) void {
        self.host_port.deinit();

        if (self.connection != null) {
            defer self.connection.?.close();
        }
    }

    pub fn connect(self: *Client) !void { // std.net.Stream
        const ip_array = net_util.str_ip_to_array(self.host_port.host);

        if (ip_array == null) {
            return error.HostInvalid;
        }

        const conn_to_address = std.net.Address.initIp4(ip_array.?, self.host_port.port);
        self.connection = try std.net.tcpConnectToAddress(conn_to_address);

        std.log.info("addrr .. {any}", .{conn_to_address});
    }

    pub fn sendMsgToServer(self: *Client) !void {
        _ = try self.connection.?.write("hello world lol.");
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
