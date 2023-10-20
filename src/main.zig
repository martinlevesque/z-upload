const std = @import("std");

pub fn main() !void {
    // read number arguments (argc)
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // loop 10 times and print hello world in each loop:
    for (5..10) |i| {
        std.log.info("hello world {d}<->{d}", .{ i, i });
        // print i
        std.log.info("{d}", .{i});
    }
}

test "simple test" {
    //var list = std.ArrayList(i32).init(std.testing.allocator);
    //defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    //try list.append(42);
    //try std.testing.expectEqual(@as(i32, 42), list.pop());
}
