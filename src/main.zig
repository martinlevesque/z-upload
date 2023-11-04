const std = @import("std");
const Client = @import("client.zig").Client;
const Server = @import("server.zig").Server;

// msg parameter
fn usage(msg: []const u8) !void {
    std.log.warn("Usage: z-upload -server|-client <input-file> </file/path@host:port>", .{});

    if (msg.len != 0) {
        std.log.warn("{s}", .{msg});
    }
}

pub fn main() !void {
    // read number arguments (argc)
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try usage("Expected at least one argument, but there were none.");
        return;
    }

    const mode = args[1];

    if (std.mem.eql(u8, mode, "-server")) {
        std.log.info("Server mode", .{});
        const server = try Server.init("127.0.0.1:8888");
        defer server.deinit();

        std.log.info("Listening on {s}:{any}", .{ server.host, server.port });
    } else if (std.mem.eql(u8, mode, "-client")) {
        std.log.info("Client mode", .{});

        if (args.len < 4) {
            try usage("Expected additional arguments");
            return;
        }

        const client = try Client.init(args[2], args[3]);

        // if no @, then fail

        // if no /, then fail
        // if / is the last character, then fail

        const at_pos = std.mem.indexOf(u8, client.remote_uri, "@");

        if (at_pos == null) {
            try usage("Expected @ in remote URI");
            return;
        }

        //const host_part = remote_uri[0..pos_at];

        // print at_post

        //if (at_pos == null) {
        //    std.log.warn("Expected @ in remote URI", .{});
        //    try usage();
        //    return;
        //}

        std.log.info("Input file: {s}", .{client.input_file_path});
        std.log.info("Remote URI: {s}", .{client.remote_uri});

        // const address = std.net.Address.initIp4([4]u8{ 127, 0, 0, 1 }, 8080);

    } else {
        std.log.warn("Unknown mode: {s}", .{mode});
        return;
    }
}

test "simple test" {
    try std.testing.expectEqual(@as(i32, 42), @as(i32, 42));
}
