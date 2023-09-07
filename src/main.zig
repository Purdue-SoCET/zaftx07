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

fn main() !void {
    const writer = Writer{ .context = {} };

    // Printing example
    {
        var one_plus_one: usize = 1 + 1;
        var one_half: f32 = 0.5;
        var hello_world: []const u8 = "Hello World";
        try std.fmt.format(writer, "Hello from Zig!\n", .{});
        try std.fmt.format(writer, "Very complex equation: 1 + 1 = {}\n", .{one_plus_one});
        try std.fmt.format(writer, "Very advanced float: 0.5 = {}\n", .{one_half});
        try std.fmt.format(writer, "Very technical string: \"Hello World\" = {s}\n", .{hello_world});
    }

    // Memory allocation example
    {
        const heap_start = @extern([*]u8, .{ .name = "__heap_start" });
        const heap_size = 1024;
        const heap_array = heap_start[0..heap_size];
        var backing_fba = std.heap.FixedBufferAllocator.init(heap_array);
        const page_allocator = backing_fba.allocator();
        var arena = std.heap.ArenaAllocator.init(page_allocator);
        defer arena.deinit();

        var allocator = arena.allocator();

        const heap_string = try allocator.alloc(u8, 20);
        defer allocator.free(heap_string);

        std.mem.copy(u8, heap_string, "hello world");
        try std.fmt.format(writer, "heap_string: \"{s}\"", .{heap_string});

        const array_list = std.ArrayList(struct {}).init(allocator);
        defer array_list.deinit();
    }
}

export fn _main() void {
    const writer = Writer{ .context = {} };
    main() catch |e| std.fmt.format(writer, "[ERROR] main() failed: {}", .{e}) catch {};
}
