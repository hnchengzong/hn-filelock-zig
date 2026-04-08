const std = @import("std");
const cipher = @import("cipher.zig");
const fileio = @import("fileio.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var filePaths: [100][]const u8 = undefined;
    var fileCount: usize = 0;

    var outputPath: ?[]const u8 = null;
    var key: ?[]const u8 = null;
    var isEncrypt = false;
    var isDecrypt = false;
    var method: []const u8 = "xor";

    if (args.len == 2 and std.mem.eql(u8, args[1], "-h")) {
        std.debug.print("usage: hn_filelock_zig files... -e/-d -k key [-o output]\n", .{});
        std.debug.print("options:\n", .{});
        std.debug.print("  -e encrypt\n", .{});
        std.debug.print("  -d decrypt\n", .{});
        std.debug.print("  -k key   set encryption key\n", .{});
        std.debug.print("  -o output\n", .{});
        std.debug.print("  -m method(default:xor)  set cipher method(xor/add)\n", .{});
        std.debug.print("  -h help   show this help\n", .{});
        return;
    }
    var index: usize = 1;
    while (index < args.len) : (index += 1) {
        const current = args[index];

        if (std.mem.eql(u8, current, "-o")) {
            if (index + 1 < args.len) {
                outputPath = args[index + 1];
                index += 1;
            }
        } else if (std.mem.eql(u8, current, "-e")) {
            isEncrypt = true;
        } else if (std.mem.eql(u8, current, "-d")) {
            isDecrypt = true;
        } else if (std.mem.eql(u8, current, "-m")) {
            if (index + 1 < args.len) {
                method = args[index + 1];
                index += 1;
            }
        } else if (std.mem.eql(u8, current, "-k")) {
            if (index + 1 < args.len) {
                key = args[index + 1];
                index += 1;
            }
        } else {
            if (fileCount < filePaths.len) {
                filePaths[fileCount] = current;
                fileCount += 1;
            }
        }
    }

    var i: usize = 0;
    while (i < fileCount) : (i += 1) {
        const path = filePaths[i];
        std.debug.print("processing: {s}\n", .{path});
        const data = try fileio.read(allocator, path);
        defer allocator.free(data);

        std.debug.print("using cipher: {s}\n", .{method});
        if (std.mem.eql(u8, method, "xor")) {
            cipher.xor(data, key.?);
        } else if (std.mem.eql(u8, method, "add")) {
            if (isEncrypt) {
                cipher.add_encrypt(data, key.?);
            } else {
                cipher.add_decrypt(data, key.?);
            }
        } else {
            std.debug.print("error: unknown method: {s}\n", .{method});
            return;
        }
        const targetPath = try fileio.getProcessedPath(allocator, path, outputPath, isEncrypt);
        defer allocator.free(targetPath);
        try fileio.write(targetPath, data);

        std.debug.print("finished: {s}\n", .{targetPath});
    }
}
