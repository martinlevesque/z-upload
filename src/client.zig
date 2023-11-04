const std = @import("std");

pub const Client = struct {
    input_file_path: []const u8,
    remote_uri: []const u8, // example: /media/file.txt@hostname:3456
    host: ?[]const u8,
    port: ?u16,

    pub fn init(input_file_path: []const u8, remote_uri: []const u8) !Client {
        const pos_at = std.mem.indexOf(u8, remote_uri, "@");
        const pos_port_delimiter = std.mem.indexOf(u8, remote_uri, ":");

        var host: ?[]const u8 = null;
        var port: ?u16 = null;

        if (pos_at != null and pos_port_delimiter != null) {
            host = remote_uri[pos_at.? + 1 .. pos_port_delimiter.?];

            port = try std.fmt.parseInt(u16, remote_uri[pos_port_delimiter.? + 1 ..], 10);
        } else {
            return error.ClientInvalidRemoteUri;
        }

        return Client{ .input_file_path = input_file_path, .remote_uri = remote_uri, .host = host, .port = port };
    }
};

test "init" {
    const remote_uri = "/media/remote.txt@localhost:3000";
    const local_file_path = "/media/local.txt";
    const client = try Client.init(local_file_path, remote_uri);

    try std.testing.expect(std.mem.eql(u8, client.input_file_path, local_file_path));
    try std.testing.expect(std.mem.eql(u8, client.remote_uri, remote_uri));
    try std.testing.expect(std.mem.eql(u8, client.host.?, "localhost"));
}
