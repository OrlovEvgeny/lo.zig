const std = @import("std");
const lo = @import("lo");

const WARMUP: usize = 100;
const ITERATIONS: usize = 10_000;

pub fn main() !void {
    const stdout = std.fs.File.stdout().deprecatedWriter();
    const allocator = std.heap.page_allocator;

    // Generate input data: 1,000 u32 elements
    var input_data: [1000]u32 = undefined;
    for (&input_data, 0..) |*v, i| {
        v.* = @as(u32, @intCast(i)) *% 7919 +% 42;
    }

    // Generate 100 strings (~20 chars each) for join benchmark
    var string_bufs: [100][20]u8 = undefined;
    var string_slices: [100][]const u8 = undefined;
    for (&string_bufs, &string_slices, 0..) |*buf, *slice_ptr, i| {
        const written = std.fmt.bufPrint(buf, "test-string-item-{d:0>2}", .{i}) catch buf;
        slice_ptr.* = written;
    }

    // Print header
    try stdout.print("{s:<20} {s:>12} {s:>12} {s:>8}\n", .{
        "Function", "lo.zig ns/op", "std ns/op", "Ratio",
    });
    try stdout.print("{s:-<20} {s:->12} {s:->12} {s:->8}\n", .{
        "", "", "", "",
    });

    // 1. sortBy benchmark
    {
        const original = input_data;

        // lo.sortBy warmup + timed
        var items_copy = original;
        for (0..WARMUP) |_| {
            items_copy = original;
            lo.sortBy(u32, u32, &items_copy, &identityU32);
            std.mem.doNotOptimizeAway(&items_copy);
        }
        var timer = try std.time.Timer.start();
        for (0..ITERATIONS) |_| {
            items_copy = original;
            lo.sortBy(u32, u32, &items_copy, &identityU32);
            std.mem.doNotOptimizeAway(&items_copy);
        }
        const lo_ns = timer.read() / ITERATIONS;

        // std.sort.block warmup + timed
        for (0..WARMUP) |_| {
            items_copy = original;
            std.sort.block(u32, &items_copy, {}, std.sort.asc(u32));
            std.mem.doNotOptimizeAway(&items_copy);
        }
        timer = try std.time.Timer.start();
        for (0..ITERATIONS) |_| {
            items_copy = original;
            std.sort.block(u32, &items_copy, {}, std.sort.asc(u32));
            std.mem.doNotOptimizeAway(&items_copy);
        }
        const std_ns = timer.read() / ITERATIONS;

        try printRow(stdout, "sortBy", lo_ns, std_ns);
    }

    // 2. filter (filterAlloc) benchmark
    {
        const items: []const u32 = &input_data;

        // lo.filterAlloc warmup + timed
        for (0..WARMUP) |_| {
            const result = try lo.filterAlloc(u32, allocator, items, &isEvenU32);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        var timer = try std.time.Timer.start();
        for (0..ITERATIONS) |_| {
            const result = try lo.filterAlloc(u32, allocator, items, &isEvenU32);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        const lo_ns = timer.read() / ITERATIONS;

        // std equivalent: ArrayList loop
        for (0..WARMUP) |_| {
            const result = try filterManual(u32, allocator, items, &isEvenU32);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        timer = try std.time.Timer.start();
        for (0..ITERATIONS) |_| {
            const result = try filterManual(u32, allocator, items, &isEvenU32);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        const std_ns = timer.read() / ITERATIONS;

        try printRow(stdout, "filter", lo_ns, std_ns);
    }

    // 3. map (mapAlloc) benchmark
    {
        const items: []const u32 = &input_data;

        // lo.mapAlloc warmup + timed
        for (0..WARMUP) |_| {
            const result = try lo.mapAlloc(u32, u64, allocator, items, &doubleU32);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        var timer = try std.time.Timer.start();
        for (0..ITERATIONS) |_| {
            const result = try lo.mapAlloc(u32, u64, allocator, items, &doubleU32);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        const lo_ns = timer.read() / ITERATIONS;

        // std equivalent: manual alloc + for loop
        for (0..WARMUP) |_| {
            const result = try mapManual(u32, u64, allocator, items, &doubleU32);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        timer = try std.time.Timer.start();
        for (0..ITERATIONS) |_| {
            const result = try mapManual(u32, u64, allocator, items, &doubleU32);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        const std_ns = timer.read() / ITERATIONS;

        try printRow(stdout, "map", lo_ns, std_ns);
    }

    // 4. concat benchmark
    {
        const s1: []const u32 = input_data[0..250];
        const s2: []const u32 = input_data[250..500];
        const s3: []const u32 = input_data[500..750];
        const s4: []const u32 = input_data[750..1000];
        const slices: []const []const u32 = &.{ s1, s2, s3, s4 };

        // lo.concat warmup + timed
        for (0..WARMUP) |_| {
            const result = try lo.concat(u32, allocator, slices);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        var timer = try std.time.Timer.start();
        for (0..ITERATIONS) |_| {
            const result = try lo.concat(u32, allocator, slices);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        const lo_ns = timer.read() / ITERATIONS;

        // std.mem.concat warmup + timed
        for (0..WARMUP) |_| {
            const result = try std.mem.concat(allocator, u32, slices);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        timer = try std.time.Timer.start();
        for (0..ITERATIONS) |_| {
            const result = try std.mem.concat(allocator, u32, slices);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        const std_ns = timer.read() / ITERATIONS;

        try printRow(stdout, "concat", lo_ns, std_ns);
    }

    // 5. join benchmark
    {
        const strings: []const []const u8 = &string_slices;

        // lo.join warmup + timed
        for (0..WARMUP) |_| {
            const result = try lo.join(allocator, ", ", strings);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        var timer = try std.time.Timer.start();
        for (0..ITERATIONS) |_| {
            const result = try lo.join(allocator, ", ", strings);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        const lo_ns = timer.read() / ITERATIONS;

        // std.mem.join warmup + timed
        for (0..WARMUP) |_| {
            const result = try std.mem.join(allocator, ", ", strings);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        timer = try std.time.Timer.start();
        for (0..ITERATIONS) |_| {
            const result = try std.mem.join(allocator, ", ", strings);
            std.mem.doNotOptimizeAway(result.ptr);
            allocator.free(result);
        }
        const std_ns = timer.read() / ITERATIONS;

        try printRow(stdout, "join", lo_ns, std_ns);
    }
}

fn printRow(writer: anytype, name: []const u8, lo_ns: u64, std_ns: u64) !void {
    const ratio = if (std_ns > 0)
        @as(f64, @floatFromInt(lo_ns)) / @as(f64, @floatFromInt(std_ns))
    else
        0.0;
    try writer.print("{s:<20} {d:>12} {d:>12} {d:>7.2}x\n", .{ name, lo_ns, std_ns, ratio });
}

// Callback functions for lo.zig
fn identityU32(v: u32) u32 {
    return v;
}

fn isEvenU32(v: u32) bool {
    return v % 2 == 0;
}

fn doubleU32(v: u32) u64 {
    return @as(u64, v) * 2;
}

// Manual std equivalents for filter and map
fn filterManual(comptime T: type, allocator: std.mem.Allocator, items: []const T, predicate: *const fn (T) bool) ![]T {
    // Two-pass: count matches, then allocate and fill
    var match_count: usize = 0;
    for (items) |item| {
        if (predicate(item)) match_count += 1;
    }
    const result = try allocator.alloc(T, match_count);
    var idx: usize = 0;
    for (items) |item| {
        if (predicate(item)) {
            result[idx] = item;
            idx += 1;
        }
    }
    return result;
}

fn mapManual(comptime T: type, comptime R: type, allocator: std.mem.Allocator, items: []const T, transform: *const fn (T) R) ![]R {
    const result = try allocator.alloc(R, items.len);
    for (items, 0..) |item, i| {
        result[i] = transform(item);
    }
    return result;
}
