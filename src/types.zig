const std = @import("std");

/// Returns true if the optional value is null.
///
/// ```zig
/// const x: ?i32 = null;
/// lo.isNull(i32, x); // true
/// ```
pub fn isNull(comptime T: type, value: ?T) bool {
    return value == null;
}

/// Returns true if the optional value is non-null.
///
/// ```zig
/// const x: ?i32 = 42;
/// lo.isNotNull(i32, x); // true
/// ```
pub fn isNotNull(comptime T: type, value: ?T) bool {
    return value != null;
}

/// Unwrap an optional, returning the fallback if null.
///
/// ```zig
/// const x: ?i32 = null;
/// lo.unwrapOr(i32, x, 99); // 99
/// ```
pub fn unwrapOr(comptime T: type, value: ?T, fallback: T) T {
    return value orelse fallback;
}

/// Returns the first non-null value from a slice of optionals,
/// or null if all values are null.
///
/// ```zig
/// const vals = [_]?i32{ null, null, 42, 7 };
/// lo.coalesce(i32, &vals); // 42
/// ```
pub fn coalesce(comptime T: type, values: []const ?T) ?T {
    for (values) |v| {
        if (v) |unwrapped| return unwrapped;
    }
    return null;
}

/// Returns the zero/default value for a type.
///
/// For integers: 0. For floats: 0.0. For bools: false.
/// For optionals: null. For structs: default field values or zeroed.
///
/// ```zig
/// lo.empty(i32); // 0
/// lo.empty(bool); // false
/// ```
pub fn empty(comptime T: type) T {
    const info = @typeInfo(T);
    return switch (info) {
        .int, .comptime_int => 0,
        .float, .comptime_float => 0.0,
        .bool => false,
        .optional => null,
        .null => null,
        .@"enum" => @enumFromInt(0),
        .@"struct" => std.mem.zeroes(T),
        .array => std.mem.zeroes(T),
        .vector => std.mem.zeroes(T),
        .pointer => |p| switch (p.size) {
            .slice => &[_]p.child{},
            else => @compileError(
                "empty: pointer type " ++
                    @typeName(T) ++
                    " has no meaningful zero value",
            ),
        },
        else => @compileError(
            "empty: unsupported type " ++ @typeName(T),
        ),
    };
}

/// Returns true if the value equals the zero/default for its type.
///
/// ```zig
/// lo.isEmpty(i32, 0);   // true
/// lo.isEmpty(i32, 42);  // false
/// ```
pub fn isEmpty(comptime T: type, value: T) bool {
    return std.meta.eql(value, empty(T));
}

/// Returns true if the value does **not** equal the zero/default for its type.
///
/// This is the logical negation of `isEmpty`.
///
/// ```zig
/// lo.isNotEmpty(i32, 42);  // true
/// lo.isNotEmpty(i32, 0);   // false
/// ```
pub fn isNotEmpty(comptime T: type, value: T) bool {
    return !isEmpty(T, value);
}

/// Selects one of two values based on a boolean condition.
///
/// Returns `if_output` when `condition` is true, `else_output` otherwise.
/// Both branches are evaluated eagerly (not short-circuited).
/// Works at comptime.
///
/// ```zig
/// lo.ternary(i32, true, 10, 20);  // 10
/// lo.ternary(i32, false, 10, 20); // 20
/// ```
pub fn ternary(comptime T: type, condition: bool, if_output: T, else_output: T) T {
    if (condition) return if_output;
    return else_output;
}

/// Convert a mutable slice to a const slice.
///
/// ```zig
/// var buf = [_]i32{ 1, 2, 3 };
/// const view = lo.toConst(i32, &buf);
/// ```
pub fn toConst(comptime T: type, slice: []T) []const T {
    return slice;
}

// Tests

test "isNull: null returns true" {
    const x: ?i32 = null;
    try std.testing.expect(isNull(i32, x));
}

test "isNull: non-null returns false" {
    const x: ?i32 = 42;
    try std.testing.expect(!isNull(i32, x));
}

test "isNull: zero is not null" {
    const x: ?i32 = 0;
    try std.testing.expect(!isNull(i32, x));
}

test "isNotNull: non-null returns true" {
    const x: ?i32 = 42;
    try std.testing.expect(isNotNull(i32, x));
}

test "isNotNull: null returns false" {
    const x: ?i32 = null;
    try std.testing.expect(!isNotNull(i32, x));
}

test "isNotNull: zero is non-null" {
    const x: ?i32 = 0;
    try std.testing.expect(isNotNull(i32, x));
}

test "unwrapOr: returns value when non-null" {
    const x: ?i32 = 42;
    try std.testing.expectEqual(42, unwrapOr(i32, x, 99));
}

test "unwrapOr: returns fallback when null" {
    const x: ?i32 = null;
    try std.testing.expectEqual(99, unwrapOr(i32, x, 99));
}

test "unwrapOr: works with floats" {
    const x: ?f64 = null;
    try std.testing.expectEqual(3.14, unwrapOr(f64, x, 3.14));
}

test "coalesce: returns first non-null" {
    const vals = [_]?i32{ null, null, 42, 7 };
    try std.testing.expectEqual(42, coalesce(i32, &vals));
}

test "coalesce: all null returns null" {
    const vals = [_]?i32{ null, null, null };
    try std.testing.expectEqual(null, coalesce(i32, &vals));
}

test "coalesce: first element non-null" {
    const vals = [_]?i32{ 10, null, 42 };
    try std.testing.expectEqual(10, coalesce(i32, &vals));
}

test "coalesce: empty slice returns null" {
    const vals = [_]?i32{};
    try std.testing.expectEqual(null, coalesce(i32, &vals));
}

test "empty: integer zero" {
    try std.testing.expectEqual(@as(i32, 0), empty(i32));
    try std.testing.expectEqual(@as(u64, 0), empty(u64));
}

test "empty: float zero" {
    try std.testing.expectEqual(@as(f32, 0.0), empty(f32));
    try std.testing.expectEqual(@as(f64, 0.0), empty(f64));
}

test "empty: bool false" {
    try std.testing.expectEqual(false, empty(bool));
}

test "empty: optional null" {
    try std.testing.expectEqual(@as(?i32, null), empty(?i32));
}

test "isEmpty: zero integer is empty" {
    try std.testing.expect(isEmpty(i32, 0));
}

test "isEmpty: non-zero integer is not empty" {
    try std.testing.expect(!isEmpty(i32, 42));
}

test "isEmpty: false bool is empty" {
    try std.testing.expect(isEmpty(bool, false));
}

test "isEmpty: true bool is not empty" {
    try std.testing.expect(!isEmpty(bool, true));
}

test "isEmpty: null optional is empty" {
    try std.testing.expect(isEmpty(?i32, null));
}

test "isEmpty: non-null optional is not empty" {
    try std.testing.expect(!isEmpty(?i32, 42));
}

test "toConst: converts mutable to const" {
    var buf = [_]i32{ 1, 2, 3 };
    const view = toConst(i32, &buf);
    try std.testing.expectEqual(@as(usize, 3), view.len);
    try std.testing.expectEqual(@as(i32, 1), view[0]);
}

test "toConst: empty slice" {
    var buf = [_]i32{};
    const view = toConst(i32, &buf);
    try std.testing.expectEqual(@as(usize, 0), view.len);
}

test "toConst: preserves element values" {
    var buf = [_]u8{ 'a', 'b', 'c' };
    const view = toConst(u8, &buf);
    try std.testing.expectEqualSlices(u8, "abc", view);
}

// isNotEmpty tests

test "isNotEmpty: zero integer is empty" {
    try std.testing.expect(!isNotEmpty(i32, 0));
}

test "isNotEmpty: non-zero integer is not empty" {
    try std.testing.expect(isNotEmpty(i32, 42));
}

test "isNotEmpty: false bool is empty" {
    try std.testing.expect(!isNotEmpty(bool, false));
}

test "isNotEmpty: true bool is not empty" {
    try std.testing.expect(isNotEmpty(bool, true));
}

test "isNotEmpty: null optional is empty" {
    try std.testing.expect(!isNotEmpty(?i32, null));
}

test "isNotEmpty: non-null optional is not empty" {
    try std.testing.expect(isNotEmpty(?i32, 42));
}

test "isNotEmpty: zero float is empty" {
    try std.testing.expect(!isNotEmpty(f64, 0.0));
}

test "isNotEmpty: non-zero float is not empty" {
    try std.testing.expect(isNotEmpty(f64, 3.14));
}

// ternary tests

test "ternary: true returns if_output" {
    try std.testing.expectEqual(@as(i32, 10), ternary(i32, true, 10, 20));
}

test "ternary: false returns else_output" {
    try std.testing.expectEqual(@as(i32, 20), ternary(i32, false, 10, 20));
}

test "ternary: works with slices" {
    const result = ternary([]const u8, true, "yes", "no");
    try std.testing.expectEqualStrings("yes", result);
}

test "ternary: works with bools" {
    try std.testing.expectEqual(true, ternary(bool, true, true, false));
}

test "ternary: works at comptime" {
    comptime {
        const result = ternary(i32, true, 1, 2);
        if (result != 1) @compileError("ternary comptime failed");
    }
}
