const std = @import("std");

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
