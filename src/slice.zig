const std = @import("std");
const Allocator = std.mem.Allocator;

// Element access.

/// Returns the first element of a slice, or null if empty.
///
/// ```zig
/// lo.first(i32, &.{ 10, 20, 30 }); // 10
/// ```
pub fn first(comptime T: type, slice: []const T) ?T {
    if (slice.len == 0) return null;
    return slice[0];
}

/// Returns the last element of a slice, or null if empty.
///
/// ```zig
/// lo.last(i32, &.{ 10, 20, 30 }); // 30
/// ```
pub fn last(comptime T: type, slice: []const T) ?T {
    if (slice.len == 0) return null;
    return slice[slice.len - 1];
}

/// Element at the given index. Negative indices count from the end.
/// Returns null if out of bounds.
///
/// ```zig
/// lo.nth(i32, &.{ 10, 20, 30 }, -1); // 30
/// ```
pub fn nth(comptime T: type, slice: []const T, index: isize) ?T {
    const len = std.math.cast(isize, slice.len) orelse return null;
    var i = index;
    if (i < 0) i += len;
    if (i < 0 or i >= len) return null;
    return slice[@intCast(i)];
}

/// True if the slice contains the given value.
///
/// ```zig
/// lo.contains(i32, &.{ 1, 2, 3 }, 2); // true
/// ```
pub fn contains(comptime T: type, slice: []const T, value: T) bool {
    for (slice) |item| {
        if (eql(T, item, value)) return true;
    }
    return false;
}

/// True if any element satisfies the predicate.
///
/// ```zig
/// lo.containsBy(i32, &.{ 1, 2, 3 }, isEven); // true
/// ```
pub fn containsBy(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) bool {
    for (slice) |item| {
        if (predicate(item)) return true;
    }
    return false;
}

/// Index of the first occurrence of value, or null.
///
/// ```zig
/// lo.indexOf(i32, &.{ 10, 20, 30 }, 20); // 1
/// ```
pub fn indexOf(comptime T: type, slice: []const T, value: T) ?usize {
    for (slice, 0..) |item, i| {
        if (eql(T, item, value)) return i;
    }
    return null;
}

/// Index of the last occurrence of value, or null.
///
/// ```zig
/// lo.lastIndexOf(i32, &.{ 1, 2, 3, 2 }, 2); // 3
/// ```
pub fn lastIndexOf(
    comptime T: type,
    slice: []const T,
    value: T,
) ?usize {
    var i = slice.len;
    while (i > 0) {
        i -= 1;
        if (eql(T, slice[i], value)) return i;
    }
    return null;
}

/// Random element from a slice. Null if empty.
///
/// ```zig
/// var prng = std.Random.DefaultPrng.init(0);
/// lo.sample(i32, &.{ 1, 2, 3 }, prng.random()); // random element
/// ```
pub fn sample(
    comptime T: type,
    slice: []const T,
    random: std.Random,
) ?T {
    if (slice.len == 0) return null;
    return slice[random.intRangeLessThan(usize, 0, slice.len)];
}

/// N random elements from a slice (with replacement).
///
/// ```zig
/// const s = try lo.samples(i32, allocator, &.{1,2,3}, 5, rng);
/// defer allocator.free(s);
/// ```
pub fn samples(
    comptime T: type,
    allocator: Allocator,
    slice: []const T,
    n: usize,
    random: std.Random,
) Allocator.Error![]T {
    if (slice.len == 0) {
        return allocator.alloc(T, 0);
    }
    const result = try allocator.alloc(T, n);
    for (result) |*slot| {
        slot.* = slice[random.intRangeLessThan(usize, 0, slice.len)];
    }
    return result;
}

// Slicing.

/// Remove the first n elements, returning the rest as a sub-slice.
///
/// ```zig
/// lo.drop(i32, &.{ 1, 2, 3, 4, 5 }, 2); // &.{ 3, 4, 5 }
/// ```
pub fn drop(
    comptime T: type,
    slice: []const T,
    n: usize,
) []const T {
    const skip = @min(n, slice.len);
    return slice[skip..];
}

/// Remove the last n elements, returning the rest as a sub-slice.
///
/// ```zig
/// lo.dropRight(i32, &.{ 1, 2, 3, 4, 5 }, 2); // &.{ 1, 2, 3 }
/// ```
pub fn dropRight(
    comptime T: type,
    slice: []const T,
    n: usize,
) []const T {
    const skip = @min(n, slice.len);
    return slice[0 .. slice.len - skip];
}

/// Drop leading elements while the predicate returns true.
///
/// ```zig
/// lo.dropWhile(i32, &.{ 1, 2, 3, 4 }, isLessThan3); // &.{ 3, 4 }
/// ```
pub fn dropWhile(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) []const T {
    var i: usize = 0;
    while (i < slice.len and predicate(slice[i])) : (i += 1) {}
    return slice[i..];
}

/// Drop trailing elements while the predicate returns true.
///
/// ```zig
/// lo.dropRightWhile(i32, &.{1,2,3,4}, isGt2); // &.{ 1, 2 }
/// ```
pub fn dropRightWhile(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) []const T {
    var len = slice.len;
    while (len > 0 and predicate(slice[len - 1])) : (len -= 1) {}
    return slice[0..len];
}

/// Take the first n elements as a sub-slice.
///
/// ```zig
/// lo.take(i32, &.{ 1, 2, 3, 4, 5 }, 3); // &.{ 1, 2, 3 }
/// ```
pub fn take(
    comptime T: type,
    slice: []const T,
    n: usize,
) []const T {
    const len = @min(n, slice.len);
    return slice[0..len];
}

/// Take the last n elements as a sub-slice.
///
/// ```zig
/// lo.takeRight(i32, &.{ 1, 2, 3, 4, 5 }, 2); // &.{ 4, 5 }
/// ```
pub fn takeRight(
    comptime T: type,
    slice: []const T,
    n: usize,
) []const T {
    const len = @min(n, slice.len);
    return slice[slice.len - len ..];
}

/// Take leading elements while the predicate returns true.
///
/// ```zig
/// lo.takeWhile(i32, &.{ 1, 2, 3, 4 }, isLessThan3); // &.{ 1, 2 }
/// ```
pub fn takeWhile(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) []const T {
    var i: usize = 0;
    while (i < slice.len and predicate(slice[i])) : (i += 1) {}
    return slice[0..i];
}

/// Take trailing elements while the predicate returns true.
///
/// ```zig
/// lo.takeRightWhile(i32, &.{1,2,3,4}, isGt2); // &.{ 3, 4 }
/// ```
pub fn takeRightWhile(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) []const T {
    var len = slice.len;
    while (len > 0 and predicate(slice[len - 1])) : (len -= 1) {}
    return slice[len..];
}

/// All elements except the last. Empty slice if input is empty.
///
/// ```zig
/// lo.initial(i32, &.{ 1, 2, 3 }); // &.{ 1, 2 }
/// ```
pub fn initial(comptime T: type, slice: []const T) []const T {
    if (slice.len == 0) return slice;
    return slice[0 .. slice.len - 1];
}

/// All elements except the first. Empty slice if input is empty.
///
/// ```zig
/// lo.tail(i32, &.{ 1, 2, 3 }); // &.{ 2, 3 }
/// ```
pub fn tail(comptime T: type, slice: []const T) []const T {
    if (slice.len == 0) return slice;
    return slice[1..];
}

// Search and query.

/// First element matching the predicate, or null.
///
/// ```zig
/// lo.find(i32, &.{ 1, 2, 3, 4 }, isEven); // 2
/// ```
pub fn find(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) ?T {
    for (slice) |item| {
        if (predicate(item)) return item;
    }
    return null;
}

/// Index of the first element matching the predicate, or null.
///
/// ```zig
/// lo.findIndex(i32, &.{ 1, 2, 3 }, isEven); // 1
/// ```
pub fn findIndex(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) ?usize {
    for (slice, 0..) |item, i| {
        if (predicate(item)) return i;
    }
    return null;
}

/// Last element matching the predicate, or null.
///
/// ```zig
/// lo.findLast(i32, &.{ 1, 2, 3, 4 }, isEven); // 4
/// ```
pub fn findLast(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) ?T {
    var i = slice.len;
    while (i > 0) {
        i -= 1;
        if (predicate(slice[i])) return slice[i];
    }
    return null;
}

/// Index of the last element matching the predicate, or null.
///
/// ```zig
/// lo.findLastIndex(i32, &.{ 1, 2, 3, 4 }, isEven); // 3
/// ```
pub fn findLastIndex(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) ?usize {
    var i = slice.len;
    while (i > 0) {
        i -= 1;
        if (predicate(slice[i])) return i;
    }
    return null;
}

/// True if all elements satisfy the predicate. True for empty slices.
///
/// ```zig
/// lo.every(i32, &.{ 2, 4, 6 }, isEven); // true
/// ```
pub fn every(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) bool {
    for (slice) |item| {
        if (!predicate(item)) return false;
    }
    return true;
}

/// True if at least one element satisfies the predicate. False for empty.
///
/// ```zig
/// lo.some(i32, &.{ 1, 2, 3 }, isEven); // true
/// ```
pub fn some(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) bool {
    for (slice) |item| {
        if (predicate(item)) return true;
    }
    return false;
}

/// True if no elements satisfy the predicate. True for empty slices.
///
/// ```zig
/// lo.none(i32, &.{ 1, 3, 5 }, isEven); // true
/// ```
pub fn none(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) bool {
    for (slice) |item| {
        if (predicate(item)) return false;
    }
    return true;
}

/// Count elements satisfying the predicate.
///
/// ```zig
/// lo.count(i32, &.{ 1, 2, 3, 4 }, isEven); // 2
/// ```
pub fn count(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) usize {
    var n: usize = 0;
    for (slice) |item| {
        if (predicate(item)) n += 1;
    }
    return n;
}

/// Build a frequency map: value -> number of occurrences.
/// Caller owns the returned map.
///
/// ```zig
/// var freq = try lo.countValues(i32, allocator, &.{1, 2, 2, 3});
/// defer freq.deinit();
/// freq.get(2).?; // 2
/// ```
pub fn countValues(
    comptime T: type,
    allocator: Allocator,
    slice: []const T,
) Allocator.Error!std.AutoHashMap(T, usize) {
    var freq = std.AutoHashMap(T, usize).init(allocator);
    errdefer freq.deinit();
    for (slice) |item| {
        const entry = try freq.getOrPut(item);
        if (entry.found_existing) {
            entry.value_ptr.* += 1;
        } else {
            entry.value_ptr.* = 1;
        }
    }
    return freq;
}

// Aggregation.

/// Left fold with an accumulator.
///
/// ```zig
/// // Sum via reduce:
/// lo.reduce(i32, i32, &.{1,2,3}, addFn, 0); // 6
/// ```
pub fn reduce(
    comptime T: type,
    comptime R: type,
    slice: []const T,
    reducer: *const fn (R, T) R,
    initial_value: R,
) R {
    var acc = initial_value;
    for (slice) |item| {
        acc = reducer(acc, item);
    }
    return acc;
}

/// Right fold with an accumulator. Processes elements right to left.
///
/// ```zig
/// lo.reduceRight(i32, i32, &.{1,2,3}, subtractFn, 0);
/// ```
pub fn reduceRight(
    comptime T: type,
    comptime R: type,
    slice: []const T,
    reducer: *const fn (R, T) R,
    initial_value: R,
) R {
    var acc = initial_value;
    var i = slice.len;
    while (i > 0) {
        i -= 1;
        acc = reducer(acc, slice[i]);
    }
    return acc;
}

/// Invoke a function on each element.
///
/// ```zig
/// lo.forEach(i32, &.{ 1, 2, 3 }, printFn);
/// ```
pub fn forEach(
    comptime T: type,
    slice: []const T,
    func: *const fn (T) void,
) void {
    for (slice) |item| {
        func(item);
    }
}

/// Invoke a function on each element with its index.
///
/// ```zig
/// lo.forEachIndex(i32, &.{ 10, 20 }, printWithIndex);
/// ```
pub fn forEachIndex(
    comptime T: type,
    slice: []const T,
    func: *const fn (T, usize) void,
) void {
    for (slice, 0..) |item, i| {
        func(item, i);
    }
}

// Iterators and transformation.

/// Lazy iterator that applies a transform to each element.
pub fn MapIterator(comptime T: type, comptime R: type) type {
    return struct {
        slice: []const T,
        transform: *const fn (T) R,
        index: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) ?R {
            if (self.index >= self.slice.len) return null;
            const result = self.transform(self.slice[self.index]);
            self.index += 1;
            return result;
        }

        /// Collect remaining elements into an allocated slice.
        pub fn collect(self: *Self, allocator: Allocator) Allocator.Error![]R {
            var list = std.ArrayList(R){};
            errdefer list.deinit(allocator);
            while (self.next()) |item| {
                try list.append(allocator, item);
            }
            return list.toOwnedSlice(allocator);
        }
    };
}

/// Transform each element. Returns a lazy iterator.
///
/// ```zig
/// var it = lo.map(i32, i64, &.{1, 2, 3}, double);
/// it.next(); // 2
/// ```
pub fn map(
    comptime T: type,
    comptime R: type,
    slice: []const T,
    transform: *const fn (T) R,
) MapIterator(T, R) {
    return .{ .slice = slice, .transform = transform };
}

/// Transform each element and collect into an allocated slice.
pub fn mapAlloc(
    comptime T: type,
    comptime R: type,
    allocator: Allocator,
    slice: []const T,
    transform: *const fn (T) R,
) Allocator.Error![]R {
    const result = try allocator.alloc(R, slice.len);
    for (slice, 0..) |item, i| {
        result[i] = transform(item);
    }
    return result;
}

/// Lazy iterator that transforms each element with its index.
pub fn MapIndexIterator(comptime T: type, comptime R: type) type {
    return struct {
        slice: []const T,
        transform: *const fn (T, usize) R,
        index: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) ?R {
            if (self.index >= self.slice.len) return null;
            const result = self.transform(self.slice[self.index], self.index);
            self.index += 1;
            return result;
        }

        pub fn collect(self: *Self, allocator: Allocator) Allocator.Error![]R {
            var list = std.ArrayList(R){};
            errdefer list.deinit(allocator);
            while (self.next()) |item| {
                try list.append(allocator, item);
            }
            return list.toOwnedSlice(allocator);
        }
    };
}

/// Transform each element with its index. Returns a lazy iterator.
pub fn mapIndex(
    comptime T: type,
    comptime R: type,
    slice: []const T,
    transform: *const fn (T, usize) R,
) MapIndexIterator(T, R) {
    return .{ .slice = slice, .transform = transform };
}

/// Lazy iterator that yields elements matching a predicate.
pub fn FilterIterator(comptime T: type) type {
    return struct {
        slice: []const T,
        predicate: *const fn (T) bool,
        index: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) ?T {
            while (self.index < self.slice.len) {
                const item = self.slice[self.index];
                self.index += 1;
                if (self.predicate(item)) return item;
            }
            return null;
        }

        pub fn collect(self: *Self, allocator: Allocator) Allocator.Error![]T {
            var list = std.ArrayList(T){};
            errdefer list.deinit(allocator);
            while (self.next()) |item| {
                try list.append(allocator, item);
            }
            return list.toOwnedSlice(allocator);
        }
    };
}

/// Keep elements matching the predicate. Returns a lazy iterator.
///
/// ```zig
/// var it = lo.filter(i32, &.{1, 2, 3, 4}, isEven);
/// it.next(); // 2
/// it.next(); // 4
/// ```
pub fn filter(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) FilterIterator(T) {
    return .{ .slice = slice, .predicate = predicate };
}

/// Keep elements matching the predicate, collected into an allocated slice.
pub fn filterAlloc(
    comptime T: type,
    allocator: Allocator,
    slice: []const T,
    predicate: *const fn (T) bool,
) Allocator.Error![]T {
    var it = filter(T, slice, predicate);
    return it.collect(allocator);
}

/// Lazy iterator that yields elements NOT matching a predicate.
pub fn RejectIterator(comptime T: type) type {
    return struct {
        slice: []const T,
        predicate: *const fn (T) bool,
        index: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) ?T {
            while (self.index < self.slice.len) {
                const item = self.slice[self.index];
                self.index += 1;
                if (!self.predicate(item)) return item;
            }
            return null;
        }

        pub fn collect(self: *Self, allocator: Allocator) Allocator.Error![]T {
            var list = std.ArrayList(T){};
            errdefer list.deinit(allocator);
            while (self.next()) |item| {
                try list.append(allocator, item);
            }
            return list.toOwnedSlice(allocator);
        }
    };
}

/// Remove elements matching the predicate. Returns a lazy iterator.
///
/// ```zig
/// var it = lo.reject(i32, &.{1, 2, 3, 4}, isEven);
/// it.next(); // 1
/// it.next(); // 3
/// ```
pub fn reject(
    comptime T: type,
    slice: []const T,
    predicate: *const fn (T) bool,
) RejectIterator(T) {
    return .{ .slice = slice, .predicate = predicate };
}

/// Remove elements matching the predicate, collected into an allocated slice.
pub fn rejectAlloc(
    comptime T: type,
    allocator: Allocator,
    slice: []const T,
    predicate: *const fn (T) bool,
) Allocator.Error![]T {
    var it = reject(T, slice, predicate);
    return it.collect(allocator);
}

/// Lazy iterator that flattens a slice of slices into a single sequence.
pub fn FlattenIterator(comptime T: type) type {
    return struct {
        slices: []const []const T,
        outer: usize = 0,
        inner: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) ?T {
            while (self.outer < self.slices.len) {
                const current = self.slices[self.outer];
                if (self.inner < current.len) {
                    const item = current[self.inner];
                    self.inner += 1;
                    return item;
                }
                self.outer += 1;
                self.inner = 0;
            }
            return null;
        }

        pub fn collect(self: *Self, allocator: Allocator) Allocator.Error![]T {
            var list = std.ArrayList(T){};
            errdefer list.deinit(allocator);
            while (self.next()) |item| {
                try list.append(allocator, item);
            }
            return list.toOwnedSlice(allocator);
        }
    };
}

/// Flatten a slice of slices into a single sequence.
///
/// ```zig
/// const data = [_][]const i32{ &.{1, 2}, &.{3, 4} };
/// var it = lo.flatten(i32, &data);
/// // yields 1, 2, 3, 4
/// ```
pub fn flatten(
    comptime T: type,
    slices: []const []const T,
) FlattenIterator(T) {
    return .{ .slices = slices };
}

/// Flatten a slice of slices into an allocated slice.
pub fn flattenAlloc(
    comptime T: type,
    allocator: Allocator,
    slices: []const []const T,
) Allocator.Error![]T {
    var it = flatten(T, slices);
    return it.collect(allocator);
}

/// Lazy iterator that maps then flattens.
pub fn FlatMapIterator(comptime T: type, comptime R: type) type {
    return struct {
        slice: []const T,
        transform: *const fn (T) []const R,
        outer: usize = 0,
        inner_slice: []const R = &[_]R{},
        inner_index: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) ?R {
            while (true) {
                if (self.inner_index < self.inner_slice.len) {
                    const item = self.inner_slice[self.inner_index];
                    self.inner_index += 1;
                    return item;
                }
                if (self.outer >= self.slice.len) return null;
                self.inner_slice = self.transform(self.slice[self.outer]);
                self.inner_index = 0;
                self.outer += 1;
            }
        }

        pub fn collect(self: *Self, allocator: Allocator) Allocator.Error![]R {
            var list = std.ArrayList(R){};
            errdefer list.deinit(allocator);
            while (self.next()) |item| {
                try list.append(allocator, item);
            }
            return list.toOwnedSlice(allocator);
        }
    };
}

/// Map each element to a slice, then flatten into a single sequence.
///
/// ```zig
/// var it = lo.flatMap(i32, u8, &.{1, 2}, toDigits);
/// ```
pub fn flatMap(
    comptime T: type,
    comptime R: type,
    slice: []const T,
    transform: *const fn (T) []const R,
) FlatMapIterator(T, R) {
    return .{ .slice = slice, .transform = transform };
}

/// Map then flatten, collected into an allocated slice.
pub fn flatMapAlloc(
    comptime T: type,
    comptime R: type,
    allocator: Allocator,
    slice: []const T,
    transform: *const fn (T) []const R,
) Allocator.Error![]R {
    var it = flatMap(T, R, slice, transform);
    return it.collect(allocator);
}

/// Lazy iterator that removes zero/null/default values.
pub fn CompactIterator(comptime T: type) type {
    return struct {
        slice: []const T,
        index: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) ?T {
            const info = @typeInfo(T);
            while (self.index < self.slice.len) {
                const item = self.slice[self.index];
                self.index += 1;
                switch (info) {
                    .optional => {
                        if (item) |_| return item;
                    },
                    .int, .comptime_int => {
                        if (item != 0) return item;
                    },
                    .float, .comptime_float => {
                        if (item != 0.0) return item;
                    },
                    .bool => {
                        if (item) return item;
                    },
                    .pointer => |p| {
                        if (p.size == .slice) {
                            if (item.len > 0) return item;
                        } else return item;
                    },
                    else => return item,
                }
            }
            return null;
        }

        pub fn collect(self: *Self, allocator: Allocator) Allocator.Error![]T {
            var list = std.ArrayList(T){};
            errdefer list.deinit(allocator);
            while (self.next()) |item| {
                try list.append(allocator, item);
            }
            return list.toOwnedSlice(allocator);
        }
    };
}

/// Remove zero/null/default values. Returns a lazy iterator.
///
/// ```zig
/// var it = lo.compact(?i32, &.{ 1, null, 3, null });
/// it.next(); // 1
/// it.next(); // 3
/// ```
pub fn compact(comptime T: type, slice: []const T) CompactIterator(T) {
    return .{ .slice = slice };
}

/// Remove zero/null/default values into an allocated slice.
pub fn compactAlloc(
    comptime T: type,
    allocator: Allocator,
    slice: []const T,
) Allocator.Error![]T {
    var it = compact(T, slice);
    return it.collect(allocator);
}

/// Lazy iterator over fixed-size chunks of a slice.
/// Returns successive fixed-size sub-slices of the input.
/// Returned slices borrow from the input -- they are NOT copies.
/// Do not use returned slices after the input slice is freed or goes out of scope.
pub fn ChunkIterator(comptime T: type) type {
    return struct {
        slice: []const T,
        size: usize,
        index: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) ?[]const T {
            if (self.index >= self.slice.len) return null;
            const end = @min(self.index + self.size, self.slice.len);
            const result = self.slice[self.index..end];
            self.index = end;
            return result;
        }
    };
}

/// Split a slice into chunks of the given size.
/// The last chunk may be smaller.
///
/// ```zig
/// var it = lo.chunk(i32, &.{1, 2, 3, 4, 5}, 2);
/// it.next(); // &.{1, 2}
/// it.next(); // &.{3, 4}
/// it.next(); // &.{5}
/// ```
pub fn chunk(
    comptime T: type,
    slice: []const T,
    size: usize,
) ChunkIterator(T) {
    return .{ .slice = slice, .size = size };
}

/// Lazy iterator that excludes specific values.
pub fn WithoutIterator(comptime T: type) type {
    return struct {
        slice: []const T,
        excluded: []const T,
        index: usize = 0,

        const Self = @This();

        pub fn next(self: *Self) ?T {
            while (self.index < self.slice.len) {
                const item = self.slice[self.index];
                self.index += 1;
                var found = false;
                for (self.excluded) |ex| {
                    if (eql(T, item, ex)) {
                        found = true;
                        break;
                    }
                }
                if (!found) return item;
            }
            return null;
        }

        pub fn collect(self: *Self, allocator: Allocator) Allocator.Error![]T {
            var list = std.ArrayList(T){};
            errdefer list.deinit(allocator);
            while (self.next()) |item| {
                try list.append(allocator, item);
            }
            return list.toOwnedSlice(allocator);
        }
    };
}

/// Exclude specific values from a slice. Returns a lazy iterator.
///
/// ```zig
/// var it = lo.without(i32, &.{1, 2, 3, 4}, &.{2, 4});
/// // yields 1, 3
/// ```
pub fn without(
    comptime T: type,
    slice: []const T,
    excluded: []const T,
) WithoutIterator(T) {
    return .{ .slice = slice, .excluded = excluded };
}

// Advanced operations.

/// Remove duplicate elements. Preserves first occurrence order.
/// Requires allocation for an internal hash set.
///
/// ```zig
/// const u = try lo.uniq(i32, allocator, &.{1, 2, 2, 3, 1});
/// defer allocator.free(u);
/// // u == &.{1, 2, 3}
/// ```
pub fn uniq(
    comptime T: type,
    allocator: Allocator,
    slice: []const T,
) Allocator.Error![]T {
    var seen = std.AutoHashMap(T, void).init(allocator);
    defer seen.deinit();
    var list = std.ArrayList(T){};
    errdefer list.deinit(allocator);
    for (slice) |item| {
        const gop = try seen.getOrPut(item);
        if (!gop.found_existing) {
            try list.append(allocator, item);
        }
    }
    return list.toOwnedSlice(allocator);
}

/// Remove duplicates by a key function. Preserves first occurrence order.
///
/// ```zig
/// const u = try lo.uniqBy(Person, u32, allocator, &people, Person.id);
/// defer allocator.free(u);
/// ```
pub fn uniqBy(
    comptime T: type,
    comptime K: type,
    allocator: Allocator,
    slice: []const T,
    key_fn: *const fn (T) K,
) Allocator.Error![]T {
    var seen = std.AutoHashMap(K, void).init(allocator);
    defer seen.deinit();
    var list = std.ArrayList(T){};
    errdefer list.deinit(allocator);
    for (slice) |item| {
        const k = key_fn(item);
        const gop = try seen.getOrPut(k);
        if (!gop.found_existing) {
            try list.append(allocator, item);
        }
    }
    return list.toOwnedSlice(allocator);
}

/// Group elements by a key function.
/// Caller owns the returned map and must deinit it.
///
/// ```zig
/// var groups = try lo.groupBy(i32, bool, allocator, &.{1,2,3,4}, isEvenFn);
/// defer {
///     var it = groups.valueIterator();
///     while (it.next()) |list| list.deinit(allocator);
///     groups.deinit();
/// }
/// ```
pub fn groupBy(
    comptime T: type,
    comptime K: type,
    allocator: Allocator,
    slice: []const T,
    key_fn: *const fn (T) K,
) Allocator.Error!std.AutoHashMap(K, std.ArrayList(T)) {
    var groups = std.AutoHashMap(K, std.ArrayList(T)).init(allocator);
    errdefer {
        var vit = groups.valueIterator();
        while (vit.next()) |list| list.deinit(allocator);
        groups.deinit();
    }
    for (slice) |item| {
        const k = key_fn(item);
        const gop = try groups.getOrPut(k);
        if (!gop.found_existing) {
            gop.value_ptr.* = std.ArrayList(T){};
        }
        try gop.value_ptr.append(allocator, item);
    }
    return groups;
}

/// Partition result holding two allocated slices.
pub fn PartitionResult(comptime T: type) type {
    return struct {
        matching: []T,
        rest: []T,

        pub fn deinit(self: @This(), allocator: Allocator) void {
            allocator.free(self.matching);
            allocator.free(self.rest);
        }
    };
}

/// Split a slice into two: elements matching the predicate and the rest.
///
/// ```zig
/// const p = try lo.partition(i32, allocator, &.{1,2,3,4}, isEven);
/// defer p.deinit(allocator);
/// // p.matching == &.{2, 4}, p.rest == &.{1, 3}
/// ```
pub fn partition(
    comptime T: type,
    allocator: Allocator,
    slice: []const T,
    predicate: *const fn (T) bool,
) Allocator.Error!PartitionResult(T) {
    var matching = std.ArrayList(T){};
    errdefer matching.deinit(allocator);
    var rest = std.ArrayList(T){};
    errdefer rest.deinit(allocator);
    for (slice) |item| {
        if (predicate(item)) {
            try matching.append(allocator, item);
        } else {
            try rest.append(allocator, item);
        }
    }
    return .{
        .matching = try matching.toOwnedSlice(allocator),
        .rest = try rest.toOwnedSlice(allocator),
    };
}

// Set operations.

/// Elements present in both slices. Order follows the first slice.
///
/// ```zig
/// const i = try lo.intersect(i32, allocator, &.{1,2,3}, &.{2,3,4});
/// defer allocator.free(i);
/// // i == &.{2, 3}
/// ```
pub fn intersect(
    comptime T: type,
    allocator: Allocator,
    a: []const T,
    b: []const T,
) Allocator.Error![]T {
    var set = std.AutoHashMap(T, void).init(allocator);
    defer set.deinit();
    for (b) |item| {
        try set.put(item, {});
    }
    var list = std.ArrayList(T){};
    errdefer list.deinit(allocator);
    for (a) |item| {
        if (set.contains(item)) {
            try list.append(allocator, item);
        }
    }
    return list.toOwnedSlice(allocator);
}

/// Unique elements from both slices combined.
///
/// ```zig
/// const u = try lo.union_(i32, allocator, &.{1,2,3}, &.{2,3,4});
/// defer allocator.free(u);
/// // u == &.{1, 2, 3, 4}
/// ```
pub fn union_(
    comptime T: type,
    allocator: Allocator,
    a: []const T,
    b: []const T,
) Allocator.Error![]T {
    var seen = std.AutoHashMap(T, void).init(allocator);
    defer seen.deinit();
    var list = std.ArrayList(T){};
    errdefer list.deinit(allocator);
    for (a) |item| {
        const gop = try seen.getOrPut(item);
        if (!gop.found_existing) {
            try list.append(allocator, item);
        }
    }
    for (b) |item| {
        const gop = try seen.getOrPut(item);
        if (!gop.found_existing) {
            try list.append(allocator, item);
        }
    }
    return list.toOwnedSlice(allocator);
}

/// Elements in the first slice but not in the second.
///
/// ```zig
/// const d = try lo.difference(i32, allocator, &.{1,2,3}, &.{2,4});
/// defer allocator.free(d);
/// // d == &.{1, 3}
/// ```
pub fn difference(
    comptime T: type,
    allocator: Allocator,
    a: []const T,
    b: []const T,
) Allocator.Error![]T {
    var set = std.AutoHashMap(T, void).init(allocator);
    defer set.deinit();
    for (b) |item| {
        try set.put(item, {});
    }
    var list = std.ArrayList(T){};
    errdefer list.deinit(allocator);
    for (a) |item| {
        if (!set.contains(item)) {
            try list.append(allocator, item);
        }
    }
    return list.toOwnedSlice(allocator);
}

/// Elements in either slice but not in both.
///
/// ```zig
/// const sd = try lo.symmetricDifference(i32, alloc, &.{1,2,3}, &.{2,3,4});
/// defer allocator.free(sd);
/// // sd == &.{1, 4}
/// ```
pub fn symmetricDifference(
    comptime T: type,
    allocator: Allocator,
    a: []const T,
    b: []const T,
) Allocator.Error![]T {
    var set_a = std.AutoHashMap(T, void).init(allocator);
    defer set_a.deinit();
    for (a) |item| try set_a.put(item, {});

    var set_b = std.AutoHashMap(T, void).init(allocator);
    defer set_b.deinit();
    for (b) |item| try set_b.put(item, {});

    var list = std.ArrayList(T){};
    errdefer list.deinit(allocator);
    for (a) |item| {
        if (!set_b.contains(item)) try list.append(allocator, item);
    }
    for (b) |item| {
        if (!set_a.contains(item)) try list.append(allocator, item);
    }
    return list.toOwnedSlice(allocator);
}

// In-place mutation.

/// Reverse a slice in-place.
///
/// ```zig
/// var data = [_]i32{ 1, 2, 3 };
/// lo.reverse(i32, &data);
/// // data == .{ 3, 2, 1 }
/// ```
pub fn reverse(comptime T: type, slice: []T) void {
    if (slice.len < 2) return;
    var lo_idx: usize = 0;
    var hi_idx: usize = slice.len - 1;
    while (lo_idx < hi_idx) {
        const tmp = slice[lo_idx];
        slice[lo_idx] = slice[hi_idx];
        slice[hi_idx] = tmp;
        lo_idx += 1;
        hi_idx -= 1;
    }
}

/// Fisher-Yates shuffle in-place.
///
/// ```zig
/// var data = [_]i32{ 1, 2, 3, 4, 5 };
/// lo.shuffle(i32, &data, prng.random());
/// ```
pub fn shuffle(comptime T: type, slice: []T, random: std.Random) void {
    if (slice.len < 2) return;
    var i = slice.len - 1;
    while (i > 0) : (i -= 1) {
        const j = random.intRangeAtMost(usize, 0, i);
        const tmp = slice[i];
        slice[i] = slice[j];
        slice[j] = tmp;
    }
}

/// Fill all elements with the given value.
///
/// ```zig
/// var data = [_]i32{ 0, 0, 0 };
/// lo.fill(i32, &data, 42);
/// // data == .{ 42, 42, 42 }
/// ```
pub fn fill(comptime T: type, slice: []T, value: T) void {
    for (slice) |*slot| {
        slot.* = value;
    }
}

/// Fill elements in the range [start, end) with the given value.
///
/// ```zig
/// var data = [_]i32{ 1, 2, 3, 4, 5 };
/// lo.fillRange(i32, &data, 0, 1, 4);
/// // data == .{ 1, 0, 0, 0, 5 }
/// ```
pub fn fillRange(
    comptime T: type,
    slice: []T,
    value: T,
    start: usize,
    end: usize,
) void {
    const s = @min(start, slice.len);
    const e = @min(end, slice.len);
    for (slice[s..e]) |*slot| {
        slot.* = value;
    }
}

// Other utilities.

/// Create a slice of n copies of a value.
///
/// ```zig
/// const r = try lo.repeat(i32, allocator, 42, 3);
/// defer allocator.free(r);
/// // r == &.{ 42, 42, 42 }
/// ```
pub fn repeat(
    comptime T: type,
    allocator: Allocator,
    value: T,
    n: usize,
) Allocator.Error![]T {
    const result = try allocator.alloc(T, n);
    for (result) |*slot| {
        slot.* = value;
    }
    return result;
}

/// Create a slice of n elements produced by the callback.
///
/// ```zig
/// const r = try lo.repeatBy(i32, allocator, 3, indexSquared);
/// defer allocator.free(r);
/// // r == &.{ 0, 1, 4 }
/// ```
pub fn repeatBy(
    comptime T: type,
    allocator: Allocator,
    n: usize,
    generator: *const fn (usize) T,
) Allocator.Error![]T {
    const result = try allocator.alloc(T, n);
    for (result, 0..) |*slot, i| {
        slot.* = generator(i);
    }
    return result;
}

/// True if the slice is sorted according to the comparator.
///
/// ```zig
/// lo.isSorted(i32, &.{ 1, 2, 3 }, compareAsc); // true
/// ```
pub fn isSorted(
    comptime T: type,
    slice: []const T,
    comparator: *const fn (T, T) std.math.Order,
) bool {
    if (slice.len < 2) return true;
    for (0..slice.len - 1) |i| {
        if (comparator(slice[i], slice[i + 1]) == .gt) return false;
    }
    return true;
}

/// Element-wise equality of two slices.
///
/// ```zig
/// lo.equal(i32, &.{ 1, 2, 3 }, &.{ 1, 2, 3 }); // true
/// ```
pub fn equal(comptime T: type, a: []const T, b: []const T) bool {
    if (a.len != b.len) return false;
    for (a, b) |x, y| {
        if (!eql(T, x, y)) return false;
    }
    return true;
}

// Map-building and deduplication.

/// Generic key-value entry type for `associate`.
///
/// ```zig
/// const entry = lo.AssocEntry([]const u8, u32){ .key = "alice", .value = 30 };
/// ```
pub fn AssocEntry(comptime K: type, comptime V: type) type {
    return struct { key: K, value: V };
}

/// Convert a slice to a map indexed by an extracted key.
///
/// Given a key function, builds a hash map from keys to elements.
/// If multiple elements produce the same key, the **last** element wins.
///
/// ```zig
/// const Person = struct { name: []const u8, age: u32 };
/// fn getAge(p: Person) u32 { return p.age; }
/// var m = try lo.keyBy(Person, u32, allocator, &people, getAge);
/// defer m.deinit();
/// ```
pub fn keyBy(
    comptime T: type,
    comptime K: type,
    allocator: Allocator,
    items: []const T,
    key_fn: *const fn (T) K,
) Allocator.Error!std.AutoHashMap(K, T) {
    _ = allocator;
    _ = items;
    _ = key_fn;
    unreachable;
}

/// Convert a slice to a map with custom key and value extraction.
///
/// The `transform` function returns an `AssocEntry(K, V)` for each element.
/// If multiple elements produce the same key, the **last** element wins.
///
/// ```zig
/// fn toEntry(p: Person) lo.AssocEntry(u32, []const u8) {
///     return .{ .key = p.age, .value = p.name };
/// }
/// var m = try lo.associate(Person, u32, []const u8, allocator, &people, toEntry);
/// defer m.deinit();
/// ```
pub fn associate(
    comptime T: type,
    comptime K: type,
    comptime V: type,
    allocator: Allocator,
    items: []const T,
    transform: *const fn (T) AssocEntry(K, V),
) Allocator.Error!std.AutoHashMap(K, V) {
    _ = allocator;
    _ = items;
    _ = transform;
    unreachable;
}

/// Count elements by a key function.
///
/// Applies the key function to each element and counts how many elements
/// produce each key. Follows the `countValues` pattern with key extraction.
///
/// ```zig
/// fn isEven(x: i32) bool { return @mod(x, 2) == 0; }
/// var m = try lo.countBy(i32, bool, allocator, &.{1,2,3,4,5}, isEven);
/// defer m.deinit();
/// m.get(true).?;  // 2
/// m.get(false).?; // 3
/// ```
pub fn countBy(
    comptime T: type,
    comptime K: type,
    allocator: Allocator,
    items: []const T,
    key_fn: *const fn (T) K,
) Allocator.Error!std.AutoHashMap(K, usize) {
    _ = allocator;
    _ = items;
    _ = key_fn;
    unreachable;
}

/// Find elements appearing more than once.
///
/// Returns a new slice containing the first occurrence of each element
/// that appears more than once. Preserves first-occurrence order from
/// the original slice.
///
/// ```zig
/// const dups = try lo.findDuplicates(i32, allocator, &.{1,2,2,3,3,3});
/// defer allocator.free(dups);
/// // dups == &.{2, 3}
/// ```
pub fn findDuplicates(
    comptime T: type,
    allocator: Allocator,
    items: []const T,
) Allocator.Error![]T {
    _ = allocator;
    _ = items;
    unreachable;
}

/// Find elements appearing exactly once.
///
/// Returns a new slice containing elements that appear exactly once
/// in the input. Preserves first-occurrence order from the original slice.
///
/// ```zig
/// const uniques = try lo.findUniques(i32, allocator, &.{1,2,2,3,3,3,4});
/// defer allocator.free(uniques);
/// // uniques == &.{1, 4}
/// ```
pub fn findUniques(
    comptime T: type,
    allocator: Allocator,
    items: []const T,
) Allocator.Error![]T {
    _ = allocator;
    _ = items;
    unreachable;
}

// Equality helper, used throughout slice.zig.

fn eql(comptime T: type, a: T, b: T) bool {
    return std.meta.eql(a, b);
}

// Tests: Element access.

test "first: returns first element" {
    try std.testing.expectEqual(@as(?i32, 10), first(i32, &.{ 10, 20, 30 }));
}

test "first: empty slice returns null" {
    try std.testing.expectEqual(@as(?i32, null), first(i32, &.{}));
}

test "first: single element" {
    try std.testing.expectEqual(@as(?i32, 42), first(i32, &.{42}));
}

test "last: returns last element" {
    try std.testing.expectEqual(@as(?i32, 30), last(i32, &.{ 10, 20, 30 }));
}

test "last: empty slice returns null" {
    try std.testing.expectEqual(@as(?i32, null), last(i32, &.{}));
}

test "last: single element" {
    try std.testing.expectEqual(@as(?i32, 42), last(i32, &.{42}));
}

test "nth: positive index" {
    try std.testing.expectEqual(@as(?i32, 20), nth(i32, &.{ 10, 20, 30 }, 1));
}

test "nth: negative index counts from end" {
    try std.testing.expectEqual(@as(?i32, 30), nth(i32, &.{ 10, 20, 30 }, -1));
}

test "nth: out of bounds returns null" {
    try std.testing.expectEqual(@as(?i32, null), nth(i32, &.{ 10, 20, 30 }, 5));
}

test "nth: negative out of bounds returns null" {
    try std.testing.expectEqual(@as(?i32, null), nth(i32, &.{ 10, 20 }, -3));
}

test "nth: zero index is first" {
    try std.testing.expectEqual(@as(?i32, 10), nth(i32, &.{ 10, 20, 30 }, 0));
}

test "contains: value present" {
    try std.testing.expect(contains(i32, &.{ 1, 2, 3 }, 2));
}

test "contains: value absent" {
    try std.testing.expect(!contains(i32, &.{ 1, 2, 3 }, 4));
}

test "contains: empty slice" {
    try std.testing.expect(!contains(i32, &.{}, 1));
}

// Shared test predicates.

const isEven = struct {
    fn f(x: i32) bool {
        return @mod(x, 2) == 0;
    }
}.f;

const isNeg = struct {
    fn f(x: i32) bool {
        return x < 0;
    }
}.f;

test "containsBy: match found" {
    try std.testing.expect(containsBy(i32, &.{ 1, 2, 3 }, isEven));
}

test "containsBy: no match" {
    try std.testing.expect(!containsBy(i32, &.{ 1, 2, 3 }, isNeg));
}

test "containsBy: empty slice" {
    const always = struct {
        fn f(_: i32) bool {
            return true;
        }
    }.f;
    try std.testing.expect(!containsBy(i32, &.{}, always));
}

test "indexOf: finds first occurrence" {
    try std.testing.expectEqual(@as(?usize, 1), indexOf(i32, &.{ 10, 20, 30 }, 20));
}

test "indexOf: not found returns null" {
    try std.testing.expectEqual(@as(?usize, null), indexOf(i32, &.{ 10, 20, 30 }, 99));
}

test "indexOf: empty slice" {
    try std.testing.expectEqual(@as(?usize, null), indexOf(i32, &.{}, 1));
}

test "indexOf: duplicate values finds first" {
    try std.testing.expectEqual(@as(?usize, 1), indexOf(i32, &.{ 1, 2, 3, 2 }, 2));
}

test "lastIndexOf: finds last occurrence" {
    try std.testing.expectEqual(@as(?usize, 3), lastIndexOf(i32, &.{ 1, 2, 3, 2 }, 2));
}

test "lastIndexOf: not found returns null" {
    try std.testing.expectEqual(@as(?usize, null), lastIndexOf(i32, &.{ 1, 2, 3 }, 99));
}

test "lastIndexOf: empty slice" {
    try std.testing.expectEqual(@as(?usize, null), lastIndexOf(i32, &.{}, 1));
}

test "lastIndexOf: single occurrence" {
    try std.testing.expectEqual(@as(?usize, 1), lastIndexOf(i32, &.{ 1, 2, 3 }, 2));
}

test "sample: returns an element from the slice" {
    var prng = std.Random.DefaultPrng.init(12345);
    const data = [_]i32{ 10, 20, 30 };
    const result = sample(i32, &data, prng.random()).?;
    try std.testing.expect(contains(i32, &data, result));
}

test "sample: empty slice returns null" {
    var prng = std.Random.DefaultPrng.init(0);
    try std.testing.expectEqual(@as(?i32, null), sample(i32, &.{}, prng.random()));
}

test "sample: single element always returns it" {
    var prng = std.Random.DefaultPrng.init(42);
    try std.testing.expectEqual(@as(?i32, 7), sample(i32, &.{7}, prng.random()));
}

test "samples: returns requested count" {
    var prng = std.Random.DefaultPrng.init(12345);
    const data = [_]i32{ 10, 20, 30 };
    const result = try samples(
        i32,
        std.testing.allocator,
        &data,
        5,
        prng.random(),
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 5), result.len);
    for (result) |v| {
        try std.testing.expect(contains(i32, &data, v));
    }
}

test "samples: zero count returns empty" {
    var prng = std.Random.DefaultPrng.init(0);
    const result = try samples(
        i32,
        std.testing.allocator,
        &.{ 1, 2, 3 },
        0,
        prng.random(),
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "samples: single element repeated" {
    var prng = std.Random.DefaultPrng.init(99);
    const result = try samples(
        i32,
        std.testing.allocator,
        &.{42},
        3,
        prng.random(),
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 42, 42, 42 }, result);
}

test "samples: empty input returns empty slice" {
    var prng = std.Random.DefaultPrng.init(0);
    const empty_slice: []const i32 = &.{};
    const result = try samples(i32, std.testing.allocator, empty_slice, 5, prng.random());
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "samples: empty input with n=0" {
    var prng = std.Random.DefaultPrng.init(0);
    const empty_slice: []const i32 = &.{};
    const result = try samples(i32, std.testing.allocator, empty_slice, 0, prng.random());
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "nth: overflow-length returns null" {
    // We cannot create a slice with length > maxInt(isize) in a test.
    // Instead, we verify boundary behavior and confirm that the fix
    // (std.math.cast replacing @intCast) compiles correctly.
    // The actual overflow protection is verified by code inspection.
    const data = [_]i32{42};
    try std.testing.expectEqual(@as(?i32, 42), nth(i32, &data, 0));
    try std.testing.expectEqual(@as(?i32, null), nth(i32, &data, 1));
    try std.testing.expectEqual(@as(?i32, null), nth(i32, &data, -2));
}

// Tests: Slicing.

test "drop: removes first n elements" {
    const result = drop(i32, &.{ 1, 2, 3, 4, 5 }, 2);
    try std.testing.expectEqualSlices(i32, &.{ 3, 4, 5 }, result);
}

test "drop: n exceeds length returns empty" {
    const result = drop(i32, &.{ 1, 2 }, 5);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "drop: zero returns whole slice" {
    const result = drop(i32, &.{ 1, 2, 3 }, 0);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "drop: empty slice" {
    const result = drop(i32, &.{}, 3);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "dropRight: removes last n elements" {
    const result = dropRight(i32, &.{ 1, 2, 3, 4, 5 }, 2);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "dropRight: n exceeds length returns empty" {
    const result = dropRight(i32, &.{ 1, 2 }, 5);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "dropRight: zero returns whole slice" {
    const result = dropRight(i32, &.{ 1, 2, 3 }, 0);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "dropWhile: drops while predicate true" {
    const lessThan3 = struct {
        fn f(x: i32) bool {
            return x < 3;
        }
    }.f;
    const result = dropWhile(i32, &.{ 1, 2, 3, 4 }, lessThan3);
    try std.testing.expectEqualSlices(i32, &.{ 3, 4 }, result);
}

test "dropWhile: all match returns empty" {
    const always = struct {
        fn f(_: i32) bool {
            return true;
        }
    }.f;
    const result = dropWhile(i32, &.{ 1, 2, 3 }, always);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "dropWhile: none match returns whole slice" {
    const never = struct {
        fn f(_: i32) bool {
            return false;
        }
    }.f;
    const result = dropWhile(i32, &.{ 1, 2, 3 }, never);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "dropRightWhile: drops from right" {
    const gt2 = struct {
        fn f(x: i32) bool {
            return x > 2;
        }
    }.f;
    const result = dropRightWhile(i32, &.{ 1, 2, 3, 4 }, gt2);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2 }, result);
}

test "dropRightWhile: all match returns empty" {
    const always = struct {
        fn f(_: i32) bool {
            return true;
        }
    }.f;
    const result = dropRightWhile(i32, &.{ 1, 2, 3 }, always);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "dropRightWhile: none match returns whole slice" {
    const never = struct {
        fn f(_: i32) bool {
            return false;
        }
    }.f;
    const result = dropRightWhile(i32, &.{ 1, 2, 3 }, never);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "take: takes first n elements" {
    const result = take(i32, &.{ 1, 2, 3, 4, 5 }, 3);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "take: n exceeds length returns whole slice" {
    const result = take(i32, &.{ 1, 2 }, 5);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2 }, result);
}

test "take: zero returns empty" {
    const result = take(i32, &.{ 1, 2, 3 }, 0);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "takeRight: takes last n elements" {
    const result = takeRight(i32, &.{ 1, 2, 3, 4, 5 }, 2);
    try std.testing.expectEqualSlices(i32, &.{ 4, 5 }, result);
}

test "takeRight: n exceeds length returns whole slice" {
    const result = takeRight(i32, &.{ 1, 2 }, 5);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2 }, result);
}

test "takeRight: zero returns empty" {
    const result = takeRight(i32, &.{ 1, 2, 3 }, 0);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "takeWhile: takes while predicate true" {
    const lessThan3 = struct {
        fn f(x: i32) bool {
            return x < 3;
        }
    }.f;
    const result = takeWhile(i32, &.{ 1, 2, 3, 4 }, lessThan3);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2 }, result);
}

test "takeWhile: all match returns whole slice" {
    const always = struct {
        fn f(_: i32) bool {
            return true;
        }
    }.f;
    const result = takeWhile(i32, &.{ 1, 2, 3 }, always);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "takeWhile: none match returns empty" {
    const never = struct {
        fn f(_: i32) bool {
            return false;
        }
    }.f;
    const result = takeWhile(i32, &.{ 1, 2, 3 }, never);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "takeRightWhile: takes from right" {
    const gt2 = struct {
        fn f(x: i32) bool {
            return x > 2;
        }
    }.f;
    const result = takeRightWhile(i32, &.{ 1, 2, 3, 4 }, gt2);
    try std.testing.expectEqualSlices(i32, &.{ 3, 4 }, result);
}

test "takeRightWhile: all match returns whole slice" {
    const always = struct {
        fn f(_: i32) bool {
            return true;
        }
    }.f;
    const result = takeRightWhile(i32, &.{ 1, 2, 3 }, always);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "takeRightWhile: none match returns empty" {
    const never = struct {
        fn f(_: i32) bool {
            return false;
        }
    }.f;
    const result = takeRightWhile(i32, &.{ 1, 2, 3 }, never);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "initial: all except last" {
    const result = initial(i32, &.{ 1, 2, 3 });
    try std.testing.expectEqualSlices(i32, &.{ 1, 2 }, result);
}

test "initial: single element returns empty" {
    const result = initial(i32, &.{42});
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "initial: empty slice returns empty" {
    const result = initial(i32, &.{});
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "tail: all except first" {
    const result = tail(i32, &.{ 1, 2, 3 });
    try std.testing.expectEqualSlices(i32, &.{ 2, 3 }, result);
}

test "tail: single element returns empty" {
    const result = tail(i32, &.{42});
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "tail: empty slice returns empty" {
    const result = tail(i32, &.{});
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

// Tests: Search and query.

test "find: returns first match" {
    try std.testing.expectEqual(@as(?i32, 2), find(i32, &.{ 1, 2, 3, 4 }, isEven));
}

test "find: no match returns null" {
    try std.testing.expectEqual(@as(?i32, null), find(i32, &.{ 1, 3, 5 }, isEven));
}

test "find: empty slice returns null" {
    try std.testing.expectEqual(@as(?i32, null), find(i32, &.{}, isEven));
}

test "findIndex: returns first match index" {
    try std.testing.expectEqual(@as(?usize, 1), findIndex(i32, &.{ 1, 2, 3, 4 }, isEven));
}

test "findIndex: no match returns null" {
    try std.testing.expectEqual(@as(?usize, null), findIndex(i32, &.{ 1, 3, 5 }, isEven));
}

test "findIndex: empty slice returns null" {
    try std.testing.expectEqual(@as(?usize, null), findIndex(i32, &.{}, isEven));
}

test "findLast: returns last match" {
    try std.testing.expectEqual(@as(?i32, 4), findLast(i32, &.{ 1, 2, 3, 4 }, isEven));
}

test "findLast: no match returns null" {
    try std.testing.expectEqual(@as(?i32, null), findLast(i32, &.{ 1, 3, 5 }, isEven));
}

test "findLast: empty slice returns null" {
    try std.testing.expectEqual(@as(?i32, null), findLast(i32, &.{}, isEven));
}

test "findLastIndex: returns last match index" {
    try std.testing.expectEqual(@as(?usize, 3), findLastIndex(i32, &.{ 1, 2, 3, 4 }, isEven));
}

test "findLastIndex: no match returns null" {
    try std.testing.expectEqual(@as(?usize, null), findLastIndex(i32, &.{ 1, 3, 5 }, isEven));
}

test "findLastIndex: empty slice returns null" {
    try std.testing.expectEqual(@as(?usize, null), findLastIndex(i32, &.{}, isEven));
}

test "every: all match returns true" {
    try std.testing.expect(every(i32, &.{ 2, 4, 6 }, isEven));
}

test "every: one mismatch returns false" {
    try std.testing.expect(!every(i32, &.{ 2, 3, 6 }, isEven));
}

test "every: empty slice returns true" {
    try std.testing.expect(every(i32, &.{}, isEven));
}

test "some: at least one match returns true" {
    try std.testing.expect(some(i32, &.{ 1, 2, 3 }, isEven));
}

test "some: no match returns false" {
    try std.testing.expect(!some(i32, &.{ 1, 3, 5 }, isEven));
}

test "some: empty slice returns false" {
    try std.testing.expect(!some(i32, &.{}, isEven));
}

test "none: no match returns true" {
    try std.testing.expect(none(i32, &.{ 1, 3, 5 }, isEven));
}

test "none: has match returns false" {
    try std.testing.expect(!none(i32, &.{ 1, 2, 3 }, isEven));
}

test "none: empty slice returns true" {
    try std.testing.expect(none(i32, &.{}, isEven));
}

test "count: counts matching elements" {
    try std.testing.expectEqual(@as(usize, 2), count(i32, &.{ 1, 2, 3, 4 }, isEven));
}

test "count: no matches returns zero" {
    try std.testing.expectEqual(@as(usize, 0), count(i32, &.{ 1, 3, 5 }, isEven));
}

test "count: empty slice returns zero" {
    try std.testing.expectEqual(@as(usize, 0), count(i32, &.{}, isEven));
}

test "countValues: frequency map" {
    var freq = try countValues(i32, std.testing.allocator, &.{ 1, 2, 2, 3, 2, 1 });
    defer freq.deinit();
    try std.testing.expectEqual(@as(usize, 2), freq.get(1).?);
    try std.testing.expectEqual(@as(usize, 3), freq.get(2).?);
    try std.testing.expectEqual(@as(usize, 1), freq.get(3).?);
}

test "countValues: empty slice" {
    var freq = try countValues(i32, std.testing.allocator, &.{});
    defer freq.deinit();
    try std.testing.expectEqual(@as(usize, 0), freq.count());
}

test "countValues: single element" {
    var freq = try countValues(i32, std.testing.allocator, &.{42});
    defer freq.deinit();
    try std.testing.expectEqual(@as(usize, 1), freq.get(42).?);
}

// Tests: Aggregation.

test "reduce: sum via reduce" {
    const add = struct {
        fn f(acc: i32, x: i32) i32 {
            return acc + x;
        }
    }.f;
    try std.testing.expectEqual(@as(i32, 6), reduce(i32, i32, &.{ 1, 2, 3 }, add, 0));
}

test "reduce: empty slice returns initial" {
    const add = struct {
        fn f(acc: i32, x: i32) i32 {
            return acc + x;
        }
    }.f;
    try std.testing.expectEqual(@as(i32, 99), reduce(i32, i32, &.{}, add, 99));
}

test "reduce: string concatenation via length sum" {
    const addLen = struct {
        fn f(acc: usize, s: []const u8) usize {
            return acc + s.len;
        }
    }.f;
    const strs = [_][]const u8{ "hello", " ", "world" };
    try std.testing.expectEqual(
        @as(usize, 11),
        reduce([]const u8, usize, &strs, addLen, 0),
    );
}

test "reduceRight: processes right to left" {
    const sub = struct {
        fn f(acc: i32, x: i32) i32 {
            return acc - x;
        }
    }.f;
    // 0 - 3 - 2 - 1 = -6
    try std.testing.expectEqual(
        @as(i32, -6),
        reduceRight(i32, i32, &.{ 1, 2, 3 }, sub, 0),
    );
}

test "reduceRight: empty slice returns initial" {
    const add = struct {
        fn f(acc: i32, x: i32) i32 {
            return acc + x;
        }
    }.f;
    try std.testing.expectEqual(
        @as(i32, 42),
        reduceRight(i32, i32, &.{}, add, 42),
    );
}

test "reduceRight: single element" {
    const add = struct {
        fn f(acc: i32, x: i32) i32 {
            return acc + x;
        }
    }.f;
    try std.testing.expectEqual(
        @as(i32, 10),
        reduceRight(i32, i32, &.{10}, add, 0),
    );
}

test "forEach: invokes on each element" {
    const Counter = struct {
        var total: i32 = 0;
        fn add(x: i32) void {
            total += x;
        }
    };
    Counter.total = 0;
    forEach(i32, &.{ 1, 2, 3 }, Counter.add);
    try std.testing.expectEqual(@as(i32, 6), Counter.total);
}

test "forEach: empty slice does nothing" {
    const Counter = struct {
        var calls: usize = 0;
        fn bump(_: i32) void {
            calls += 1;
        }
    };
    Counter.calls = 0;
    forEach(i32, &.{}, Counter.bump);
    try std.testing.expectEqual(@as(usize, 0), Counter.calls);
}

test "forEach: single element" {
    const Counter = struct {
        var total: i32 = 0;
        fn add(x: i32) void {
            total += x;
        }
    };
    Counter.total = 0;
    forEach(i32, &.{42}, Counter.add);
    try std.testing.expectEqual(@as(i32, 42), Counter.total);
}

test "forEachIndex: invokes with index" {
    const Tracker = struct {
        var sum_indices: usize = 0;
        fn track(_: i32, i: usize) void {
            sum_indices += i;
        }
    };
    Tracker.sum_indices = 0;
    forEachIndex(i32, &.{ 10, 20, 30 }, Tracker.track);
    // 0 + 1 + 2 = 3
    try std.testing.expectEqual(@as(usize, 3), Tracker.sum_indices);
}

test "forEachIndex: empty slice does nothing" {
    const Tracker = struct {
        var calls: usize = 0;
        fn track(_: i32, _: usize) void {
            calls += 1;
        }
    };
    Tracker.calls = 0;
    forEachIndex(i32, &.{}, Tracker.track);
    try std.testing.expectEqual(@as(usize, 0), Tracker.calls);
}

test "forEachIndex: single element gets index 0" {
    const Tracker = struct {
        var last_index: usize = 999;
        fn track(_: i32, i: usize) void {
            last_index = i;
        }
    };
    Tracker.last_index = 999;
    forEachIndex(i32, &.{42}, Tracker.track);
    try std.testing.expectEqual(@as(usize, 0), Tracker.last_index);
}

// Tests: Iterators and transformation.

const double = struct {
    fn f(x: i32) i64 {
        return @as(i64, x) * 2;
    }
}.f;

test "map: transforms via iterator" {
    var it = map(i32, i64, &.{ 1, 2, 3 }, double);
    try std.testing.expectEqual(@as(?i64, 2), it.next());
    try std.testing.expectEqual(@as(?i64, 4), it.next());
    try std.testing.expectEqual(@as(?i64, 6), it.next());
    try std.testing.expectEqual(@as(?i64, null), it.next());
}

test "map: empty slice" {
    var it = map(i32, i64, &.{}, double);
    try std.testing.expectEqual(@as(?i64, null), it.next());
}

test "map: collect allocates result" {
    var it = map(i32, i64, &.{ 1, 2, 3 }, double);
    const result = try it.collect(std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i64, &.{ 2, 4, 6 }, result);
}

test "mapAlloc: transforms into allocated slice" {
    const result = try mapAlloc(
        i32,
        i64,
        std.testing.allocator,
        &.{ 1, 2, 3 },
        double,
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i64, &.{ 2, 4, 6 }, result);
}

test "mapAlloc: empty slice" {
    const result = try mapAlloc(
        i32,
        i64,
        std.testing.allocator,
        &.{},
        double,
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "mapAlloc: single element" {
    const result = try mapAlloc(
        i32,
        i64,
        std.testing.allocator,
        &.{5},
        double,
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i64, &.{10}, result);
}

test "mapIndex: transforms with index" {
    const addIndex = struct {
        fn f(x: i32, i: usize) i64 {
            return @as(i64, x) + @as(i64, @intCast(i));
        }
    }.f;
    var it = mapIndex(i32, i64, &.{ 10, 20, 30 }, addIndex);
    try std.testing.expectEqual(@as(?i64, 10), it.next());
    try std.testing.expectEqual(@as(?i64, 21), it.next());
    try std.testing.expectEqual(@as(?i64, 32), it.next());
    try std.testing.expectEqual(@as(?i64, null), it.next());
}

test "mapIndex: empty slice" {
    const addIndex = struct {
        fn f(x: i32, i: usize) i64 {
            return @as(i64, x) + @as(i64, @intCast(i));
        }
    }.f;
    var it = mapIndex(i32, i64, &.{}, addIndex);
    try std.testing.expectEqual(@as(?i64, null), it.next());
}

test "mapIndex: collect" {
    const addIndex = struct {
        fn f(x: i32, i: usize) i64 {
            return @as(i64, x) + @as(i64, @intCast(i));
        }
    }.f;
    var it = mapIndex(i32, i64, &.{ 10, 20, 30 }, addIndex);
    const result = try it.collect(std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i64, &.{ 10, 21, 32 }, result);
}

test "filter: keeps matching elements" {
    var it = filter(i32, &.{ 1, 2, 3, 4, 5, 6 }, isEven);
    try std.testing.expectEqual(@as(?i32, 2), it.next());
    try std.testing.expectEqual(@as(?i32, 4), it.next());
    try std.testing.expectEqual(@as(?i32, 6), it.next());
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

test "filter: no matches yields nothing" {
    var it = filter(i32, &.{ 1, 3, 5 }, isEven);
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

test "filter: empty slice" {
    var it = filter(i32, &.{}, isEven);
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

test "filter: collect" {
    var it = filter(i32, &.{ 1, 2, 3, 4 }, isEven);
    const result = try it.collect(std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 2, 4 }, result);
}

test "filterAlloc: allocated result" {
    const result = try filterAlloc(
        i32,
        std.testing.allocator,
        &.{ 1, 2, 3, 4, 5, 6 },
        isEven,
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 2, 4, 6 }, result);
}

test "filterAlloc: empty input" {
    const result = try filterAlloc(
        i32,
        std.testing.allocator,
        &.{},
        isEven,
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "filterAlloc: no matches" {
    const result = try filterAlloc(
        i32,
        std.testing.allocator,
        &.{ 1, 3, 5 },
        isEven,
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "reject: removes matching elements" {
    var it = reject(i32, &.{ 1, 2, 3, 4 }, isEven);
    try std.testing.expectEqual(@as(?i32, 1), it.next());
    try std.testing.expectEqual(@as(?i32, 3), it.next());
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

test "reject: no matches keeps all" {
    var it = reject(i32, &.{ 1, 3, 5 }, isEven);
    try std.testing.expectEqual(@as(?i32, 1), it.next());
    try std.testing.expectEqual(@as(?i32, 3), it.next());
    try std.testing.expectEqual(@as(?i32, 5), it.next());
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

test "reject: empty slice" {
    var it = reject(i32, &.{}, isEven);
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

test "rejectAlloc: allocated result" {
    const result = try rejectAlloc(
        i32,
        std.testing.allocator,
        &.{ 1, 2, 3, 4 },
        isEven,
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 3 }, result);
}

test "rejectAlloc: empty slice" {
    const result = try rejectAlloc(
        i32,
        std.testing.allocator,
        &.{},
        isEven,
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "rejectAlloc: all match returns empty" {
    const result = try rejectAlloc(
        i32,
        std.testing.allocator,
        &.{ 2, 4, 6 },
        isEven,
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "flatten: merges slices" {
    const a = [_]i32{ 1, 2 };
    const b = [_]i32{ 3, 4 };
    const c = [_]i32{5};
    const slices = [_][]const i32{ &a, &b, &c };
    var it = flatten(i32, &slices);
    const result = try it.collect(std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3, 4, 5 }, result);
}

test "flatten: empty outer slice" {
    const slices = [_][]const i32{};
    var it = flatten(i32, &slices);
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

test "flatten: contains empty inner slices" {
    const a = [_]i32{ 1, 2 };
    const b = [_]i32{};
    const c = [_]i32{3};
    const slices = [_][]const i32{ &a, &b, &c };
    var it = flatten(i32, &slices);
    const result = try it.collect(std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "flattenAlloc: allocated result" {
    const a = [_]i32{ 1, 2 };
    const b = [_]i32{ 3, 4 };
    const slices = [_][]const i32{ &a, &b };
    const result = try flattenAlloc(i32, std.testing.allocator, &slices);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3, 4 }, result);
}

test "flatMap: map then flatten" {
    // Map each i32 to a pair of itself repeated
    const Pairs = struct {
        const pairs = [_][2]i32{ .{ 1, 1 }, .{ 2, 2 }, .{ 3, 3 } };
        fn repeat(x: i32) []const i32 {
            return &pairs[@intCast(x - 1)];
        }
    };
    var it = flatMap(i32, i32, &.{ 1, 2, 3 }, Pairs.repeat);
    const result = try it.collect(std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(
        i32,
        &.{ 1, 1, 2, 2, 3, 3 },
        result,
    );
}

test "flatMap: empty input" {
    const identity = struct {
        fn f(_: i32) []const i32 {
            return &.{};
        }
    }.f;
    var it = flatMap(i32, i32, &.{}, identity);
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

test "flatMap: transform returns empty slices" {
    const toEmpty = struct {
        fn f(_: i32) []const i32 {
            return &.{};
        }
    }.f;
    var it = flatMap(i32, i32, &.{ 1, 2, 3 }, toEmpty);
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

test "compact: removes zero integers" {
    var it = compact(i32, &.{ 0, 1, 0, 2, 0, 3 });
    try std.testing.expectEqual(@as(?i32, 1), it.next());
    try std.testing.expectEqual(@as(?i32, 2), it.next());
    try std.testing.expectEqual(@as(?i32, 3), it.next());
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

test "compact: removes null optionals" {
    var it = compact(?i32, &.{ @as(?i32, 1), null, @as(?i32, 3), null });
    try std.testing.expectEqual(@as(??i32, 1), it.next());
    try std.testing.expectEqual(@as(??i32, 3), it.next());
    try std.testing.expectEqual(@as(??i32, null), it.next());
}

test "compact: empty slice" {
    var it = compact(i32, &.{});
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

test "compactAlloc: allocated result" {
    const result = try compactAlloc(
        i32,
        std.testing.allocator,
        &.{ 0, 1, 0, 2, 0, 3 },
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "chunk: splits into groups" {
    var it = chunk(i32, &.{ 1, 2, 3, 4, 5 }, 2);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2 }, it.next().?);
    try std.testing.expectEqualSlices(i32, &.{ 3, 4 }, it.next().?);
    try std.testing.expectEqualSlices(i32, &.{5}, it.next().?);
    try std.testing.expectEqual(@as(?[]const i32, null), it.next());
}

test "chunk: exact division" {
    var it = chunk(i32, &.{ 1, 2, 3, 4 }, 2);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2 }, it.next().?);
    try std.testing.expectEqualSlices(i32, &.{ 3, 4 }, it.next().?);
    try std.testing.expectEqual(@as(?[]const i32, null), it.next());
}

test "chunk: empty slice" {
    var it = chunk(i32, &.{}, 3);
    try std.testing.expectEqual(@as(?[]const i32, null), it.next());
}

test "chunk: size larger than slice" {
    var it = chunk(i32, &.{ 1, 2 }, 10);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2 }, it.next().?);
    try std.testing.expectEqual(@as(?[]const i32, null), it.next());
}

test "without: excludes values" {
    var it = without(i32, &.{ 1, 2, 3, 4, 5 }, &.{ 2, 4 });
    const result = try it.collect(std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 3, 5 }, result);
}

test "without: nothing excluded" {
    var it = without(i32, &.{ 1, 2, 3 }, &.{});
    const result = try it.collect(std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "without: all excluded" {
    var it = without(i32, &.{ 1, 2 }, &.{ 1, 2 });
    const result = try it.collect(std.testing.allocator);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "without: empty input" {
    var it = without(i32, &.{}, &.{ 1, 2 });
    try std.testing.expectEqual(@as(?i32, null), it.next());
}

// Tests: Advanced operations.

test "uniq: removes duplicates" {
    const result = try uniq(i32, std.testing.allocator, &.{ 1, 2, 2, 3, 1, 3 });
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "uniq: empty slice" {
    const result = try uniq(i32, std.testing.allocator, &.{});
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "uniq: no duplicates" {
    const result = try uniq(i32, std.testing.allocator, &.{ 1, 2, 3 });
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "uniq: all same" {
    const result = try uniq(i32, std.testing.allocator, &.{ 5, 5, 5, 5 });
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{5}, result);
}

test "uniqBy: deduplicates by key" {
    const abs = struct {
        fn f(x: i32) u32 {
            return @intCast(@abs(x));
        }
    }.f;
    const result = try uniqBy(
        i32,
        u32,
        std.testing.allocator,
        &.{ 1, -1, 2, -2, 3 },
        abs,
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "uniqBy: empty slice" {
    const identity = struct {
        fn f(x: i32) i32 {
            return x;
        }
    }.f;
    const result = try uniqBy(
        i32,
        i32,
        std.testing.allocator,
        &.{},
        identity,
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "uniqBy: all unique keys" {
    const identity = struct {
        fn f(x: i32) i32 {
            return x;
        }
    }.f;
    const result = try uniqBy(
        i32,
        i32,
        std.testing.allocator,
        &.{ 1, 2, 3 },
        identity,
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, result);
}

test "groupBy: groups elements" {
    const parity = struct {
        fn f(x: i32) bool {
            return @mod(x, 2) == 0;
        }
    }.f;
    var groups = try groupBy(
        i32,
        bool,
        std.testing.allocator,
        &.{ 1, 2, 3, 4, 5, 6 },
        parity,
    );
    defer {
        var vit = groups.valueIterator();
        while (vit.next()) |list| list.deinit(std.testing.allocator);
        groups.deinit();
    }
    try std.testing.expectEqualSlices(i32, &.{ 2, 4, 6 }, groups.get(true).?.items);
    try std.testing.expectEqualSlices(i32, &.{ 1, 3, 5 }, groups.get(false).?.items);
}

test "groupBy: empty slice" {
    const identity = struct {
        fn f(x: i32) i32 {
            return x;
        }
    }.f;
    var groups = try groupBy(
        i32,
        i32,
        std.testing.allocator,
        &.{},
        identity,
    );
    defer groups.deinit();
    try std.testing.expectEqual(@as(usize, 0), groups.count());
}

test "groupBy: single group" {
    const always1 = struct {
        fn f(_: i32) i32 {
            return 1;
        }
    }.f;
    var groups = try groupBy(
        i32,
        i32,
        std.testing.allocator,
        &.{ 10, 20, 30 },
        always1,
    );
    defer {
        var vit = groups.valueIterator();
        while (vit.next()) |list| list.deinit(std.testing.allocator);
        groups.deinit();
    }
    try std.testing.expectEqual(@as(usize, 1), groups.count());
    try std.testing.expectEqualSlices(i32, &.{ 10, 20, 30 }, groups.get(1).?.items);
}

test "partition: splits by predicate" {
    const p = try partition(
        i32,
        std.testing.allocator,
        &.{ 1, 2, 3, 4, 5, 6 },
        isEven,
    );
    defer p.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(i32, &.{ 2, 4, 6 }, p.matching);
    try std.testing.expectEqualSlices(i32, &.{ 1, 3, 5 }, p.rest);
}

test "partition: empty slice" {
    const p = try partition(
        i32,
        std.testing.allocator,
        &.{},
        isEven,
    );
    defer p.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 0), p.matching.len);
    try std.testing.expectEqual(@as(usize, 0), p.rest.len);
}

test "partition: all match" {
    const p = try partition(
        i32,
        std.testing.allocator,
        &.{ 2, 4, 6 },
        isEven,
    );
    defer p.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(i32, &.{ 2, 4, 6 }, p.matching);
    try std.testing.expectEqual(@as(usize, 0), p.rest.len);
}

// Tests: Set operations.

test "intersect: common elements" {
    const result = try intersect(
        i32,
        std.testing.allocator,
        &.{ 1, 2, 3, 4 },
        &.{ 2, 4, 6 },
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 2, 4 }, result);
}

test "intersect: no common elements" {
    const result = try intersect(
        i32,
        std.testing.allocator,
        &.{ 1, 2 },
        &.{ 3, 4 },
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "intersect: empty input" {
    const result = try intersect(
        i32,
        std.testing.allocator,
        &.{},
        &.{ 1, 2 },
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "union_: combines unique elements" {
    const result = try union_(
        i32,
        std.testing.allocator,
        &.{ 1, 2, 3 },
        &.{ 2, 3, 4 },
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3, 4 }, result);
}

test "union_: disjoint slices" {
    const result = try union_(
        i32,
        std.testing.allocator,
        &.{ 1, 2 },
        &.{ 3, 4 },
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3, 4 }, result);
}

test "union_: empty inputs" {
    const result = try union_(
        i32,
        std.testing.allocator,
        &.{},
        &.{},
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "difference: elements in first not in second" {
    const result = try difference(
        i32,
        std.testing.allocator,
        &.{ 1, 2, 3, 4 },
        &.{ 2, 4 },
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 3 }, result);
}

test "difference: no overlap" {
    const result = try difference(
        i32,
        std.testing.allocator,
        &.{ 1, 2 },
        &.{ 3, 4 },
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2 }, result);
}

test "difference: all overlap" {
    const result = try difference(
        i32,
        std.testing.allocator,
        &.{ 1, 2 },
        &.{ 1, 2 },
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "symmetricDifference: exclusive elements" {
    const result = try symmetricDifference(
        i32,
        std.testing.allocator,
        &.{ 1, 2, 3 },
        &.{ 2, 3, 4 },
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 4 }, result);
}

test "symmetricDifference: disjoint" {
    const result = try symmetricDifference(
        i32,
        std.testing.allocator,
        &.{ 1, 2 },
        &.{ 3, 4 },
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3, 4 }, result);
}

test "symmetricDifference: identical" {
    const result = try symmetricDifference(
        i32,
        std.testing.allocator,
        &.{ 1, 2, 3 },
        &.{ 1, 2, 3 },
    );
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

// Tests: In-place mutation.

test "reverse: reverses in-place" {
    var data = [_]i32{ 1, 2, 3, 4, 5 };
    reverse(i32, &data);
    try std.testing.expectEqualSlices(i32, &.{ 5, 4, 3, 2, 1 }, &data);
}

test "reverse: single element" {
    var data = [_]i32{42};
    reverse(i32, &data);
    try std.testing.expectEqualSlices(i32, &.{42}, &data);
}

test "reverse: empty slice" {
    var data = [_]i32{};
    reverse(i32, &data);
    try std.testing.expectEqual(@as(usize, 0), data.len);
}

test "reverse: two elements" {
    var data = [_]i32{ 1, 2 };
    reverse(i32, &data);
    try std.testing.expectEqualSlices(i32, &.{ 2, 1 }, &data);
}

test "shuffle: preserves all elements" {
    var prng = std.Random.DefaultPrng.init(12345);
    var data = [_]i32{ 1, 2, 3, 4, 5 };
    shuffle(i32, &data, prng.random());
    var sorted = data;
    std.mem.sort(i32, &sorted, {}, std.sort.asc(i32));
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3, 4, 5 }, &sorted);
}

test "shuffle: empty slice" {
    var data = [_]i32{};
    var prng = std.Random.DefaultPrng.init(0);
    shuffle(i32, &data, prng.random());
    try std.testing.expectEqual(@as(usize, 0), data.len);
}

test "shuffle: single element unchanged" {
    var data = [_]i32{42};
    var prng = std.Random.DefaultPrng.init(0);
    shuffle(i32, &data, prng.random());
    try std.testing.expectEqualSlices(i32, &.{42}, &data);
}

test "fill: fills all elements" {
    var data = [_]i32{ 0, 0, 0, 0 };
    fill(i32, &data, 42);
    try std.testing.expectEqualSlices(i32, &.{ 42, 42, 42, 42 }, &data);
}

test "fill: empty slice" {
    var data = [_]i32{};
    fill(i32, &data, 99);
    try std.testing.expectEqual(@as(usize, 0), data.len);
}

test "fill: single element" {
    var data = [_]i32{0};
    fill(i32, &data, 7);
    try std.testing.expectEqualSlices(i32, &.{7}, &data);
}

test "fillRange: fills within range" {
    var data = [_]i32{ 1, 2, 3, 4, 5 };
    fillRange(i32, &data, 0, 1, 4);
    try std.testing.expectEqualSlices(i32, &.{ 1, 0, 0, 0, 5 }, &data);
}

test "fillRange: start equals end does nothing" {
    var data = [_]i32{ 1, 2, 3 };
    fillRange(i32, &data, 99, 2, 2);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, &data);
}

test "fillRange: clamps to slice bounds" {
    var data = [_]i32{ 1, 2, 3 };
    fillRange(i32, &data, 0, 0, 100);
    try std.testing.expectEqualSlices(i32, &.{ 0, 0, 0 }, &data);
}

// Tests: Other utilities.

test "repeat: creates n copies" {
    const result = try repeat(i32, std.testing.allocator, 42, 3);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 42, 42, 42 }, result);
}

test "repeat: zero copies" {
    const result = try repeat(i32, std.testing.allocator, 42, 0);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "repeat: single copy" {
    const result = try repeat(i32, std.testing.allocator, 7, 1);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{7}, result);
}

test "repeatBy: generates via callback" {
    const square = struct {
        fn f(i: usize) i32 {
            const val: i32 = @intCast(i);
            return val * val;
        }
    }.f;
    const result = try repeatBy(i32, std.testing.allocator, 4, square);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{ 0, 1, 4, 9 }, result);
}

test "repeatBy: zero count" {
    const noop = struct {
        fn f(_: usize) i32 {
            return 0;
        }
    }.f;
    const result = try repeatBy(i32, std.testing.allocator, 0, noop);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "repeatBy: single element" {
    const always42 = struct {
        fn f(_: usize) i32 {
            return 42;
        }
    }.f;
    const result = try repeatBy(i32, std.testing.allocator, 1, always42);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(i32, &.{42}, result);
}

test "isSorted: ascending sorted" {
    const asc = struct {
        fn f(a: i32, b: i32) std.math.Order {
            return std.math.order(a, b);
        }
    }.f;
    try std.testing.expect(isSorted(i32, &.{ 1, 2, 3, 4, 5 }, asc));
}

test "isSorted: not sorted" {
    const asc = struct {
        fn f(a: i32, b: i32) std.math.Order {
            return std.math.order(a, b);
        }
    }.f;
    try std.testing.expect(!isSorted(i32, &.{ 1, 3, 2 }, asc));
}

test "isSorted: empty is sorted" {
    const asc = struct {
        fn f(a: i32, b: i32) std.math.Order {
            return std.math.order(a, b);
        }
    }.f;
    try std.testing.expect(isSorted(i32, &.{}, asc));
}

test "isSorted: single element is sorted" {
    const asc = struct {
        fn f(a: i32, b: i32) std.math.Order {
            return std.math.order(a, b);
        }
    }.f;
    try std.testing.expect(isSorted(i32, &.{42}, asc));
}

test "equal: same elements" {
    try std.testing.expect(equal(i32, &.{ 1, 2, 3 }, &.{ 1, 2, 3 }));
}

test "equal: different elements" {
    try std.testing.expect(!equal(i32, &.{ 1, 2, 3 }, &.{ 1, 2, 4 }));
}

test "equal: different lengths" {
    try std.testing.expect(!equal(i32, &.{ 1, 2 }, &.{ 1, 2, 3 }));
}

test "equal: both empty" {
    try std.testing.expect(equal(i32, &.{}, &.{}));
}

// Tests: keyBy.

test "keyBy: converts slice to map indexed by key" {
    const Person = struct { name: []const u8, age: u32 };
    const getAge = struct {
        fn f(p: Person) u32 {
            return p.age;
        }
    }.f;
    const people = [_]Person{
        .{ .name = "alice", .age = 30 },
        .{ .name = "bob", .age = 25 },
    };
    var m = try keyBy(Person, u32, std.testing.allocator, &people, getAge);
    defer m.deinit();
    try std.testing.expectEqualSlices(u8, "alice", m.get(30).?.name);
    try std.testing.expectEqualSlices(u8, "bob", m.get(25).?.name);
    try std.testing.expectEqual(@as(usize, 2), m.count());
}

test "keyBy: duplicate keys last wins" {
    const Person = struct { name: []const u8, age: u32 };
    const getAge = struct {
        fn f(p: Person) u32 {
            return p.age;
        }
    }.f;
    const people = [_]Person{
        .{ .name = "alice", .age = 30 },
        .{ .name = "bob", .age = 30 },
    };
    var m = try keyBy(Person, u32, std.testing.allocator, &people, getAge);
    defer m.deinit();
    try std.testing.expectEqualSlices(u8, "bob", m.get(30).?.name);
    try std.testing.expectEqual(@as(usize, 1), m.count());
}

test "keyBy: empty slice" {
    const getId = struct {
        fn f(x: i32) i32 {
            return x;
        }
    }.f;
    var m = try keyBy(i32, i32, std.testing.allocator, &.{}, getId);
    defer m.deinit();
    try std.testing.expectEqual(@as(usize, 0), m.count());
}

test "keyBy: single element" {
    const getId = struct {
        fn f(x: i32) i32 {
            return x;
        }
    }.f;
    var m = try keyBy(i32, i32, std.testing.allocator, &.{42}, getId);
    defer m.deinit();
    try std.testing.expectEqual(@as(usize, 1), m.count());
    try std.testing.expectEqual(@as(i32, 42), m.get(42).?);
}

// Tests: associate.

test "associate: converts slice to map with custom key+value" {
    const Person = struct { name: []const u8, age: u32 };
    const personToEntry = struct {
        fn f(p: Person) AssocEntry(u32, []const u8) {
            return .{ .key = p.age, .value = p.name };
        }
    }.f;
    const people = [_]Person{
        .{ .name = "alice", .age = 30 },
        .{ .name = "bob", .age = 25 },
    };
    var m = try associate(Person, u32, []const u8, std.testing.allocator, &people, personToEntry);
    defer m.deinit();
    try std.testing.expectEqualSlices(u8, "alice", m.get(30).?);
    try std.testing.expectEqualSlices(u8, "bob", m.get(25).?);
    try std.testing.expectEqual(@as(usize, 2), m.count());
}

test "associate: duplicate keys last wins" {
    const Person = struct { name: []const u8, age: u32 };
    const personToEntry = struct {
        fn f(p: Person) AssocEntry(u32, []const u8) {
            return .{ .key = p.age, .value = p.name };
        }
    }.f;
    const people = [_]Person{
        .{ .name = "alice", .age = 30 },
        .{ .name = "bob", .age = 30 },
    };
    var m = try associate(Person, u32, []const u8, std.testing.allocator, &people, personToEntry);
    defer m.deinit();
    try std.testing.expectEqualSlices(u8, "bob", m.get(30).?);
    try std.testing.expectEqual(@as(usize, 1), m.count());
}

test "associate: empty slice" {
    const toEntry = struct {
        fn f(x: i32) AssocEntry(i32, i32) {
            return .{ .key = x, .value = x * 10 };
        }
    }.f;
    var m = try associate(i32, i32, i32, std.testing.allocator, &.{}, toEntry);
    defer m.deinit();
    try std.testing.expectEqual(@as(usize, 0), m.count());
}

// Tests: countBy.

test "countBy: counts by predicate" {
    const isEvenCb = struct {
        fn f(x: i32) bool {
            return @mod(x, 2) == 0;
        }
    }.f;
    var m = try countBy(i32, bool, std.testing.allocator, &.{ 1, 2, 3, 4, 5 }, isEvenCb);
    defer m.deinit();
    try std.testing.expectEqual(@as(usize, 2), m.get(true).?);
    try std.testing.expectEqual(@as(usize, 3), m.get(false).?);
}

test "countBy: all same key" {
    const always = struct {
        fn f(_: i32) bool {
            return true;
        }
    }.f;
    var m = try countBy(i32, bool, std.testing.allocator, &.{ 1, 2, 3 }, always);
    defer m.deinit();
    try std.testing.expectEqual(@as(usize, 3), m.get(true).?);
}

test "countBy: all different keys" {
    const identity = struct {
        fn f(x: i32) i32 {
            return x;
        }
    }.f;
    var m = try countBy(i32, i32, std.testing.allocator, &.{ 1, 2, 3 }, identity);
    defer m.deinit();
    try std.testing.expectEqual(@as(usize, 1), m.get(1).?);
    try std.testing.expectEqual(@as(usize, 1), m.get(2).?);
    try std.testing.expectEqual(@as(usize, 1), m.get(3).?);
}

test "countBy: empty slice" {
    const identity = struct {
        fn f(x: i32) i32 {
            return x;
        }
    }.f;
    var m = try countBy(i32, i32, std.testing.allocator, &.{}, identity);
    defer m.deinit();
    try std.testing.expectEqual(@as(usize, 0), m.count());
}

// Tests: findDuplicates.

test "findDuplicates: returns duplicated elements" {
    const dups = try findDuplicates(i32, std.testing.allocator, &.{ 1, 2, 2, 3, 3, 3 });
    defer std.testing.allocator.free(dups);
    try std.testing.expectEqualSlices(i32, &.{ 2, 3 }, dups);
}

test "findDuplicates: no duplicates" {
    const dups = try findDuplicates(i32, std.testing.allocator, &.{ 1, 2, 3 });
    defer std.testing.allocator.free(dups);
    try std.testing.expectEqualSlices(i32, &.{}, dups);
}

test "findDuplicates: all same" {
    const dups = try findDuplicates(i32, std.testing.allocator, &.{ 5, 5, 5 });
    defer std.testing.allocator.free(dups);
    try std.testing.expectEqualSlices(i32, &.{5}, dups);
}

test "findDuplicates: empty slice" {
    const dups = try findDuplicates(i32, std.testing.allocator, &.{});
    defer std.testing.allocator.free(dups);
    try std.testing.expectEqualSlices(i32, &.{}, dups);
}

test "findDuplicates: single element" {
    const dups = try findDuplicates(i32, std.testing.allocator, &.{42});
    defer std.testing.allocator.free(dups);
    try std.testing.expectEqualSlices(i32, &.{}, dups);
}

// Tests: findUniques.

test "findUniques: returns unique elements" {
    const uniques = try findUniques(i32, std.testing.allocator, &.{ 1, 2, 2, 3, 3, 3, 4 });
    defer std.testing.allocator.free(uniques);
    try std.testing.expectEqualSlices(i32, &.{ 1, 4 }, uniques);
}

test "findUniques: no uniques" {
    const uniques = try findUniques(i32, std.testing.allocator, &.{ 2, 2, 3, 3 });
    defer std.testing.allocator.free(uniques);
    try std.testing.expectEqualSlices(i32, &.{}, uniques);
}

test "findUniques: all unique" {
    const uniques = try findUniques(i32, std.testing.allocator, &.{ 1, 2, 3 });
    defer std.testing.allocator.free(uniques);
    try std.testing.expectEqualSlices(i32, &.{ 1, 2, 3 }, uniques);
}

test "findUniques: empty slice" {
    const uniques = try findUniques(i32, std.testing.allocator, &.{});
    defer std.testing.allocator.free(uniques);
    try std.testing.expectEqualSlices(i32, &.{}, uniques);
}

test "findUniques: single element" {
    const uniques = try findUniques(i32, std.testing.allocator, &.{42});
    defer std.testing.allocator.free(uniques);
    try std.testing.expectEqualSlices(i32, &.{42}, uniques);
}
