const std = @import("std");

pub const Client = struct {
    input_file_path: []const u8,
    remote_uri: []const u8,

    pub fn create(input_file_path: []const u8, remote_uri: []const u8) Client {
        return Client{ .input_file_path = input_file_path, .remote_uri = remote_uri };
    }
};

test "create" {
    const remote_uri = "localhost:3000@/media/remote.txt";
    const local_file_path = "/media/local.txt";
    const client = Client.create(local_file_path, remote_uri);

    try std.testing.expectEqual(client.input_file_path, local_file_path);
    try std.testing.expectEqual(client.remote_uri, remote_uri);
}
