const std = @import("std");

const Writer = std.io.Writer(void, error{}, write);

fn write(_: void, bytes: []const u8) error{}!usize {
    const magic_addr: *volatile u8 = @ptrFromInt(0xB0000000);
    var bytes_written: usize = 0;

    for (bytes) |c| {
        magic_addr.* = c;
        bytes_written += 1;
    }

    return bytes_written;
}

export fn main() void {
    const writer = Writer{ .context = {} };
    var one_plus_one: usize = 1 + 1;
    var one_half: f32 = 0.5;
    var hello_world: []const u8 = "Hello World";
    std.fmt.format(writer, "Hello from Zig!\n", .{}) catch unreachable;
    std.fmt.format(writer, "Very complex equation: 1 + 1 = {}\n", .{one_plus_one}) catch unreachable;
    std.fmt.format(writer, "Very advanced float: 0.5 = {}\n", .{one_half}) catch unreachable;
    std.fmt.format(writer, "Very technical string: \"Hello World\" = {s}\n", .{hello_world}) catch unreachable;
}
