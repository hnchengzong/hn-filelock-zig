const std = @import("std");
const cipher = @import("cipher.zig");
const file_io = @import("fileio.zig");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_purpose_allocator.deinit();
    const allocator = general_purpose_allocator.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var file_paths = std.ArrayList([]const u8).empty;
    defer file_paths.deinit(allocator);

    var output_path: ?[]const u8 = null;
    var key: ?[]const u8 = null;
    var is_encrypt = false;
    var is_decrypt = false;
    var cipher_method: []const u8 = "xor";

    print_help(args);

    try parse_arguments(allocator, args, &file_paths, &output_path, &key, &is_encrypt, &is_decrypt, &cipher_method);

    validate_arguments(file_paths.items, key, is_encrypt, is_decrypt);

    const key_content = key.?;
    validate_key(key_content);

    try process_files(allocator, file_paths.items, output_path, key_content, is_encrypt, cipher_method);
}

fn print_help(args: [][:0]u8) void {
    if (args.len != 2) return;
    if (!std.mem.eql(u8, args[1], "-h")) return;

    std.debug.print("usage: hn_filelock_zig files... -e/-d -k key [-o output]\n", .{});
    std.debug.print("options:\n", .{});
    std.debug.print("  -e encrypt\n", .{});
    std.debug.print("  -d decrypt\n", .{});
    std.debug.print("  -k key   set encryption key\n", .{});
    std.debug.print("  -o output\n", .{});
    std.debug.print("  -m method(default:xor)  set cipher method(xor/add)\n", .{});
    std.debug.print("  -h help   show this help\n", .{});

    std.process.exit(0);
}

fn parse_arguments(
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

fn validate_arguments(
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

fn validate_key(key_content: []const u8) void {
    if (key_content.len > 0) return;

    std.debug.print("error: key cannot be empty\n", .{});
    std.process.exit(1);
}

fn process_files(
    allocator: std.mem.Allocator,
    file_paths: [][]const u8,
    output_path: ?[]const u8,
    key_content: []const u8,
    is_encrypt: bool,
    cipher_method: []const u8,
) !void {
    for (file_paths) |current_path| {
        std.debug.print("processing: {s}\n", .{current_path});

        const file_data = try file_io.read(allocator, current_path);
        defer allocator.free(file_data);

        run_cipher(file_data, key_content, is_encrypt, cipher_method);

        const target_path = output_path orelse current_path;

        if (std.fs.cwd().access(target_path, .{})) |_| {
            std.debug.print("error: output file '{s}' already exists. Remove it or use a different path.\n", .{target_path});
            return error.FileAlreadyExists;
        } else |err| {
            if (err != error.FileNotFound) return err;
        }

        try file_io.write(target_path, file_data);
        std.debug.print("finished: {s}\n", .{target_path});
    }
}

fn run_cipher(
    data: []u8,
    key: []const u8,
    is_encrypt: bool,
    method: []const u8,
) void {
    std.debug.print("using cipher: {s}\n", .{method});

    if (std.mem.eql(u8, method, "xor")) {
        cipher.xor(data, key);
        return;
    }

    if (std.mem.eql(u8, method, "add") and is_encrypt) {
        cipher.add_encrypt(data, key);
        return;
    }

    if (std.mem.eql(u8, method, "add") and !is_encrypt) {
        cipher.add_decrypt(data, key);
        return;
    }

    std.debug.print("error: unknown method: {s}\n", .{method});
    std.process.exit(1);
}
