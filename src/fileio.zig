const std = @import("std");

pub fn read(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const size = try file.getEndPos();
    const buf = try allocator.alloc(u8, size);
    errdefer allocator.free(buf);

    _ = try file.readAll(buf);
    return buf;
}

pub fn write(path: []const u8, data: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();
    try file.writeAll(data);
}

pub fn getProcessedPath(allocator: std.mem.Allocator, input: []const u8, output: ?[]const u8, encrypt: bool) ![]const u8 {
    if (output != null) {
        return try allocator.dupe(u8, output.?);
    }

    const suffix = ".filelock";
    if (encrypt) {
        return try std.fmt.allocPrint(allocator, "{s}{s}", .{ input, suffix });
    }

    if (std.mem.endsWith(u8, input, suffix)) {
        return try allocator.dupe(u8, input[0 .. input.len - suffix.len]);
    }

    return try allocator.dupe(u8, input);
}
