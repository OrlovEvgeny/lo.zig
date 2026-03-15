const std = @import("std");
const Allocator = std.mem.Allocator;

/// A generic pair for zip operations.
pub fn Pair(comptime A: type, comptime B: type) type {
    return struct { a: A, b: B };
}

/// Lazy iterator that pairs elements from two slices.
/// Stops at the shorter slice.
pub fn ZipIterator(comptime A: type, comptime B: type) type {
    return struct {
        as: []const A,
        bs: []const B,
        index: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) ?Pair(A, B) {
            if (self.index >= self.as.len or
                self.index >= self.bs.len) return null;
            const result = Pair(A, B){
                .a = self.as[self.index],
                .b = self.bs[self.index],
            };
            self.index += 1;
            return result;
        }

        pub fn collect(
            self: *Self,
            allocator: Allocator,
        ) Allocator.Error![]Pair(A, B) {
            var list = std.ArrayList(Pair(A, B)){};
            errdefer list.deinit(allocator);
            while (self.next()) |item| {
                try list.append(allocator, item);
            }
            return list.toOwnedSlice(allocator);
        }
    };
}

/// Pair elements from two slices. Returns a lazy iterator.
/// Stops at the shorter slice's length.
///
/// ```zig
/// var it = lo.zip(i32, u8, &.{1, 2}, &.{'a', 'b'});
/// it.next(); // .{ .a = 1, .b = 'a' }
/// ```
pub fn zip(
    comptime A: type,
    comptime B: type,
    as: []const A,
    bs: []const B,
) ZipIterator(A, B) {
    return .{ .as = as, .bs = bs };
}

/// Pair elements from two slices into an allocated slice.
pub fn zipAlloc(
    comptime A: type,
    comptime B: type,
    allocator: Allocator,
    as: []const A,
    bs: []const B,
) Allocator.Error![]Pair(A, B) {
    var it = zip(A, B, as, bs);
    return it.collect(allocator);
}

/// Unzip result holding two allocated slices.
pub fn UnzipResult(comptime A: type, comptime B: type) type {
    return struct {
        a: []A,
        b: []B,

        pub fn deinit(self: @This(), allocator: Allocator) void {
            allocator.free(self.a);
            allocator.free(self.b);
        }
    };
}

/// Split a slice of pairs into two separate slices.
///
/// ```zig
/// const r = try lo.unzip(i32, u8, allocator, &pairs);
/// defer r.deinit(allocator);
/// ```
pub fn unzip(
    comptime A: type,
    comptime B: type,
    allocator: Allocator,
    pairs: []const Pair(A, B),
) Allocator.Error!UnzipResult(A, B) {
    const as = try allocator.alloc(A, pairs.len);
    errdefer allocator.free(as);
    const bs = try allocator.alloc(B, pairs.len);
    for (pairs, 0..) |p, i| {
        as[i] = p.a;
        bs[i] = p.b;
    }
    return .{ .a = as, .b = bs };
}

/// Lazy iterator that zips two slices with a transform function.
pub fn ZipWithIterator(
    comptime A: type,
    comptime B: type,
    comptime R: type,
) type {
    return struct {
        as: []const A,
        bs: []const B,
        func: *const fn (A, B) R,
        index: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) ?R {
            if (self.index >= self.as.len or
                self.index >= self.bs.len) return null;
            const result = self.func(
                self.as[self.index],
                self.bs[self.index],
            );
            self.index += 1;
            return result;
        }

        pub fn collect(
            self: *Self,
            allocator: Allocator,
        ) Allocator.Error![]R {
            var list = std.ArrayList(R){};
            errdefer list.deinit(allocator);
            while (self.next()) |item| {
                try list.append(allocator, item);
            }
            return list.toOwnedSlice(allocator);
        }
    };
}

/// Zip two slices with a transform function. Returns a lazy iterator.
///
/// ```zig
/// var it = lo.zipWith(i32, i32, i32, &.{1,2}, &.{3,4}, addFn);
/// it.next(); // 4
/// it.next(); // 6
/// ```
pub fn zipWith(
    comptime A: type,
    comptime B: type,
    comptime R: type,
    as: []const A,
    bs: []const B,
    func: *const fn (A, B) R,
) ZipWithIterator(A, B, R) {
    return .{ .as = as, .bs = bs, .func = func };
}

/// Lazy iterator that pairs each element with its index.
pub fn EnumerateIterator(comptime T: type) type {
    return struct {
        slice: []const T,
        index: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) ?Pair(usize, T) {
            if (self.index >= self.slice.len) return null;
            const result = Pair(usize, T){
                .a = self.index,
                .b = self.slice[self.index],
            };
            self.index += 1;
            return result;
        }

        pub fn collect(
            self: *Self,
            allocator: Allocator,
        ) Allocator.Error![]Pair(usize, T) {
            var list = std.ArrayList(Pair(usize, T)){};
            errdefer list.deinit(allocator);
            while (self.next()) |item| {
                try list.append(allocator, item);
            }
            return list.toOwnedSlice(allocator);
        }
    };
}

/// Pair each element with its index. Returns a lazy iterator.
///
/// ```zig
/// var it = lo.enumerate(i32, &.{10, 20, 30});
/// it.next(); // .{ .a = 0, .b = 10 }
/// it.next(); // .{ .a = 1, .b = 20 }
/// ```
pub fn enumerate(
    comptime T: type,
    slice: []const T,
) EnumerateIterator(T) {
    return .{ .slice = slice };
}

// Tests.

test "zip: pairs elements" {
    var it = zip(i32, u8, &.{ 1, 2, 3 }, &.{ 'a', 'b', 'c' });
    const p1 = it.next().?;
    try std.testing.expectEqual(@as(i32, 1), p1.a);
    try std.testing.expectEqual(@as(u8, 'a'), p1.b);
    const p2 = it.next().?;
    try std.testing.expectEqual(@as(i32, 2), p2.a);
    try std.testing.expectEqual(@as(u8, 'b'), p2.b);
    const p3 = it.next().?;
    try std.testing.expectEqual(@as(i32, 3), p3.a);
    try std.testing.expectEqual(@as(u8, 'c'), p3.b);
    try std.testing.expectEqual(
        @as(?Pair(i32, u8), null),
        it.next(),
    );
}

test "zip: different lengths uses shorter" {
    var it = zip(i32, u8, &.{ 1, 2, 3 }, &.{ 'a', 'b' });
    _ = it.next();
    _ = it.next();
    try std.testing.expectEqual(
        @as(?Pair(i32, u8), null),
        it.next(),
    );
}

test "zip: empty slices" {
    var it = zip(i32, u8, &.{}, &.{});
    try std.testing.expectEqual(
        @as(?Pair(i32, u8), null),
        it.next(),
    );
}

test "zipAlloc: allocated result" {
    const result = try zipAlloc(
        i32,
        u8,
        std.testing.allocator,
        &.{ 1, 2 },
        &.{ 'x', 'y' },
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 2), result.len);
    try std.testing.expectEqual(@as(i32, 1), result[0].a);
    try std.testing.expectEqual(@as(u8, 'x'), result[0].b);
}

test "zipAlloc: empty input" {
    const result = try zipAlloc(
        i32,
        u8,
        std.testing.allocator,
        &.{},
        &.{},
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "zipAlloc: single pair" {
    const result = try zipAlloc(
        i32,
        u8,
        std.testing.allocator,
        &.{42},
        &.{'z'},
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 1), result.len);
}

test "unzip: splits pairs" {
    const pairs = [_]Pair(i32, u8){
        .{ .a = 1, .b = 'a' },
        .{ .a = 2, .b = 'b' },
        .{ .a = 3, .b = 'c' },
    };
    const r = try unzip(i32, u8, std.testing.allocator, &pairs);
    defer r.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, r.a);
    try std.testing.expectEqualSlices(u8, "abc", r.b);
}

test "unzip: empty pairs" {
    const pairs = [_]Pair(i32, u8){};
    const r = try unzip(i32, u8, std.testing.allocator, &pairs);
    defer r.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 0), r.a.len);
    try std.testing.expectEqual(@as(usize, 0), r.b.len);
}

test "unzip: single pair" {
    const pairs = [_]Pair(i32, u8){.{ .a = 42, .b = 'z' }};
    const r = try unzip(i32, u8, std.testing.allocator, &pairs);
    defer r.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(i32, &.{42}, r.a);
    try std.testing.expectEqualSlices(u8, "z", r.b);
}

test "zipWith: transforms pairs" {
    const add = struct {
        fn f(a: i32, b: i32) i32 {
            return a + b;
        }
    }.f;
    var it = zipWith(i32, i32, i32, &.{ 1, 2, 3 }, &.{ 10, 20, 30 }, add);
    try std.testing.expectEqual(@as(?i32, 11), it.next());
    try std.testing.expectEqual(@as(?i32, 22), it.next());
    try std.testing.expectEqual(@as(?i32, 33), it.next());
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

test "zipWith: different lengths" {
    const mul = struct {
        fn f(a: i32, b: i32) i32 {
            return a * b;
        }
    }.f;
    var it = zipWith(i32, i32, i32, &.{ 2, 3 }, &.{ 4, 5, 6 }, mul);
    try std.testing.expectEqual(@as(?i32, 8), it.next());
    try std.testing.expectEqual(@as(?i32, 15), it.next());
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

test "zipWith: empty input" {
    const add = struct {
        fn f(a: i32, b: i32) i32 {
            return a + b;
        }
    }.f;
    var it = zipWith(i32, i32, i32, &.{}, &.{}, add);
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

test "enumerate: pairs with index" {
    var it = enumerate(i32, &.{ 10, 20, 30 });
    const e1 = it.next().?;
    try std.testing.expectEqual(@as(usize, 0), e1.a);
    try std.testing.expectEqual(@as(i32, 10), e1.b);
    const e2 = it.next().?;
    try std.testing.expectEqual(@as(usize, 1), e2.a);
    try std.testing.expectEqual(@as(i32, 20), e2.b);
    const e3 = it.next().?;
    try std.testing.expectEqual(@as(usize, 2), e3.a);
    try std.testing.expectEqual(@as(i32, 30), e3.b);
    try std.testing.expectEqual(
        @as(?Pair(usize, i32), null),
        it.next(),
    );
}

test "enumerate: empty slice" {
    var it = enumerate(i32, &.{});
    try std.testing.expectEqual(
        @as(?Pair(usize, i32), null),
        it.next(),
    );
}

test "enumerate: collect" {
    var it = enumerate(i32, &.{ 10, 20 });
    const result = try it.collect(std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 2), result.len);
    try std.testing.expectEqual(@as(usize, 0), result[0].a);
    try std.testing.expectEqual(@as(i32, 10), result[0].b);
}
