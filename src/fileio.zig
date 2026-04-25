const std = @import("std");

pub fn read(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        std.debug.print("cannot open file '{s}', error: {s}\n", .{ path, @errorName(err) });
        return err;
    };
    defer file.close();

    const size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, size);
    errdefer allocator.free(buffer);

    _ = try file.readAll(buffer);
    return buffer;
}

pub fn write(path: []const u8, data: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();
    try file.writeAll(data);
}

pub fn get_processed_path(allocator: std.mem.Allocator, input: []const u8, output: ?[]const u8, is_encrypt: bool) ![]const u8 {
    if (output != null) {
        return try allocator.dupe(u8, output.?);
    }

    const suffix = ".filelock";

    if (is_encrypt) {
        return try std.fmt.allocPrint(allocator, "{s}{s}", .{ input, suffix });
    }

    if (std.mem.endsWith(u8, input, suffix)) {
        const stripped = input[0 .. input.len - suffix.len];
        if (stripped.len == 0) return error.EmptyOutputPath;
        return try allocator.dupe(u8, stripped);
    }

    return try allocator.dupe(u8, input);
}
