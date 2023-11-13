const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn str_ip_to_array(str_ip: []const u8) ?[4]u8 {
    var ip_array: [4]u8 = undefined;
    var it = std.mem.split(u8, str_ip, ".");
    var i: usize = 0;

    while (it.next()) |octet| {
        var result = std.fmt.parseUnsigned(u8, octet, 10) catch null;

        if (result == null) {
            return null;
        }

        ip_array[i] = result.?;
        i += 1;
    }

    return ip_array;
}

pub const HostPort = struct {
    host: []const u8,
    port: u16,
    allocator: Allocator,

    pub fn init(allocator: Allocator, host: []const u8, port: u16) !HostPort {
        var cloned_host = try allocator.alloc(u8, host.len);
        std.mem.copy(u8, cloned_host, host);

        return HostPort{ .host = cloned_host, .port = port, .allocator = allocator };
    }

    pub fn parse_host_port(allocator: Allocator, host_port_str: []const u8) !HostPort {
        var it = std.mem.split(u8, host_port_str, ":");
        var host: []const u8 = undefined;

        if (it.next()) |given_host| {
            host = given_host;
        } else {
            return error.HostPortMissingHost;
        }

        var port: u16 = 0;

        if (it.next()) |port_str| {
            var result = try std.fmt.parseUnsigned(u16, port_str, 10);

            port = result;
        } else {
            return error.HostPortMissingPort;
        }

        return try HostPort.init(allocator, host, port);
    }

    pub fn deinit(self: *HostPort) void {
        self.allocator.free(self.host);
    }
};

test "str_ip_to_array happy path" {
    var ip = "127.0.0.1";

    var ip_array = str_ip_to_array(ip).?;

    try std.testing.expect(ip_array[0] == 127);
    try std.testing.expect(ip_array[1] == 0);
    try std.testing.expect(ip_array[2] == 0);
    try std.testing.expect(ip_array[3] == 1);
}

test "str_ip_to_array with empty string" {
    var ip_array = str_ip_to_array("");

    try std.testing.expect(ip_array == null);
}

test "HostPort.parse_host_port happy path" {
    const addr = "test:8080";
    const allocator = std.testing.allocator;
    var result = try HostPort.parse_host_port(allocator, addr);
    defer result.deinit();

    try std.testing.expect(std.mem.eql(u8, result.host, "test"));
    try std.testing.expect(result.port == 8080);
}

test "HostPort.parse_host_port case 2" {
    const addr = "123-123:8081";
    const allocator = std.testing.allocator;
    var result = try HostPort.parse_host_port(allocator, addr);
    defer result.deinit();

    try std.testing.expect(std.mem.eql(u8, result.host, "123-123"));
    try std.testing.expect(result.port == 8081);
}

test "HostPort.parse_host_port missing port" {
    const addr = "123-123";
    const allocator = std.testing.allocator;
    const result = HostPort.parse_host_port(allocator, addr);

    //try std.testing.expect(result == null);
    try std.testing.expectError(error.HostPortMissingPort, result);
}
