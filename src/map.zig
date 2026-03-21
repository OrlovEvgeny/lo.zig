const std = @import("std");
const Allocator = std.mem.Allocator;

/// A generic key-value pair type used by map utilities.
///
/// ```zig
/// const e = lo.Entry(u32, u8){ .key = 1, .value = 'a' };
/// ```
pub fn Entry(comptime K: type, comptime V: type) type {
    return struct { key: K, value: V };
}

/// Iterator over map keys. Returned by `keys()`.
/// See `keys()` for usage examples.
pub fn KeyIterator(comptime K: type, comptime V: type) type {
    return struct {
        inner: std.AutoHashMap(K, V).Iterator,

        const Self = @This();

        pub fn next(self: *Self) ?K {
            if (self.inner.next()) |entry| return entry.key_ptr.*;
            return null;
        }
    };
}

/// Iterator over map values. Returned by `values()`.
/// See `values()` for usage examples.
pub fn ValueIterator(comptime K: type, comptime V: type) type {
    return struct {
        inner: std.AutoHashMap(K, V).Iterator,

        const Self = @This();

        pub fn next(self: *Self) ?V {
            if (self.inner.next()) |entry| return entry.value_ptr.*;
            return null;
        }
    };
}

/// Iterator over map key-value pairs. Returned by `entries()`.
/// See `entries()` for usage examples.
pub fn EntryIterator(comptime K: type, comptime V: type) type {
    return struct {
        inner: std.AutoHashMap(K, V).Iterator,

        const Self = @This();

        pub fn next(self: *Self) ?Entry(K, V) {
            if (self.inner.next()) |entry| {
                return .{
                    .key = entry.key_ptr.*,
                    .value = entry.value_ptr.*,
                };
            }
            return null;
        }
    };
}

/// Iterate over map keys.
///
/// ```zig
/// var it = lo.keys(u32, []const u8, &my_map);
/// while (it.next()) |key| { ... }
/// ```
pub fn keys(
    comptime K: type,
    comptime V: type,
    hash_map: *const std.AutoHashMap(K, V),
) KeyIterator(K, V) {
    return .{ .inner = hash_map.iterator() };
}

/// Collect all keys into an allocated slice.
/// Caller owns the returned slice.
///
/// ```zig
/// const ks = try lo.keysAlloc(u32, u8, allocator, &my_map);
/// defer allocator.free(ks);
/// ```
pub fn keysAlloc(
    comptime K: type,
    comptime V: type,
    allocator: Allocator,
    hash_map: *const std.AutoHashMap(K, V),
) Allocator.Error![]K {
    var list = std.ArrayList(K){};
    errdefer list.deinit(allocator);
    var it = hash_map.iterator();
    while (it.next()) |entry| {
        try list.append(allocator, entry.key_ptr.*);
    }
    return list.toOwnedSlice(allocator);
}

/// Iterate over map values.
///
/// ```zig
/// var it = lo.values(u32, []const u8, &my_map);
/// while (it.next()) |val| { ... }
/// ```
pub fn values(
    comptime K: type,
    comptime V: type,
    hash_map: *const std.AutoHashMap(K, V),
) ValueIterator(K, V) {
    return .{ .inner = hash_map.iterator() };
}

/// Collect all values into an allocated slice.
/// Caller owns the returned slice.
///
/// ```zig
/// const vs = try lo.valuesAlloc(u32, u8, allocator, &my_map);
/// defer allocator.free(vs);
/// ```
pub fn valuesAlloc(
    comptime K: type,
    comptime V: type,
    allocator: Allocator,
    hash_map: *const std.AutoHashMap(K, V),
) Allocator.Error![]V {
    var list = std.ArrayList(V){};
    errdefer list.deinit(allocator);
    var it = hash_map.iterator();
    while (it.next()) |entry| {
        try list.append(allocator, entry.value_ptr.*);
    }
    return list.toOwnedSlice(allocator);
}

/// Iterate over key-value pairs.
///
/// ```zig
/// var it = lo.entries(u32, []const u8, &my_map);
/// while (it.next()) |e| { _ = e.key; _ = e.value; }
/// ```
pub fn entries(
    comptime K: type,
    comptime V: type,
    hash_map: *const std.AutoHashMap(K, V),
) EntryIterator(K, V) {
    return .{ .inner = hash_map.iterator() };
}

/// Collect all key-value pairs into an allocated slice.
/// Caller owns the returned slice.
///
/// ```zig
/// const es = try lo.entriesAlloc(u32, u8, allocator, &my_map);
/// defer allocator.free(es);
/// ```
pub fn entriesAlloc(
    comptime K: type,
    comptime V: type,
    allocator: Allocator,
    hash_map: *const std.AutoHashMap(K, V),
) Allocator.Error![]Entry(K, V) {
    var list = std.ArrayList(Entry(K, V)){};
    errdefer list.deinit(allocator);
    var it = hash_map.iterator();
    while (it.next()) |entry| {
        try list.append(allocator, .{
            .key = entry.key_ptr.*,
            .value = entry.value_ptr.*,
        });
    }
    return list.toOwnedSlice(allocator);
}

/// Build a map from a slice of key-value pairs.
/// Caller owns the returned map.
///
/// ```zig
/// const pairs = [_]lo.Entry(u32, u8){ .{.key=1, .value='a'} };
/// var m = try lo.fromEntries(u32, u8, allocator, &pairs);
/// defer m.deinit();
/// ```
pub fn fromEntries(
    comptime K: type,
    comptime V: type,
    allocator: Allocator,
    pairs: []const Entry(K, V),
) Allocator.Error!std.AutoHashMap(K, V) {
    var result = std.AutoHashMap(K, V).init(allocator);
    errdefer result.deinit();
    for (pairs) |pair| {
        try result.put(pair.key, pair.value);
    }
    return result;
}

/// Transform map keys using a function.
/// Caller owns the returned map.
///
/// ```zig
/// var result = try lo.mapKeys(u32, u8, u64, allocator, &m, timesTwo);
/// defer result.deinit();
/// ```
pub fn mapKeys(
    comptime K: type,
    comptime V: type,
    comptime K2: type,
    allocator: Allocator,
    hash_map: *const std.AutoHashMap(K, V),
    transform: *const fn (K) K2,
) Allocator.Error!std.AutoHashMap(K2, V) {
    var result = std.AutoHashMap(K2, V).init(allocator);
    errdefer result.deinit();
    var it = hash_map.iterator();
    while (it.next()) |entry| {
        try result.put(transform(entry.key_ptr.*), entry.value_ptr.*);
    }
    return result;
}

/// Transform map values using a function.
/// Caller owns the returned map.
///
/// ```zig
/// var result = try lo.mapValues(u32, u8, u16, allocator, &m, multiply);
/// defer result.deinit();
/// ```
pub fn mapValues(
    comptime K: type,
    comptime V: type,
    comptime V2: type,
    allocator: Allocator,
    hash_map: *const std.AutoHashMap(K, V),
    transform: *const fn (V) V2,
) Allocator.Error!std.AutoHashMap(K, V2) {
    var result = std.AutoHashMap(K, V2).init(allocator);
    errdefer result.deinit();
    var it = hash_map.iterator();
    while (it.next()) |entry| {
        try result.put(entry.key_ptr.*, transform(entry.value_ptr.*));
    }
    return result;
}

/// Filter map entries by a predicate on key and value.
/// Caller owns the returned map.
///
/// ```zig
/// var result = try lo.filterMap(u32, u8, allocator, &m, keyGt1);
/// defer result.deinit();
/// ```
pub fn filterMap(
    comptime K: type,
    comptime V: type,
    allocator: Allocator,
    hash_map: *const std.AutoHashMap(K, V),
    predicate: *const fn (K, V) bool,
) Allocator.Error!std.AutoHashMap(K, V) {
    var result = std.AutoHashMap(K, V).init(allocator);
    errdefer result.deinit();
    var it = hash_map.iterator();
    while (it.next()) |entry| {
        if (predicate(entry.key_ptr.*, entry.value_ptr.*)) {
            try result.put(entry.key_ptr.*, entry.value_ptr.*);
        }
    }
    return result;
}

/// Keep only entries with the specified keys.
/// Caller owns the returned map.
///
/// ```zig
/// var result = try lo.pickKeys(u32, u8, allocator, &m, &.{ 1, 3 });
/// defer result.deinit();
/// ```
pub fn pickKeys(
    comptime K: type,
    comptime V: type,
    allocator: Allocator,
    hash_map: *const std.AutoHashMap(K, V),
    pick: []const K,
) Allocator.Error!std.AutoHashMap(K, V) {
    var result = std.AutoHashMap(K, V).init(allocator);
    errdefer result.deinit();
    for (pick) |k| {
        if (hash_map.get(k)) |v| {
            try result.put(k, v);
        }
    }
    return result;
}

/// Remove entries with the specified keys.
/// Caller owns the returned map.
///
/// ```zig
/// var result = try lo.omitKeys(u32, u8, allocator, &m, &.{ 2, 3 });
/// defer result.deinit();
/// ```
pub fn omitKeys(
    comptime K: type,
    comptime V: type,
    allocator: Allocator,
    hash_map: *const std.AutoHashMap(K, V),
    omit: []const K,
) Allocator.Error!std.AutoHashMap(K, V) {
    var omit_set = std.AutoHashMap(K, void).init(allocator);
    defer omit_set.deinit();
    for (omit) |k| try omit_set.put(k, {});

    var result = std.AutoHashMap(K, V).init(allocator);
    errdefer result.deinit();
    var it = hash_map.iterator();
    while (it.next()) |entry| {
        if (!omit_set.contains(entry.key_ptr.*)) {
            try result.put(entry.key_ptr.*, entry.value_ptr.*);
        }
    }
    return result;
}

/// Swap keys and values. Caller owns the returned map.
/// Duplicate values in the source become a single key in the result.
///
/// ```zig
/// var result = try lo.invert(u32, u8, allocator, &m);
/// defer result.deinit();
/// ```
pub fn invert(
    comptime K: type,
    comptime V: type,
    allocator: Allocator,
    hash_map: *const std.AutoHashMap(K, V),
) Allocator.Error!std.AutoHashMap(V, K) {
    var result = std.AutoHashMap(V, K).init(allocator);
    errdefer result.deinit();
    var it = hash_map.iterator();
    while (it.next()) |entry| {
        try result.put(entry.value_ptr.*, entry.key_ptr.*);
    }
    return result;
}

/// Merge entries from source into dest. Source values overwrite on conflict.
///
/// ```zig
/// try lo.merge(u32, u8, &dest, &source);
/// ```
pub fn merge(
    comptime K: type,
    comptime V: type,
    dest: *std.AutoHashMap(K, V),
    source: *const std.AutoHashMap(K, V),
) Allocator.Error!void {
    var it = source.iterator();
    while (it.next()) |entry| {
        try dest.put(entry.key_ptr.*, entry.value_ptr.*);
    }
}

/// Get a value from the map, or return a default if the key is absent.
///
/// ```zig
/// lo.valueOr(u32, u8, &my_map, 999, 0); // 0 if 999 not in map
/// ```
pub fn valueOr(
    comptime K: type,
    comptime V: type,
    hash_map: *const std.AutoHashMap(K, V),
    key: K,
    default: V,
) V {
    return hash_map.get(key) orelse default;
}

/// True if the map contains the given key.
///
/// ```zig
/// lo.hasKey(u32, u8, &m, 1); // true
/// ```
pub fn hasKey(
    comptime K: type,
    comptime V: type,
    hash_map: *const std.AutoHashMap(K, V),
    key: K,
) bool {
    return hash_map.contains(key);
}

/// Number of entries in the map.
///
/// ```zig
/// lo.mapCount(u32, u8, &m); // 3
/// ```
pub fn mapCount(
    comptime K: type,
    comptime V: type,
    hash_map: *const std.AutoHashMap(K, V),
) usize {
    return hash_map.count();
}

/// Transform both keys and values of a map using a function.
/// Caller owns the returned map.
///
/// ```zig
/// var result = try lo.mapEntries(u32, u8, u64, u16, allocator, &m, xform);
/// defer result.deinit();
/// ```
pub fn mapEntries(
    comptime K: type,
    comptime V: type,
    comptime K2: type,
    comptime V2: type,
    allocator: Allocator,
    hash_map: *const std.AutoHashMap(K, V),
    transform: *const fn (K, V) Entry(K2, V2),
) Allocator.Error!std.AutoHashMap(K2, V2) {
    var result = std.AutoHashMap(K2, V2).init(allocator);
    errdefer result.deinit();
    var it = hash_map.iterator();
    while (it.next()) |entry| {
        const e = transform(entry.key_ptr.*, entry.value_ptr.*);
        try result.put(e.key, e.value);
    }
    return result;
}

/// Transform map entries into an allocated slice.
/// Caller owns the returned slice.
///
/// ```zig
/// const result = try lo.mapToSlice(u32, u8, u64, allocator, &m, sumKeyVal);
/// defer allocator.free(result);
/// ```
pub fn mapToSlice(
    comptime K: type,
    comptime V: type,
    comptime R: type,
    allocator: Allocator,
    hash_map: *const std.AutoHashMap(K, V),
    transform: *const fn (K, V) R,
) Allocator.Error![]R {
    var list = std.ArrayList(R){};
    errdefer list.deinit(allocator);
    var it = hash_map.iterator();
    while (it.next()) |entry| {
        try list.append(allocator, transform(entry.key_ptr.*, entry.value_ptr.*));
    }
    return list.toOwnedSlice(allocator);
}

/// Filter map entries by a predicate on the key.
/// Caller owns the returned map.
///
/// ```zig
/// var result = try lo.filterKeys(u32, u8, allocator, &m, isEven);
/// defer result.deinit();
/// ```
pub fn filterKeys(
    comptime K: type,
    comptime V: type,
    allocator: Allocator,
    hash_map: *const std.AutoHashMap(K, V),
    predicate: *const fn (K) bool,
) Allocator.Error!std.AutoHashMap(K, V) {
    var result = std.AutoHashMap(K, V).init(allocator);
    errdefer result.deinit();
    var it = hash_map.iterator();
    while (it.next()) |entry| {
        if (predicate(entry.key_ptr.*)) {
            try result.put(entry.key_ptr.*, entry.value_ptr.*);
        }
    }
    return result;
}

/// Filter map entries by a predicate on the value.
/// Caller owns the returned map.
///
/// ```zig
/// var result = try lo.filterValues(u32, u8, allocator, &m, isPositive);
/// defer result.deinit();
/// ```
pub fn filterValues(
    comptime K: type,
    comptime V: type,
    allocator: Allocator,
    hash_map: *const std.AutoHashMap(K, V),
    predicate: *const fn (V) bool,
) Allocator.Error!std.AutoHashMap(K, V) {
    var result = std.AutoHashMap(K, V).init(allocator);
    errdefer result.deinit();
    var it = hash_map.iterator();
    while (it.next()) |entry| {
        if (predicate(entry.value_ptr.*)) {
            try result.put(entry.key_ptr.*, entry.value_ptr.*);
        }
    }
    return result;
}

/// Merge N maps into one with last-write-wins semantics.
/// Caller owns the returned map.
///
/// ```zig
/// var result = try lo.assign(u32, u8, allocator, &.{ &m1, &m2 });
/// defer result.deinit();
/// ```
pub fn assign(
    comptime K: type,
    comptime V: type,
    allocator: Allocator,
    maps: []const *const std.AutoHashMap(K, V),
) Allocator.Error!std.AutoHashMap(K, V) {
    var result = std.AutoHashMap(K, V).init(allocator);
    errdefer result.deinit();
    for (maps) |m| {
        var it = m.iterator();
        while (it.next()) |entry| {
            try result.put(entry.key_ptr.*, entry.value_ptr.*);
        }
    }
    return result;
}

// Tests.

fn makeTestMap(allocator: Allocator) !std.AutoHashMap(u32, u8) {
    var m = std.AutoHashMap(u32, u8).init(allocator);
    try m.put(1, 'a');
    try m.put(2, 'b');
    try m.put(3, 'c');
    return m;
}

test "keys: iterates all keys" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    var it = keys(u32, u8, &m);
    var sum: u32 = 0;
    while (it.next()) |k| sum += k;
    try std.testing.expectEqual(@as(u32, 6), sum);
}

test "keys: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    var it = keys(u32, u8, &m);
    try std.testing.expectEqual(@as(?u32, null), it.next());
}

test "keysAlloc: collects keys" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    const ks = try keysAlloc(u32, u8, std.testing.allocator, &m);
    defer std.testing.allocator.free(ks);
    try std.testing.expectEqual(@as(usize, 3), ks.len);
    var sum: u32 = 0;
    for (ks) |k| sum += k;
    try std.testing.expectEqual(@as(u32, 6), sum);
}

test "keysAlloc: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    const ks = try keysAlloc(u32, u8, std.testing.allocator, &m);
    defer std.testing.allocator.free(ks);
    try std.testing.expectEqual(@as(usize, 0), ks.len);
}

test "values: iterates all values" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    var it = values(u32, u8, &m);
    var sum: u32 = 0;
    while (it.next()) |v| sum += v;
    try std.testing.expectEqual(@as(u32, 'a' + 'b' + 'c'), sum);
}

test "values: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    var it = values(u32, u8, &m);
    try std.testing.expectEqual(@as(?u8, null), it.next());
}

test "valuesAlloc: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    const vs = try valuesAlloc(u32, u8, std.testing.allocator, &m);
    defer std.testing.allocator.free(vs);
    try std.testing.expectEqual(@as(usize, 0), vs.len);
}

test "valuesAlloc: collects values" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    const vs = try valuesAlloc(u32, u8, std.testing.allocator, &m);
    defer std.testing.allocator.free(vs);
    try std.testing.expectEqual(@as(usize, 3), vs.len);
}

test "entries: iterates all pairs" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    var it = entries(u32, u8, &m);
    var n: usize = 0;
    while (it.next()) |_| n += 1;
    try std.testing.expectEqual(@as(usize, 3), n);
}

test "entries: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    var it = entries(u32, u8, &m);
    try std.testing.expectEqual(@as(?Entry(u32, u8), null), it.next());
}

test "entriesAlloc: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    const es = try entriesAlloc(u32, u8, std.testing.allocator, &m);
    defer std.testing.allocator.free(es);
    try std.testing.expectEqual(@as(usize, 0), es.len);
}

test "entriesAlloc: collects pairs" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    const es = try entriesAlloc(u32, u8, std.testing.allocator, &m);
    defer std.testing.allocator.free(es);
    try std.testing.expectEqual(@as(usize, 3), es.len);
}

test "fromEntries: builds map" {
    const pairs = [_]Entry(u32, u8){
        .{ .key = 1, .value = 'x' },
        .{ .key = 2, .value = 'y' },
    };
    var m = try fromEntries(u32, u8, std.testing.allocator, &pairs);
    defer m.deinit();
    try std.testing.expectEqual(@as(u8, 'x'), m.get(1).?);
    try std.testing.expectEqual(@as(u8, 'y'), m.get(2).?);
}

test "fromEntries: empty pairs" {
    const pairs = [_]Entry(u32, u8){};
    var m = try fromEntries(u32, u8, std.testing.allocator, &pairs);
    defer m.deinit();
    try std.testing.expectEqual(@as(usize, 0), m.count());
}

test "fromEntries: duplicate keys keep last" {
    const pairs = [_]Entry(u32, u8){
        .{ .key = 1, .value = 'a' },
        .{ .key = 1, .value = 'b' },
    };
    var m = try fromEntries(u32, u8, std.testing.allocator, &pairs);
    defer m.deinit();
    try std.testing.expectEqual(@as(u8, 'b'), m.get(1).?);
}

test "mapKeys: transforms keys" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try m.put(1, 'a');
    try m.put(2, 'b');

    const timesTwo = struct {
        fn f(k: u32) u64 {
            return @as(u64, k) * 2;
        }
    }.f;

    var result = try mapKeys(u32, u8, u64, std.testing.allocator, &m, timesTwo);
    defer result.deinit();
    try std.testing.expectEqual(@as(u8, 'a'), result.get(2).?);
    try std.testing.expectEqual(@as(u8, 'b'), result.get(4).?);
}

test "mapKeys: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    const id = struct {
        fn f(k: u32) u32 {
            return k;
        }
    }.f;
    var result = try mapKeys(u32, u8, u32, std.testing.allocator, &m, id);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 0), result.count());
}

test "mapKeys: single entry" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try m.put(5, 'z');
    const addTen = struct {
        fn f(k: u32) u32 {
            return k + 10;
        }
    }.f;
    var result = try mapKeys(u32, u8, u32, std.testing.allocator, &m, addTen);
    defer result.deinit();
    try std.testing.expectEqual(@as(u8, 'z'), result.get(15).?);
}

test "mapValues: transforms values" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try m.put(1, 10);
    try m.put(2, 20);

    const toU16 = struct {
        fn f(v: u8) u16 {
            return @as(u16, v) * 100;
        }
    }.f;

    var result = try mapValues(u32, u8, u16, std.testing.allocator, &m, toU16);
    defer result.deinit();
    try std.testing.expectEqual(@as(u16, 1000), result.get(1).?);
    try std.testing.expectEqual(@as(u16, 2000), result.get(2).?);
}

test "mapValues: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    const id = struct {
        fn f(v: u8) u8 {
            return v;
        }
    }.f;
    var result = try mapValues(u32, u8, u8, std.testing.allocator, &m, id);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 0), result.count());
}

test "mapValues: single entry" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try m.put(1, 5);
    const doubled = struct {
        fn f(v: u8) u16 {
            return @as(u16, v) * 2;
        }
    }.f;
    var result = try mapValues(u32, u8, u16, std.testing.allocator, &m, doubled);
    defer result.deinit();
    try std.testing.expectEqual(@as(u16, 10), result.get(1).?);
}

test "filterMap: keeps matching entries" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();

    const keyGt1 = struct {
        fn f(k: u32, _: u8) bool {
            return k > 1;
        }
    }.f;

    var result = try filterMap(u32, u8, std.testing.allocator, &m, keyGt1);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 2), result.count());
    try std.testing.expectEqual(@as(?u8, null), result.get(1));
}

test "filterMap: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    const always = struct {
        fn f(_: u32, _: u8) bool {
            return true;
        }
    }.f;
    var result = try filterMap(u32, u8, std.testing.allocator, &m, always);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 0), result.count());
}

test "filterMap: single entry match" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try m.put(5, 'x');
    const always = struct {
        fn f(_: u32, _: u8) bool {
            return true;
        }
    }.f;
    var result = try filterMap(u32, u8, std.testing.allocator, &m, always);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 1), result.count());
    try std.testing.expectEqual(@as(u8, 'x'), result.get(5).?);
}

test "filterMap: no matches" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    const never = struct {
        fn f(_: u32, _: u8) bool {
            return false;
        }
    }.f;
    var result = try filterMap(u32, u8, std.testing.allocator, &m, never);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 0), result.count());
}

test "pickKeys: keeps specified keys" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    var result = try pickKeys(u32, u8, std.testing.allocator, &m, &.{ 1, 3 });
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 2), result.count());
    try std.testing.expectEqual(@as(u8, 'a'), result.get(1).?);
    try std.testing.expectEqual(@as(u8, 'c'), result.get(3).?);
}

test "pickKeys: single key" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    var result = try pickKeys(u32, u8, std.testing.allocator, &m, &.{2});
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 1), result.count());
    try std.testing.expectEqual(@as(u8, 'b'), result.get(2).?);
}

test "pickKeys: keys not in map" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    var result = try pickKeys(u32, u8, std.testing.allocator, &m, &.{ 99, 100 });
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 0), result.count());
}

test "pickKeys: empty pick list" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    var result = try pickKeys(u32, u8, std.testing.allocator, &m, &.{});
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 0), result.count());
}

test "omitKeys: removes specified keys" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    var result = try omitKeys(u32, u8, std.testing.allocator, &m, &.{ 1, 3 });
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 1), result.count());
    try std.testing.expectEqual(@as(u8, 'b'), result.get(2).?);
}

test "omitKeys: omit nonexistent keys" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    var result = try omitKeys(u32, u8, std.testing.allocator, &m, &.{99});
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 3), result.count());
}

test "omitKeys: omit all keys" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    var result = try omitKeys(u32, u8, std.testing.allocator, &m, &.{ 1, 2, 3 });
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 0), result.count());
}

test "invert: swaps keys and values" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    var result = try invert(u32, u8, std.testing.allocator, &m);
    defer result.deinit();
    try std.testing.expectEqual(@as(u32, 1), result.get('a').?);
    try std.testing.expectEqual(@as(u32, 2), result.get('b').?);
    try std.testing.expectEqual(@as(u32, 3), result.get('c').?);
}

test "invert: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    var result = try invert(u32, u8, std.testing.allocator, &m);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 0), result.count());
}

test "invert: duplicate values" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try m.put(1, 'a');
    try m.put(2, 'a');
    try m.put(3, 'b');
    var result = try invert(u32, u8, std.testing.allocator, &m);
    defer result.deinit();
    // Two keys mapped to 'a', last-write-wins: result has one entry for 'a'
    try std.testing.expectEqual(@as(usize, 2), result.count());
    try std.testing.expect(result.get('a') != null); // one of 1 or 2
    try std.testing.expectEqual(@as(u32, 3), result.get('b').?);
}

test "invert: single entry" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try m.put(42, 'z');
    var result = try invert(u32, u8, std.testing.allocator, &m);
    defer result.deinit();
    try std.testing.expectEqual(@as(u32, 42), result.get('z').?);
}

test "merge: adds entries from source" {
    var dest = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer dest.deinit();
    try dest.put(1, 'a');

    var source = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer source.deinit();
    try source.put(2, 'b');
    try source.put(3, 'c');

    try merge(u32, u8, &dest, &source);
    try std.testing.expectEqual(@as(usize, 3), dest.count());
    try std.testing.expectEqual(@as(u8, 'b'), dest.get(2).?);
}

test "merge: into empty dest" {
    var dest = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer dest.deinit();

    var source = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer source.deinit();
    try source.put(1, 'a');
    try source.put(2, 'b');

    try merge(u32, u8, &dest, &source);
    try std.testing.expectEqual(@as(usize, 2), dest.count());
    try std.testing.expectEqual(@as(u8, 'a'), dest.get(1).?);
    try std.testing.expectEqual(@as(u8, 'b'), dest.get(2).?);
}

test "merge: overwrites on conflict" {
    var dest = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer dest.deinit();
    try dest.put(1, 'a');

    var source = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer source.deinit();
    try source.put(1, 'z');

    try merge(u32, u8, &dest, &source);
    try std.testing.expectEqual(@as(u8, 'z'), dest.get(1).?);
}

test "merge: empty source" {
    var dest = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer dest.deinit();
    try dest.put(1, 'a');

    var source = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer source.deinit();

    try merge(u32, u8, &dest, &source);
    try std.testing.expectEqual(@as(usize, 1), dest.count());
}

test "valueOr: returns value when key exists" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    try std.testing.expectEqual(@as(u8, 'a'), valueOr(u32, u8, &m, 1, 'z'));
}

test "valueOr: returns default when key absent" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    try std.testing.expectEqual(@as(u8, 'z'), valueOr(u32, u8, &m, 99, 'z'));
}

test "valueOr: empty map returns default" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try std.testing.expectEqual(@as(u8, 'x'), valueOr(u32, u8, &m, 1, 'x'));
}

test "hasKey: key exists" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    try std.testing.expect(hasKey(u32, u8, &m, 1));
}

test "hasKey: key absent" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    try std.testing.expect(!hasKey(u32, u8, &m, 99));
}

test "hasKey: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try std.testing.expect(!hasKey(u32, u8, &m, 1));
}

test "mapCount: returns entry count" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    try std.testing.expectEqual(@as(usize, 3), mapCount(u32, u8, &m));
}

test "mapCount: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try std.testing.expectEqual(@as(usize, 0), mapCount(u32, u8, &m));
}

test "mapCount: single entry" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try m.put(1, 'a');
    try std.testing.expectEqual(@as(usize, 1), mapCount(u32, u8, &m));
}

// ── mapEntries tests ──────────────────────────────────────────────────

test "mapEntries: transforms both keys and values" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try m.put(1, 'a');
    try m.put(2, 'b');

    const xform = struct {
        fn f(k: u32, v: u8) Entry(u64, u16) {
            return .{ .key = @as(u64, k) * 10, .value = @as(u16, v) + 1 };
        }
    }.f;

    var result = try mapEntries(u32, u8, u64, u16, std.testing.allocator, &m, xform);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 2), result.count());
    try std.testing.expectEqual(@as(u16, 'a' + 1), result.get(10).?);
    try std.testing.expectEqual(@as(u16, 'b' + 1), result.get(20).?);
}

test "mapEntries: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    const xform = struct {
        fn f(k: u32, v: u8) Entry(u32, u8) {
            return .{ .key = k, .value = v };
        }
    }.f;
    var result = try mapEntries(u32, u8, u32, u8, std.testing.allocator, &m, xform);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 0), result.count());
}

test "mapEntries: single entry" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try m.put(5, 'z');
    const xform = struct {
        fn f(k: u32, v: u8) Entry(u64, u16) {
            return .{ .key = @as(u64, k) + 100, .value = @as(u16, v) * 2 };
        }
    }.f;
    var result = try mapEntries(u32, u8, u64, u16, std.testing.allocator, &m, xform);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 1), result.count());
    try std.testing.expectEqual(@as(u16, 'z' * 2), result.get(105).?);
}

// ── mapToSlice tests ──────────────────────────────────────────────────

test "mapToSlice: transforms entries to slice" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try m.put(1, 10);
    try m.put(2, 20);

    const xform = struct {
        fn f(k: u32, v: u8) u64 {
            return @as(u64, k) + @as(u64, v);
        }
    }.f;

    const result = try mapToSlice(u32, u8, u64, std.testing.allocator, &m, xform);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 2), result.len);
    // Order-independent: check sum
    var total: u64 = 0;
    for (result) |r| total += r;
    try std.testing.expectEqual(@as(u64, (1 + 10) + (2 + 20)), total);
}

test "mapToSlice: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    const xform = struct {
        fn f(k: u32, v: u8) u64 {
            return @as(u64, k) + @as(u64, v);
        }
    }.f;
    const result = try mapToSlice(u32, u8, u64, std.testing.allocator, &m, xform);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "mapToSlice: single entry" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    try m.put(42, 8);
    const xform = struct {
        fn f(k: u32, v: u8) u64 {
            return @as(u64, k) * @as(u64, v);
        }
    }.f;
    const result = try mapToSlice(u32, u8, u64, std.testing.allocator, &m, xform);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqual(@as(usize, 1), result.len);
    try std.testing.expectEqual(@as(u64, 42 * 8), result[0]);
}

// ── filterKeys tests ──────────────────────────────────────────────────

test "filterKeys: keeps entries where key predicate is true" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    const gt1 = struct {
        fn f(k: u32) bool {
            return k > 1;
        }
    }.f;
    var result = try filterKeys(u32, u8, std.testing.allocator, &m, gt1);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 2), result.count());
    try std.testing.expectEqual(@as(?u8, null), result.get(1));
    try std.testing.expect(result.get(2) != null);
    try std.testing.expect(result.get(3) != null);
}

test "filterKeys: keep all" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    const always = struct {
        fn f(_: u32) bool {
            return true;
        }
    }.f;
    var result = try filterKeys(u32, u8, std.testing.allocator, &m, always);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 3), result.count());
}

test "filterKeys: keep none" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    const never = struct {
        fn f(_: u32) bool {
            return false;
        }
    }.f;
    var result = try filterKeys(u32, u8, std.testing.allocator, &m, never);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 0), result.count());
}

test "filterKeys: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    const always = struct {
        fn f(_: u32) bool {
            return true;
        }
    }.f;
    var result = try filterKeys(u32, u8, std.testing.allocator, &m, always);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 0), result.count());
}

// ── filterValues tests ──────────────────────────────────────────────────

test "filterValues: keeps entries where value predicate is true" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    const gtA = struct {
        fn f(v: u8) bool {
            return v > 'a';
        }
    }.f;
    var result = try filterValues(u32, u8, std.testing.allocator, &m, gtA);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 2), result.count());
    try std.testing.expectEqual(@as(?u8, null), result.get(1)); // key 1 has 'a', filtered out
    try std.testing.expect(result.get(2) != null);
    try std.testing.expect(result.get(3) != null);
}

test "filterValues: keep all" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    const always = struct {
        fn f(_: u8) bool {
            return true;
        }
    }.f;
    var result = try filterValues(u32, u8, std.testing.allocator, &m, always);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 3), result.count());
}

test "filterValues: keep none" {
    var m = try makeTestMap(std.testing.allocator);
    defer m.deinit();
    const never = struct {
        fn f(_: u8) bool {
            return false;
        }
    }.f;
    var result = try filterValues(u32, u8, std.testing.allocator, &m, never);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 0), result.count());
}

test "filterValues: empty map" {
    var m = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m.deinit();
    const always = struct {
        fn f(_: u8) bool {
            return true;
        }
    }.f;
    var result = try filterValues(u32, u8, std.testing.allocator, &m, always);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 0), result.count());
}

// ── assign tests ──────────────────────────────────────────────────

test "assign: merges disjoint maps" {
    var m1 = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m1.deinit();
    try m1.put(1, 'a');

    var m2 = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m2.deinit();
    try m2.put(2, 'b');

    var result = try assign(u32, u8, std.testing.allocator, &.{ &m1, &m2 });
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 2), result.count());
    try std.testing.expectEqual(@as(u8, 'a'), result.get(1).?);
    try std.testing.expectEqual(@as(u8, 'b'), result.get(2).?);
}

test "assign: last-write-wins on overlap" {
    var m1 = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m1.deinit();
    try m1.put(1, 'a');

    var m2 = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m2.deinit();
    try m2.put(1, 'z');

    var result = try assign(u32, u8, std.testing.allocator, &.{ &m1, &m2 });
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 1), result.count());
    try std.testing.expectEqual(@as(u8, 'z'), result.get(1).?);
}

test "assign: empty maps slice" {
    const empty_slice: []const *const std.AutoHashMap(u32, u8) = &.{};
    var result = try assign(u32, u8, std.testing.allocator, empty_slice);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 0), result.count());
}

test "assign: single map" {
    var m1 = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m1.deinit();
    try m1.put(1, 'a');
    try m1.put(2, 'b');

    var result = try assign(u32, u8, std.testing.allocator, &.{&m1});
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 2), result.count());
    try std.testing.expectEqual(@as(u8, 'a'), result.get(1).?);
    try std.testing.expectEqual(@as(u8, 'b'), result.get(2).?);
}

test "assign: mix of empty and non-empty" {
    var m1 = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m1.deinit();

    var m2 = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m2.deinit();
    try m2.put(1, 'x');

    var m3 = std.AutoHashMap(u32, u8).init(std.testing.allocator);
    defer m3.deinit();

    var result = try assign(u32, u8, std.testing.allocator, &.{ &m1, &m2, &m3 });
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 1), result.count());
    try std.testing.expectEqual(@as(u8, 'x'), result.get(1).?);
}
