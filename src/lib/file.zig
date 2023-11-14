
const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;

pub const FileDir = struct {
    directory: fs.IterableDir,
    filename: ?[]const u8,
    is_dir: bool,
    allocator: Allocator,

    pub fn deinit(self: *FileDir) void {
        if (self.filename != null) {
            self.allocator.free(self.filename.?);
        }

        self.directory.close();
    }
};

pub fn evaluate_file_dir(allocator: Allocator, filepath: []const u8) !FileDir {
    // filepath: example /folder/dir.txt
    // returned FileDir must be closed by the caller

    // check ends with /
    const pos_last_slash = std.mem.lastIndexOf(u8, filepath, "/");

    if (pos_last_slash == null) {
        return error.FileNotFound;
    }

    if (pos_last_slash == filepath.len - 1) {
        var dir = try std.fs.cwd().openIterableDir(filepath, .{});

        return FileDir{ .allocator = allocator, .directory = dir, .is_dir = true, .filename = null };
    }

    var directory_path = filepath[0..pos_last_slash.?];
    var dir = try std.fs.cwd().openIterableDir(directory_path, .{});

    // copy after / to f_dir.filename
    const filename = try allocator.alloc(u8, filepath.len - (pos_last_slash.? + 1));
    std.mem.copy(u8, filename, filepath[pos_last_slash.?+1..]);

    return FileDir{ .allocator = allocator, .directory = dir, .is_dir = false, .filename = filename };
}

test "evaluate_file_dir with directory" {
    const allocator = std.testing.allocator;
    var dir = try evaluate_file_dir(allocator, "/tmp/");
    defer dir.deinit();

    try std.testing.expect(dir.is_dir);
}