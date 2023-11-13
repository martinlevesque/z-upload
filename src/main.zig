const std = @import("std");

const Client = @import("client.zig").Client;
const Server = @import("server.zig").Server;

// msg parameter
fn usage(msg: []const u8) !void {
    std.log.warn("Usage: z-upload -server host:port|-client <input-file> </file/path@host:port>", .{});

    if (msg.len != 0) {
        std.log.warn("{s}", .{msg});
    }
}

fn asyncing(id: u32) void {
    // Sleep for 2 seconds
    std.log.info("hello sleeping! {d}", .{id});
    // sleep is in nanoseconds
    std.time.sleep(2 * 1000 * 1000 * 1000);
    std.log.info("done sleeping! {d}", .{id});
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

        if (args.len < 3) {
            try usage("Expected additional arguments");
            return;
        }

        var server = try Server.init(allocator, args[2]);
        std.log.info("Server initiated...", .{});
        defer server.deinit();

        // while
        while (true) {
            var cur_thread = try server.handle_client();

            // break;
            cur_thread.detach();
        }
    } else if (std.mem.eql(u8, mode, "-client")) {
        std.log.info("Client mode", .{});

        if (args.len < 4) {
            try usage("Expected additional arguments");
            return;
        }

        var client = try Client.init(allocator, args[2], args[3]);
        defer client.deinit();

        std.log.info("about to connect...", .{});
        try client.connect();
        std.log.info("connected...", .{});

        try client.process();
    } else {
        std.log.warn("Unknown mode: {s}", .{mode});
        return;
    }
}

test "simple test" {
    try std.testing.expectEqual(@as(i32, 42), @as(i32, 42));
}
