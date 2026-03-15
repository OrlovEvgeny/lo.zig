const std = @import("std");
const Allocator = std.mem.Allocator;

/// Sum all elements in a slice. Returns 0 for empty slices.
///
/// ```zig
/// lo.sum(i32, &.{ 1, 2, 3, 4 }); // 10
/// ```
pub fn sum(comptime T: type, slice: []const T) T {
    var acc: T = 0;
    for (slice) |v| {
        acc += v;
    }
    return acc;
}

/// Sum elements after applying a transform function.
///
/// ```zig
/// const people = [_]Person{ .{ .age = 20 }, .{ .age = 30 } };
/// lo.sumBy(Person, i32, &people, Person.getAge); // 50
/// ```
pub fn sumBy(
    comptime T: type,
    comptime R: type,
    slice: []const T,
    transform: *const fn (T) R,
) R {
    var acc: R = 0;
    for (slice) |v| {
        acc += transform(v);
    }
    return acc;
}

/// Multiply all elements in a slice. Returns 1 for empty slices.
///
/// ```zig
/// lo.product(i32, &.{ 2, 3, 4 }); // 24
/// ```
pub fn product(comptime T: type, slice: []const T) T {
    var acc: T = 1;
    for (slice) |v| {
        acc *= v;
    }
    return acc;
}

/// Multiply elements after applying a transform function.
pub fn productBy(
    comptime T: type,
    comptime R: type,
    slice: []const T,
    transform: *const fn (T) R,
) R {
    var acc: R = 1;
    for (slice) |v| {
        acc *= transform(v);
    }
    return acc;
}

/// Arithmetic mean of a slice. Returns 0.0 for empty slices.
///
/// ```zig
/// lo.mean(i32, &.{ 2, 4, 6 }); // 4.0
/// ```
pub fn mean(comptime T: type, slice: []const T) f64 {
    if (slice.len == 0) return 0.0;
    var acc: f64 = 0.0;
    for (slice) |v| {
        acc += toF64(T, v);
    }
    return acc / @as(f64, @floatFromInt(slice.len));
}

/// Arithmetic mean after applying a transform function.
pub fn meanBy(
    comptime T: type,
    slice: []const T,
    transform: *const fn (T) f64,
) f64 {
    if (slice.len == 0) return 0.0;
    var acc: f64 = 0.0;
    for (slice) |v| {
        acc += transform(v);
    }
    return acc / @as(f64, @floatFromInt(slice.len));
}

/// Returns the minimum value in a slice, or null if empty.
///
/// ```zig
/// lo.min(i32, &.{ 3, 1, 2 }); // 1
/// ```
pub fn min(comptime T: type, slice: []const T) ?T {
    if (slice.len == 0) return null;
    var result = slice[0];
    for (slice[1..]) |v| {
        if (compare(T, v, result) == .lt) result = v;
    }
    return result;
}

/// Returns the maximum value in a slice, or null if empty.
///
/// ```zig
/// lo.max(i32, &.{ 3, 1, 2 }); // 3
/// ```
pub fn max(comptime T: type, slice: []const T) ?T {
    if (slice.len == 0) return null;
    var result = slice[0];
    for (slice[1..]) |v| {
        if (compare(T, v, result) == .gt) result = v;
    }
    return result;
}

/// Returns the minimum element according to a comparator.
///
/// ```zig
/// lo.minBy(Point, &points, Point.compareByX); // point with smallest x
/// ```
pub fn minBy(
    comptime T: type,
    slice: []const T,
    comparator: *const fn (T, T) std.math.Order,
) ?T {
    if (slice.len == 0) return null;
    var result = slice[0];
    for (slice[1..]) |v| {
        if (comparator(v, result) == .lt) result = v;
    }
    return result;
}

/// Returns the maximum element according to a comparator.
///
/// ```zig
/// lo.maxBy(Point, &points, Point.compareByX); // point with largest x
/// ```
pub fn maxBy(
    comptime T: type,
    slice: []const T,
    comparator: *const fn (T, T) std.math.Order,
) ?T {
    if (slice.len == 0) return null;
    var result = slice[0];
    for (slice[1..]) |v| {
        if (comparator(v, result) == .gt) result = v;
    }
    return result;
}

/// Returns both min and max in a single pass. Null if empty.
///
/// ```zig
/// const mm = lo.minMax(i32, &.{ 5, 1, 9, 3 }).?;
/// // mm.min_val == 1, mm.max_val == 9
/// ```
pub fn minMax(comptime T: type, slice: []const T) ?MinMax(T) {
    if (slice.len == 0) return null;
    var result = MinMax(T){
        .min_val = slice[0],
        .max_val = slice[0],
    };
    for (slice[1..]) |v| {
        if (compare(T, v, result.min_val) == .lt) result.min_val = v;
        if (compare(T, v, result.max_val) == .gt) result.max_val = v;
    }
    return result;
}

pub fn MinMax(comptime T: type) type {
    return struct {
        min_val: T,
        max_val: T,
    };
}

/// Clamp a value to the range [lo, hi].
///
/// ```zig
/// lo.clamp(i32, 15, 0, 10); // 10
/// lo.clamp(i32, -5, 0, 10); // 0
/// lo.clamp(i32, 5, 0, 10);  // 5
/// ```
pub fn clamp(comptime T: type, value: T, lo: T, hi: T) T {
    if (compare(T, value, lo) == .lt) return lo;
    if (compare(T, value, hi) == .gt) return hi;
    return value;
}

/// Allocate a slice containing integers in [start, end).
/// Returns an empty slice when start >= end.
///
/// ```zig
/// const r = try lo.rangeAlloc(i32, allocator, 0, 5);
/// defer allocator.free(r);
/// // r == .{ 0, 1, 2, 3, 4 }
/// ```
pub fn rangeAlloc(
    comptime T: type,
    allocator: Allocator,
    start: T,
    end: T,
) Allocator.Error![]T {
    if (start >= end) {
        return allocator.alloc(T, 0);
    }
    const len: usize = @intCast(end - start);
    const result = try allocator.alloc(T, len);
    var v = start;
    for (result) |*slot| {
        slot.* = v;
        v += 1;
    }
    return result;
}

/// Allocate a slice containing values from start to end (exclusive)
/// with the given step. Returns error.InvalidArgument if step is 0.
///
/// ```zig
/// const r = try lo.rangeWithStepAlloc(i32, allocator, 0, 10, 3);
/// defer allocator.free(r);
/// // r == .{ 0, 3, 6, 9 }
/// ```
pub fn rangeWithStepAlloc(
    comptime T: type,
    allocator: Allocator,
    start: T,
    end: T,
    step: T,
) RangeError![]T {
    if (step == 0) return error.InvalidArgument;
    if (start >= end) {
        return allocator.alloc(T, 0);
    }
    const span: usize = @intCast(end - start);
    const s: usize = @intCast(step);
    const len = (span + s - 1) / s;
    const result = try allocator.alloc(T, len);
    var v = start;
    for (result) |*slot| {
        slot.* = v;
        v += step;
    }
    return result;
}

pub const RangeError = Allocator.Error || error{InvalidArgument};

/// Returns the most frequently occurring value in a slice.
/// When multiple values share the highest frequency, returns the smallest value.
/// Requires allocation for an internal frequency map.
/// Returns null for empty slices.
///
/// ```zig
/// const m = try lo.mode(i32, allocator, &.{ 1, 2, 2, 3, 2 });
/// // m == 2
/// ```
pub fn mode(
    comptime T: type,
    allocator: Allocator,
    slice: []const T,
) Allocator.Error!?T {
    if (slice.len == 0) return null;

    var counts = std.AutoHashMap(T, usize).init(allocator);
    defer counts.deinit();

    for (slice) |v| {
        const entry = try counts.getOrPut(v);
        if (entry.found_existing) {
            entry.value_ptr.* += 1;
        } else {
            entry.value_ptr.* = 1;
        }
    }

    var best: ?T = null;
    var best_count: usize = 0;
    var it = counts.iterator();
    while (it.next()) |entry| {
        const count_val = entry.value_ptr.*;
        const key = entry.key_ptr.*;
        if (count_val > best_count or
            (count_val == best_count and (best == null or
            std.math.order(key, best.?) == .lt)))
        {
            best_count = count_val;
            best = key;
        }
    }
    return best;
}

/// Returns the median of a numeric slice, or null if empty.
/// For odd-length slices, returns the middle element.
/// For even-length slices, returns the average of the two middle elements.
/// Allocates a temporary copy for sorting; the input slice is not mutated.
///
/// ```zig
/// const m = try lo.median(i32, allocator, &.{ 1, 2, 3, 4 });
/// // m == 2.5
/// ```
pub fn median(comptime T: type, allocator: Allocator, slice: []const T) Allocator.Error!?f64 {
    if (slice.len == 0) return null;

    const copy = try allocator.dupe(T, slice);
    defer allocator.free(copy);
    std.mem.sort(T, copy, {}, std.sort.asc(T));

    const mid = slice.len / 2;
    if (slice.len % 2 == 1) {
        return toF64(T, copy[mid]);
    } else {
        return (toF64(T, copy[mid - 1]) + toF64(T, copy[mid])) / 2.0;
    }
}

/// Returns the nth percentile of a numeric slice using linear interpolation.
/// Returns null for empty slices or if p is outside [0, 100].
/// p=0 returns the minimum, p=100 returns the maximum.
/// Allocates a temporary copy for sorting; the input slice is not mutated.
///
/// ```zig
/// const p = try lo.percentile(i32, allocator, &.{ 1, 2, 3, 4, 5 }, 50.0);
/// // p == 3.0
/// ```
pub fn percentile(comptime T: type, allocator: Allocator, slice: []const T, p: f64) Allocator.Error!?f64 {
    if (slice.len == 0) return null;
    if (p < 0.0 or p > 100.0) return null;

    const copy = try allocator.dupe(T, slice);
    defer allocator.free(copy);
    std.mem.sort(T, copy, {}, std.sort.asc(T));

    if (slice.len == 1) return toF64(T, copy[0]);

    const n: f64 = @floatFromInt(slice.len);
    const rank = (p / 100.0) * (n - 1.0);
    const lo_idx: usize = @intFromFloat(@floor(rank));
    const hi_idx: usize = @intFromFloat(@ceil(rank));

    if (lo_idx == hi_idx) return toF64(T, copy[lo_idx]);

    const frac = rank - @floor(rank);
    const lo_val = toF64(T, copy[lo_idx]);
    const hi_val = toF64(T, copy[hi_idx]);
    return lo_val + frac * (hi_val - lo_val);
}

/// Population variance of a numeric slice (N denominator).
/// Returns null for empty slices, 0.0 for single-element slices.
/// Uses a two-pass algorithm: computes mean, then sums squared deviations.
///
/// ```zig
/// lo.variance(i32, &.{ 2, 4, 4, 4, 5, 5, 7, 9 }); // 4.0
/// ```
pub fn variance(comptime T: type, slice: []const T) ?f64 {
    if (slice.len == 0) return null;

    const m = mean(T, slice);
    var acc: f64 = 0.0;
    for (slice) |v| {
        const diff = toF64(T, v) - m;
        acc += diff * diff;
    }
    return acc / @as(f64, @floatFromInt(slice.len));
}

/// Standard deviation of a numeric slice (sqrt of population variance).
/// Returns null for empty slices, 0.0 for single-element slices.
///
/// ```zig
/// lo.stddev(i32, &.{ 2, 4, 4, 4, 5, 5, 7, 9 }); // 2.0
/// ```
pub fn stddev(comptime T: type, slice: []const T) ?f64 {
    const v = variance(T, slice) orelse return null;
    return @sqrt(v);
}

// Comparison and conversion helpers.

fn compare(comptime T: type, a: T, b: T) std.math.Order {
    return std.math.order(a, b);
}

fn toF64(comptime T: type, value: T) f64 {
    return switch (@typeInfo(T)) {
        .int, .comptime_int => @floatFromInt(value),
        .float, .comptime_float => @floatCast(value),
        else => @compileError(
            "toF64: unsupported type " ++ @typeName(T),
        ),
    };
}

// Tests

test "sum: integers" {
    try std.testing.expectEqual(@as(i32, 10), sum(i32, &.{ 1, 2, 3, 4 }));
}

test "sum: empty slice" {
    try std.testing.expectEqual(@as(i32, 0), sum(i32, &.{}));
}

test "sum: single element" {
    try std.testing.expectEqual(@as(i32, 7), sum(i32, &.{7}));
}

test "sum: negative values" {
    try std.testing.expectEqual(@as(i32, -3), sum(i32, &.{ -1, -2, 0 }));
}

test "sumBy: transform then sum" {
    const double = struct {
        fn f(x: i32) i64 {
            return @as(i64, x) * 2;
        }
    }.f;
    try std.testing.expectEqual(
        @as(i64, 12),
        sumBy(i32, i64, &.{ 1, 2, 3 }, double),
    );
}

test "sumBy: empty slice" {
    const identity = struct {
        fn f(x: i32) i32 {
            return x;
        }
    }.f;
    try std.testing.expectEqual(@as(i32, 0), sumBy(i32, i32, &.{}, identity));
}

test "sumBy: single element" {
    const negate = struct {
        fn f(x: i32) i32 {
            return -x;
        }
    }.f;
    try std.testing.expectEqual(
        @as(i32, -5),
        sumBy(i32, i32, &.{5}, negate),
    );
}

test "product: integers" {
    try std.testing.expectEqual(@as(i32, 24), product(i32, &.{ 2, 3, 4 }));
}

test "product: empty slice returns 1" {
    try std.testing.expectEqual(@as(i32, 1), product(i32, &.{}));
}

test "product: single element" {
    try std.testing.expectEqual(@as(i32, 7), product(i32, &.{7}));
}

test "product: contains zero" {
    try std.testing.expectEqual(@as(i32, 0), product(i32, &.{ 1, 0, 3 }));
}

test "productBy: transform then multiply" {
    const double = struct {
        fn f(x: i32) i64 {
            return @as(i64, x) * 2;
        }
    }.f;
    // (2*2) * (3*2) * (4*2) = 4 * 6 * 8 = 192
    try std.testing.expectEqual(
        @as(i64, 192),
        productBy(i32, i64, &.{ 2, 3, 4 }, double),
    );
}

test "productBy: empty slice returns 1" {
    const identity = struct {
        fn f(x: i32) i32 {
            return x;
        }
    }.f;
    try std.testing.expectEqual(
        @as(i32, 1),
        productBy(i32, i32, &.{}, identity),
    );
}

test "productBy: single element" {
    const double = struct {
        fn f(x: i32) i32 {
            return x * 2;
        }
    }.f;
    try std.testing.expectEqual(
        @as(i32, 10),
        productBy(i32, i32, &.{5}, double),
    );
}

test "mean: integers" {
    try std.testing.expectEqual(@as(f64, 4.0), mean(i32, &.{ 2, 4, 6 }));
}

test "mean: empty slice returns 0" {
    try std.testing.expectEqual(@as(f64, 0.0), mean(i32, &.{}));
}

test "mean: single element" {
    try std.testing.expectEqual(@as(f64, 5.0), mean(i32, &.{5}));
}

test "mean: floats" {
    try std.testing.expectEqual(@as(f64, 2.5), mean(f64, &.{ 1.0, 2.0, 3.0, 4.0 }));
}

test "meanBy: transform then average" {
    const asF64 = struct {
        fn f(x: i32) f64 {
            return @floatFromInt(x);
        }
    }.f;
    try std.testing.expectEqual(
        @as(f64, 2.0),
        meanBy(i32, &.{ 1, 2, 3 }, asF64),
    );
}

test "meanBy: empty slice returns 0" {
    const asF64 = struct {
        fn f(x: i32) f64 {
            return @floatFromInt(x);
        }
    }.f;
    try std.testing.expectEqual(@as(f64, 0.0), meanBy(i32, &.{}, asF64));
}

test "meanBy: single element" {
    const doubled = struct {
        fn f(x: i32) f64 {
            return @as(f64, @floatFromInt(x)) * 2.0;
        }
    }.f;
    try std.testing.expectEqual(@as(f64, 10.0), meanBy(i32, &.{5}, doubled));
}

test "min: finds minimum" {
    try std.testing.expectEqual(@as(?i32, 1), min(i32, &.{ 3, 1, 2 }));
}

test "min: empty slice returns null" {
    try std.testing.expectEqual(@as(?i32, null), min(i32, &.{}));
}

test "min: single element" {
    try std.testing.expectEqual(@as(?i32, 42), min(i32, &.{42}));
}

test "min: negative values" {
    try std.testing.expectEqual(@as(?i32, -10), min(i32, &.{ -1, -10, 5 }));
}

test "max: finds maximum" {
    try std.testing.expectEqual(@as(?i32, 3), max(i32, &.{ 3, 1, 2 }));
}

test "max: empty slice returns null" {
    try std.testing.expectEqual(@as(?i32, null), max(i32, &.{}));
}

test "max: single element" {
    try std.testing.expectEqual(@as(?i32, 42), max(i32, &.{42}));
}

test "max: negative values" {
    try std.testing.expectEqual(@as(?i32, 5), max(i32, &.{ -1, -10, 5 }));
}

test "minBy: custom comparator" {
    const Point = struct { x: i32, y: i32 };
    const byX = struct {
        fn f(a: Point, b: Point) std.math.Order {
            return std.math.order(a.x, b.x);
        }
    }.f;
    const pts = [_]Point{
        .{ .x = 3, .y = 0 },
        .{ .x = 1, .y = 0 },
        .{ .x = 2, .y = 0 },
    };
    const result = minBy(Point, &pts, byX).?;
    try std.testing.expectEqual(@as(i32, 1), result.x);
}

test "minBy: empty slice returns null" {
    const cmp = struct {
        fn f(a: i32, b: i32) std.math.Order {
            return std.math.order(a, b);
        }
    }.f;
    try std.testing.expectEqual(@as(?i32, null), minBy(i32, &.{}, cmp));
}

test "minBy: single element" {
    const cmp = struct {
        fn f(a: i32, b: i32) std.math.Order {
            return std.math.order(a, b);
        }
    }.f;
    try std.testing.expectEqual(@as(?i32, 42), minBy(i32, &.{42}, cmp));
}

test "maxBy: custom comparator" {
    const Point = struct { x: i32, y: i32 };
    const byX = struct {
        fn f(a: Point, b: Point) std.math.Order {
            return std.math.order(a.x, b.x);
        }
    }.f;
    const pts = [_]Point{
        .{ .x = 3, .y = 0 },
        .{ .x = 1, .y = 0 },
        .{ .x = 2, .y = 0 },
    };
    const result = maxBy(Point, &pts, byX).?;
    try std.testing.expectEqual(@as(i32, 3), result.x);
}

test "maxBy: empty slice returns null" {
    const cmp = struct {
        fn f(a: i32, b: i32) std.math.Order {
            return std.math.order(a, b);
        }
    }.f;
    try std.testing.expectEqual(@as(?i32, null), maxBy(i32, &.{}, cmp));
}

test "maxBy: single element" {
    const cmp = struct {
        fn f(a: i32, b: i32) std.math.Order {
            return std.math.order(a, b);
        }
    }.f;
    try std.testing.expectEqual(@as(?i32, 42), maxBy(i32, &.{42}, cmp));
}

test "minMax: finds both" {
    const result = minMax(i32, &.{ 5, 1, 9, 3 }).?;
    try std.testing.expectEqual(@as(i32, 1), result.min_val);
    try std.testing.expectEqual(@as(i32, 9), result.max_val);
}

test "minMax: empty slice returns null" {
    try std.testing.expectEqual(
        @as(?MinMax(i32), null),
        minMax(i32, &.{}),
    );
}

test "minMax: single element" {
    const result = minMax(i32, &.{42}).?;
    try std.testing.expectEqual(@as(i32, 42), result.min_val);
    try std.testing.expectEqual(@as(i32, 42), result.max_val);
}

test "minMax: two elements" {
    const result = minMax(i32, &.{ 10, 3 }).?;
    try std.testing.expectEqual(@as(i32, 3), result.min_val);
    try std.testing.expectEqual(@as(i32, 10), result.max_val);
}

test "clamp: within range unchanged" {
    try std.testing.expectEqual(@as(i32, 5), clamp(i32, 5, 0, 10));
}

test "clamp: below range clamped to lo" {
    try std.testing.expectEqual(@as(i32, 0), clamp(i32, -5, 0, 10));
}

test "clamp: above range clamped to hi" {
    try std.testing.expectEqual(@as(i32, 10), clamp(i32, 15, 0, 10));
}

test "clamp: at boundaries" {
    try std.testing.expectEqual(@as(i32, 0), clamp(i32, 0, 0, 10));
    try std.testing.expectEqual(@as(i32, 10), clamp(i32, 10, 0, 10));
}

test "clamp: floats" {
    try std.testing.expectEqual(@as(f64, 0.5), clamp(f64, 0.5, 0.0, 1.0));
    try std.testing.expectEqual(@as(f64, 0.0), clamp(f64, -1.0, 0.0, 1.0));
    try std.testing.expectEqual(@as(f64, 1.0), clamp(f64, 2.0, 0.0, 1.0));
}

test "rangeAlloc: generates range" {
    const r = try rangeAlloc(i32, std.testing.allocator, 0, 5);
    defer std.testing.allocator.free(r);
    try std.testing.expectEqualSlices(i32, &.{ 0, 1, 2, 3, 4 }, r);
}

test "rangeAlloc: start equals end returns empty" {
    const r = try rangeAlloc(i32, std.testing.allocator, 3, 3);
    defer std.testing.allocator.free(r);
    try std.testing.expectEqual(@as(usize, 0), r.len);
}

test "rangeAlloc: start greater than end returns empty" {
    const r = try rangeAlloc(i32, std.testing.allocator, 5, 2);
    defer std.testing.allocator.free(r);
    try std.testing.expectEqual(@as(usize, 0), r.len);
}

test "rangeAlloc: single element" {
    const r = try rangeAlloc(i32, std.testing.allocator, 4, 5);
    defer std.testing.allocator.free(r);
    try std.testing.expectEqualSlices(i32, &.{4}, r);
}

test "rangeWithStepAlloc: generates with step" {
    const r = try rangeWithStepAlloc(
        i32,
        std.testing.allocator,
        0,
        10,
        3,
    );
    defer std.testing.allocator.free(r);
    try std.testing.expectEqualSlices(i32, &.{ 0, 3, 6, 9 }, r);
}

test "rangeWithStepAlloc: step 1 same as rangeAlloc" {
    const r = try rangeWithStepAlloc(
        i32,
        std.testing.allocator,
        0,
        5,
        1,
    );
    defer std.testing.allocator.free(r);
    try std.testing.expectEqualSlices(i32, &.{ 0, 1, 2, 3, 4 }, r);
}

test "rangeWithStepAlloc: step zero returns error" {
    const result = rangeWithStepAlloc(i32, std.testing.allocator, 0, 5, 0);
    try std.testing.expectError(error.InvalidArgument, result);
}

test "rangeWithStepAlloc: step larger than range" {
    const r = try rangeWithStepAlloc(
        i32,
        std.testing.allocator,
        0,
        3,
        10,
    );
    defer std.testing.allocator.free(r);
    try std.testing.expectEqualSlices(i32, &.{0}, r);
}

test "mode: finds most frequent" {
    const m = try mode(i32, std.testing.allocator, &.{ 1, 2, 2, 3, 2 });
    try std.testing.expectEqual(@as(?i32, 2), m);
}

test "mode: empty slice returns null" {
    const m = try mode(i32, std.testing.allocator, &.{});
    try std.testing.expectEqual(@as(?i32, null), m);
}

test "mode: single element" {
    const m = try mode(i32, std.testing.allocator, &.{42});
    try std.testing.expectEqual(@as(?i32, 42), m);
}

test "mode: all same value" {
    const m = try mode(i32, std.testing.allocator, &.{ 5, 5, 5 });
    try std.testing.expectEqual(@as(?i32, 5), m);
}

test "mode: tied frequencies returns smallest value" {
    // All values have frequency 1, smallest should win
    const m = try mode(i32, std.testing.allocator, &.{ 1, 2, 3 });
    try std.testing.expectEqual(@as(?i32, 1), m);
}

test "mode: tie-breaking is insertion-order independent" {
    // Same data reversed — must return same result (1, the smallest)
    const m = try mode(i32, std.testing.allocator, &.{ 3, 2, 1 });
    try std.testing.expectEqual(@as(?i32, 1), m);
}

test "mode: tie-breaking with partial tie" {
    // 5 and 3 each appear twice, 1 appears once; smallest of tied (3) wins
    const m = try mode(i32, std.testing.allocator, &.{ 5, 5, 3, 3, 1 });
    try std.testing.expectEqual(@as(?i32, 3), m);
}

test "median: empty slice returns null" {
    const result = try median(i32, std.testing.allocator, &.{});
    try std.testing.expectEqual(@as(?f64, null), result);
}

test "median: single element" {
    const result = try median(i32, std.testing.allocator, &.{5});
    try std.testing.expectEqual(@as(?f64, 5.0), result);
}

test "median: odd-count slice" {
    const result = (try median(i32, std.testing.allocator, &.{ 1, 3, 2 })).?;
    try std.testing.expectApproxEqAbs(@as(f64, 2.0), result, 1e-10);
}

test "median: even-count slice" {
    const result = (try median(i32, std.testing.allocator, &.{ 1, 2, 3, 4 })).?;
    try std.testing.expectApproxEqAbs(@as(f64, 2.5), result, 1e-10);
}

test "median: floats" {
    const result = (try median(f64, std.testing.allocator, &.{ 1.5, 2.5, 3.5 })).?;
    try std.testing.expectApproxEqAbs(@as(f64, 2.5), result, 1e-10);
}

test "median: negative values" {
    const result = (try median(i32, std.testing.allocator, &.{ -5, -1, -3 })).?;
    try std.testing.expectApproxEqAbs(@as(f64, -3.0), result, 1e-10);
}

test "median: does not mutate input slice" {
    var data = [_]i32{ 3, 1, 2 };
    _ = try median(i32, std.testing.allocator, &data);
    try std.testing.expectEqualSlices(i32, &.{ 3, 1, 2 }, &data);
}

test "percentile: empty slice returns null" {
    const result = try percentile(i32, std.testing.allocator, &.{}, 50.0);
    try std.testing.expectEqual(@as(?f64, null), result);
}

test "percentile: p=0 returns minimum" {
    const result = (try percentile(i32, std.testing.allocator, &.{ 3, 1, 5, 2, 4 }, 0.0)).?;
    try std.testing.expectApproxEqAbs(@as(f64, 1.0), result, 1e-10);
}

test "percentile: p=100 returns maximum" {
    const result = (try percentile(i32, std.testing.allocator, &.{ 3, 1, 5, 2, 4 }, 100.0)).?;
    try std.testing.expectApproxEqAbs(@as(f64, 5.0), result, 1e-10);
}

test "percentile: p=50 on odd-count slice" {
    const result = (try percentile(i32, std.testing.allocator, &.{ 1, 2, 3, 4, 5 }, 50.0)).?;
    try std.testing.expectApproxEqAbs(@as(f64, 3.0), result, 1e-10);
}

test "percentile: p=25 on odd-count slice" {
    const result = (try percentile(i32, std.testing.allocator, &.{ 1, 2, 3, 4, 5 }, 25.0)).?;
    try std.testing.expectApproxEqAbs(@as(f64, 2.0), result, 1e-10);
}

test "percentile: p=75 on odd-count slice" {
    const result = (try percentile(i32, std.testing.allocator, &.{ 1, 2, 3, 4, 5 }, 75.0)).?;
    try std.testing.expectApproxEqAbs(@as(f64, 4.0), result, 1e-10);
}

test "percentile: single element returns that element for any valid p" {
    const result = (try percentile(i32, std.testing.allocator, &.{42}, 50.0)).?;
    try std.testing.expectApproxEqAbs(@as(f64, 42.0), result, 1e-10);
}

test "percentile: p less than 0 returns null" {
    const result = try percentile(i32, std.testing.allocator, &.{ 1, 2, 3 }, -1.0);
    try std.testing.expectEqual(@as(?f64, null), result);
}

test "percentile: p greater than 100 returns null" {
    const result = try percentile(i32, std.testing.allocator, &.{ 1, 2, 3 }, 101.0);
    try std.testing.expectEqual(@as(?f64, null), result);
}

test "percentile: even-count slice uses linear interpolation" {
    // {1, 2, 3, 4}: p=50 -> rank = 0.5 * 3 = 1.5 -> lerp(2,3,0.5) = 2.5
    const result = (try percentile(i32, std.testing.allocator, &.{ 1, 2, 3, 4 }, 50.0)).?;
    try std.testing.expectApproxEqAbs(@as(f64, 2.5), result, 1e-10);
}

test "variance: empty slice returns null" {
    const result = variance(i32, &.{});
    try std.testing.expectEqual(@as(?f64, null), result);
}

test "variance: single element returns 0.0" {
    const result = variance(i32, &.{5}).?;
    try std.testing.expectApproxEqAbs(@as(f64, 0.0), result, 1e-10);
}

test "variance: known value population variance" {
    // {2,4,4,4,5,5,7,9}: mean=5, sum_sq_diff=32, var=32/8=4.0
    const result = variance(i32, &.{ 2, 4, 4, 4, 5, 5, 7, 9 }).?;
    try std.testing.expectApproxEqAbs(@as(f64, 4.0), result, 1e-10);
}

test "variance: floats" {
    // {1.0, 2.0, 3.0, 4.0, 5.0}: mean=3.0, sum_sq_diff=10, var=10/5=2.0
    const result = variance(f64, &.{ 1.0, 2.0, 3.0, 4.0, 5.0 }).?;
    try std.testing.expectApproxEqAbs(@as(f64, 2.0), result, 1e-10);
}

test "variance: all same values returns 0.0" {
    const result = variance(i32, &.{ 7, 7, 7, 7 }).?;
    try std.testing.expectApproxEqAbs(@as(f64, 0.0), result, 1e-10);
}

test "stddev: empty slice returns null" {
    const result = stddev(i32, &.{});
    try std.testing.expectEqual(@as(?f64, null), result);
}

test "stddev: single element returns 0.0" {
    const result = stddev(i32, &.{5}).?;
    try std.testing.expectApproxEqAbs(@as(f64, 0.0), result, 1e-10);
}

test "stddev: known value" {
    // variance({2,4,4,4,5,5,7,9}) = 4.0, stddev = sqrt(4.0) = 2.0
    const result = stddev(i32, &.{ 2, 4, 4, 4, 5, 5, 7, 9 }).?;
    try std.testing.expectApproxEqAbs(@as(f64, 2.0), result, 1e-10);
}

test "stddev: is sqrt of variance" {
    const data = [_]i32{ 1, 3, 5, 7, 9 };
    const v = variance(i32, &data).?;
    const s = stddev(i32, &data).?;
    try std.testing.expectApproxEqAbs(@sqrt(v), s, 1e-10);
}

// inRange tests

test "inRange: value within range returns true" {
    try std.testing.expectEqual(true, inRange(i32, 3, 1, 5));
}

test "inRange: value at start (inclusive) returns true" {
    try std.testing.expectEqual(true, inRange(i32, 1, 1, 5));
}

test "inRange: value at end (exclusive) returns false" {
    try std.testing.expectEqual(false, inRange(i32, 5, 1, 5));
}

test "inRange: value below range returns false" {
    try std.testing.expectEqual(false, inRange(i32, 0, 1, 5));
}

test "inRange: value above range returns false" {
    try std.testing.expectEqual(false, inRange(i32, 10, 1, 5));
}

test "inRange: negative ranges work correctly" {
    try std.testing.expectEqual(true, inRange(i32, -3, -5, -1));
    try std.testing.expectEqual(false, inRange(i32, -1, -5, -1));
}

test "inRange: floats work correctly" {
    try std.testing.expectEqual(true, inRange(f64, 0.5, 0.0, 1.0));
    try std.testing.expectEqual(false, inRange(f64, 1.0, 0.0, 1.0));
}

test "inRange: start >= end returns false (empty range)" {
    try std.testing.expectEqual(false, inRange(i32, 3, 5, 1));
    try std.testing.expectEqual(false, inRange(i32, 3, 3, 3));
}

// lerp tests

test "lerp: t=0 returns a, t=1 returns b, t=0.5 returns midpoint" {
    try std.testing.expectApproxEqAbs(@as(f64, 0.0), lerp(f64, 0.0, 10.0, 0.0), 1e-10);
    try std.testing.expectApproxEqAbs(@as(f64, 10.0), lerp(f64, 0.0, 10.0, 1.0), 1e-10);
    try std.testing.expectApproxEqAbs(@as(f64, 5.0), lerp(f64, 0.0, 10.0, 0.5), 1e-10);
}

test "lerp: works with f32" {
    const result = lerp(f32, 0.0, 10.0, 0.5);
    try std.testing.expectApproxEqAbs(@as(f32, 5.0), result, 1e-5);
}

// remap tests

test "remap: maps value from one range to another" {
    // 5 in [0,10] -> 50 in [0,100]
    try std.testing.expectApproxEqAbs(@as(f64, 50.0), remap(f64, 5.0, 0.0, 10.0, 0.0, 100.0), 1e-10);
}

test "remap: works with f32" {
    const result = remap(f32, 5.0, 0.0, 10.0, 0.0, 100.0);
    try std.testing.expectApproxEqAbs(@as(f32, 50.0), result, 1e-5);
}

test "remap: inverted output range works" {
    // 5 in [0,10] -> 50 in [100,0] = 50
    try std.testing.expectApproxEqAbs(@as(f64, 50.0), remap(f64, 5.0, 0.0, 10.0, 100.0, 0.0), 1e-10);
}

// cumSum tests

test "cumSum: empty slice returns empty slice" {
    const result = try cumSum(i32, std.testing.allocator, &.{});
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "cumSum: {1,2,3,4} returns {1,3,6,10}" {
    const result = try cumSum(i32, std.testing.allocator, &.{ 1, 2, 3, 4 });
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 3, 6, 10 }, result);
}

test "cumSum: single element returns {element}" {
    const result = try cumSum(i32, std.testing.allocator, &.{42});
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{42}, result);
}

test "cumSum: with negatives works correctly" {
    const result = try cumSum(i32, std.testing.allocator, &.{ 1, -2, 3, -4 });
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, -1, 2, -2 }, result);
}

test "cumSum: with zeros works correctly" {
    const result = try cumSum(i32, std.testing.allocator, &.{ 0, 1, 0, 2 });
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 0, 1, 1, 3 }, result);
}

// cumProd tests

test "cumProd: empty slice returns empty slice" {
    const result = try cumProd(i32, std.testing.allocator, &.{});
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "cumProd: {1,2,3,4} returns {1,2,6,24}" {
    const result = try cumProd(i32, std.testing.allocator, &.{ 1, 2, 3, 4 });
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 6, 24 }, result);
}

test "cumProd: single element returns {element}" {
    const result = try cumProd(i32, std.testing.allocator, &.{7});
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{7}, result);
}

test "cumProd: with zero produces zeros after the zero" {
    const result = try cumProd(i32, std.testing.allocator, &.{ 1, 2, 0, 4 });
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 0, 0 }, result);
}
