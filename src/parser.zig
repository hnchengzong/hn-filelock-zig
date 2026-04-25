const std = @import("std");

pub fn parse_arguments(
    allocator: std.mem.Allocator,
    args: [][:0]u8,
    file_paths: *std.ArrayList([]const u8),
    output_path: *?[]const u8,
    key: *?[]const u8,
    is_encrypt: *bool,
    is_decrypt: *bool,
    cipher_method: *[]const u8,
) !void {
    var index: usize = 1;
    while (index < args.len) : (index += 1) {
        const current_arg = args[index];

        if (std.mem.eql(u8, current_arg, "-o")) {
            index += 1;
            if (index >= args.len) return error.MissingOutputPath;
            output_path.* = args[index];
            continue;
        }

        if (std.mem.eql(u8, current_arg, "-e")) {
            is_encrypt.* = true;
            continue;
        }

        if (std.mem.eql(u8, current_arg, "-d")) {
            is_decrypt.* = true;
            continue;
        }

        if (std.mem.eql(u8, current_arg, "-m")) {
            index += 1;
            if (index >= args.len) return error.MissingMethod;
            cipher_method.* = args[index];
            continue;
        }

        if (std.mem.eql(u8, current_arg, "-k")) {
            index += 1;
            if (index >= args.len) return error.MissingKey;
            key.* = args[index];
            continue;
        }

        try file_paths.append(allocator, args[index]);
    }
}

pub fn validate_arguments(
    file_paths: [][]const u8,
    key: ?[]const u8,
    is_encrypt: bool,
    is_decrypt: bool,
) void {
    const has_files = file_paths.len > 0;
    const has_key = key != null;
    const valid_mode = is_encrypt != is_decrypt;

    if (has_files and has_key and valid_mode) return;

    std.debug.print("usage: hn_filelock_zig files... -e/-d -k key [-o output]\n", .{});
    std.process.exit(1);
}

pub fn validate_key(key_content: []const u8) void {
    if (key_content.len > 0) return;

    std.debug.print("error: key cannot be empty\n", .{});
    std.process.exit(1);
}
