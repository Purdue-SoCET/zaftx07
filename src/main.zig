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

pub const os = struct {
    pub const heap = struct {
        const heap_start = @extern([*]u8, .{ .name = "__heap_start" });
        const heap_size = 1024 * 2;
        const heap_array = heap_start[0..heap_size];
        var backing_fba = std.heap.FixedBufferAllocator.init(heap_array);
        pub const page_allocator = backing_fba.allocator();
    };
};

fn main() !void {
    const writer = Writer{ .context = {} };

    // Printing example
    {
        var one_plus_one: usize = 1 + 1;
        // Commented out as float rt routines are quite slow and bloats binary size
        // var one_half: f32 = 0.5;
        var hello_world: []const u8 = "Hello World";
        std.fmt.format(writer, "Hello from Zig!\n", .{}) catch unreachable;
        std.fmt.format(writer, "Very complex equation: 1 + 1 = {}\n", .{one_plus_one}) catch unreachable;
        // std.fmt.format(writer, "Very advanced float: 0.5 = {}\n", .{one_half}) catch unreachable;
        std.fmt.format(writer, "Very technical string: \"Hello World\" = {s}\n", .{hello_world}) catch unreachable;
    }

    // Memory allocation example
    {
        // TODO: safety doesn't work due to debug being very reliant on hosted systems
        var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = false }){};
        defer if (gpa.deinit() == .leak) std.fmt.format(writer, "Memory leak detected!", .{}) catch unreachable;

        var allocator = gpa.allocator();

        const heap_string = allocator.alloc(u8, 20) catch unreachable;
        std.mem.copy(u8, heap_string, "hello world");
        std.fmt.format(writer, "heap_string: \"{s}\"", .{heap_string}) catch unreachable;

        const array_list = std.ArrayList(struct {}).init(allocator);
        defer array_list.deinit();

        defer allocator.free(heap_string);
    }
}

export fn _main() void {
    const writer = Writer{ .context = {} };
    main() catch |e| std.fmt.format(writer, "[ERROR] main() failed: {}", .{e}) catch {};
}
