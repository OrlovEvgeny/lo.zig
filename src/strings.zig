const std = @import("std");
const Allocator = std.mem.Allocator;

/// Iterator that splits a string into words at camelCase, PascalCase,
/// snake_case, kebab-case, and whitespace boundaries.
pub const WordIterator = struct {
    input: []const u8,
    index: usize = 0,

    pub fn next(self: *WordIterator) ?[]const u8 {
        // Skip separators.
        while (self.index < self.input.len and isSeparator(self.input[self.index])) {
            self.index += 1;
        }
        if (self.index >= self.input.len) return null;

        const start = self.index;

        if (isUpper(self.input[self.index])) {
            self.index += 1;
            // Uppercase run: "XMLParser" -> "XML", "Parser"
            if (self.index < self.input.len and isUpper(self.input[self.index])) {
                while (self.index < self.input.len and isUpper(self.input[self.index])) {
                    if (self.index + 1 < self.input.len and isLower(self.input[self.index + 1])) {
                        break;
                    }
                    self.index += 1;
                }
            } else {
                while (self.index < self.input.len and
                    isLower(self.input[self.index]))
                {
                    self.index += 1;
                }
            }
        } else {
            while (self.index < self.input.len and
                !isSeparator(self.input[self.index]) and
                !isUpper(self.input[self.index]))
            {
                self.index += 1;
            }
        }
        if (self.index == start) return null;
        return self.input[start..self.index];
    }

    pub fn reset(self: *WordIterator) void {
        self.index = 0;
    }
};

fn isSeparator(c: u8) bool {
    return c == '_' or c == '-' or c == ' ' or c == '\t' or c == '\n';
}

fn isUpper(c: u8) bool {
    return c >= 'A' and c <= 'Z';
}

fn isLower(c: u8) bool {
    return c >= 'a' and c <= 'z';
}

fn toLower(c: u8) u8 {
    if (isUpper(c)) return c + 32;
    return c;
}

fn toUpper(c: u8) u8 {
    if (isLower(c)) return c - 32;
    return c;
}

/// Split a string into words. Returns a lazy iterator.
///
/// ```zig
/// var it = lo.words("helloWorld");
/// it.next(); // "hello"
/// it.next(); // "World"
/// ```
pub fn words(input: []const u8) WordIterator {
    return .{ .input = input };
}

/// Split a string into words, collected into an allocated slice.
pub fn wordsAlloc(
    allocator: Allocator,
    input: []const u8,
) Allocator.Error![][]const u8 {
    var it = words(input);
    var list = std.ArrayList([]const u8){};
    errdefer list.deinit(allocator);
    while (it.next()) |word| {
        try list.append(allocator, word);
    }
    return list.toOwnedSlice(allocator);
}

/// Convert to camelCase.
///
/// ```zig
/// const s = try lo.camelCase(alloc, "hello_world");
/// // s == "helloWorld"
/// ```
pub fn camelCase(
    allocator: Allocator,
    input: []const u8,
) Allocator.Error![]u8 {
    var it = words(input);
    var list = std.ArrayList(u8){};
    errdefer list.deinit(allocator);
    var first_word = true;
    while (it.next()) |word| {
        for (word, 0..) |c, i| {
            if (first_word) {
                try list.append(allocator, toLower(c));
            } else if (i == 0) {
                try list.append(allocator, toUpper(c));
            } else {
                try list.append(allocator, toLower(c));
            }
        }
        first_word = false;
    }
    return list.toOwnedSlice(allocator);
}

/// Convert to PascalCase.
///
/// ```zig
/// const s = try lo.pascalCase(alloc, "hello_world");
/// // s == "HelloWorld"
/// ```
pub fn pascalCase(
    allocator: Allocator,
    input: []const u8,
) Allocator.Error![]u8 {
    var it = words(input);
    var list = std.ArrayList(u8){};
    errdefer list.deinit(allocator);
    while (it.next()) |word| {
        for (word, 0..) |c, i| {
            if (i == 0) {
                try list.append(allocator, toUpper(c));
            } else {
                try list.append(allocator, toLower(c));
            }
        }
    }
    return list.toOwnedSlice(allocator);
}

/// Convert to snake_case.
///
/// ```zig
/// const s = try lo.snakeCase(alloc, "helloWorld");
/// // s == "hello_world"
/// ```
pub fn snakeCase(
    allocator: Allocator,
    input: []const u8,
) Allocator.Error![]u8 {
    return joinWords(allocator, input, '_');
}

/// Convert to kebab-case.
///
/// ```zig
/// const s = try lo.kebabCase(alloc, "helloWorld");
/// // s == "hello-world"
/// ```
pub fn kebabCase(
    allocator: Allocator,
    input: []const u8,
) Allocator.Error![]u8 {
    return joinWords(allocator, input, '-');
}

fn joinWords(
    allocator: Allocator,
    input: []const u8,
    sep: u8,
) Allocator.Error![]u8 {
    var it = words(input);
    var list = std.ArrayList(u8){};
    errdefer list.deinit(allocator);
    var first_word = true;
    while (it.next()) |word| {
        if (!first_word) try list.append(allocator, sep);
        for (word) |c| {
            try list.append(allocator, toLower(c));
        }
        first_word = false;
    }
    return list.toOwnedSlice(allocator);
}

/// Capitalize the first letter of a string.
///
/// ```zig
/// const s = try lo.capitalize(alloc, "hello");
/// // s == "Hello"
/// ```
pub fn capitalize(
    allocator: Allocator,
    input: []const u8,
) Allocator.Error![]u8 {
    if (input.len == 0) {
        return allocator.alloc(u8, 0);
    }
    const result = try allocator.alloc(u8, input.len);
    @memcpy(result, input);
    result[0] = toUpper(input[0]);
    return result;
}

/// Truncate a string and add "..." if it exceeds max_len.
///
/// ```zig
/// const s = try lo.ellipsis(alloc, "hello world", 8);
/// // s == "hello..."
/// ```
pub fn ellipsis(
    allocator: Allocator,
    input: []const u8,
    max_len: usize,
) Allocator.Error![]u8 {
    if (input.len <= max_len) {
        const result = try allocator.alloc(u8, input.len);
        @memcpy(result, input);
        return result;
    }
    if (max_len < 3) {
        const result = try allocator.alloc(u8, max_len);
        for (result) |*c| c.* = '.';
        return result;
    }
    const text_len = max_len - 3;
    const result = try allocator.alloc(u8, max_len);
    @memcpy(result[0..text_len], input[0..text_len]);
    result[text_len] = '.';
    result[text_len + 1] = '.';
    result[text_len + 2] = '.';
    return result;
}

/// Repeat a string n times.
///
/// ```zig
/// const s = try lo.repeat(alloc, "ab", 3);
/// // s == "ababab"
/// ```
pub fn strRepeat(
    allocator: Allocator,
    input: []const u8,
    n: usize,
) Allocator.Error![]u8 {
    if (n == 0 or input.len == 0) {
        return allocator.alloc(u8, 0);
    }
    const result = try allocator.alloc(u8, input.len * n);
    for (0..n) |i| {
        @memcpy(result[i * input.len .. (i + 1) * input.len], input);
    }
    return result;
}

/// Left-pad a string to the given length with the pad character.
///
/// ```zig
/// const s = try lo.padLeft(alloc, "42", 5, '0');
/// // s == "00042"
/// ```
pub fn padLeft(
    allocator: Allocator,
    input: []const u8,
    target_len: usize,
    pad_char: u8,
) Allocator.Error![]u8 {
    if (input.len >= target_len) {
        const result = try allocator.alloc(u8, input.len);
        @memcpy(result, input);
        return result;
    }
    const pad_count = target_len - input.len;
    const result = try allocator.alloc(u8, target_len);
    @memset(result[0..pad_count], pad_char);
    @memcpy(result[pad_count..], input);
    return result;
}

/// Right-pad a string to the given length with the pad character.
///
/// ```zig
/// const s = try lo.padRight(alloc, "hi", 5, '.');
/// // s == "hi..."
/// ```
pub fn padRight(
    allocator: Allocator,
    input: []const u8,
    target_len: usize,
    pad_char: u8,
) Allocator.Error![]u8 {
    if (input.len >= target_len) {
        const result = try allocator.alloc(u8, input.len);
        @memcpy(result, input);
        return result;
    }
    const result = try allocator.alloc(u8, target_len);
    @memcpy(result[0..input.len], input);
    @memset(result[input.len..], pad_char);
    return result;
}

/// Count the number of Unicode codepoints in a UTF-8 string.
/// Returns `error.InvalidUtf8` if the input contains invalid UTF-8 bytes.
///
/// ```zig
/// const len = try lo.runeLength("hello"); // 5
/// const len2 = try lo.runeLength("こんにちは"); // 5
/// ```
pub fn runeLength(input: []const u8) error{InvalidUtf8}!usize {
    const view = std.unicode.Utf8View.init(input) catch return error.InvalidUtf8;
    var iter = view.iterator();
    var len: usize = 0;
    while (iter.nextCodepoint() != null) : (len += 1) {}
    return len;
}

/// Generate a random alphanumeric string of the given length.
///
/// ```zig
/// const s = try lo.randomString(alloc, 10, prng.random());
/// defer alloc.free(s);
/// ```
pub fn randomString(
    allocator: Allocator,
    len: usize,
    random: std.Random,
) Allocator.Error![]u8 {
    const charset = "abcdefghijklmnopqrstuvwxyz" ++
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    const result = try allocator.alloc(u8, len);
    for (result) |*c| {
        c.* = charset[random.intRangeLessThan(usize, 0, charset.len)];
    }
    return result;
}

// Tests.

test "words: camelCase" {
    var it = words("helloWorld");
    try std.testing.expectEqualStrings("hello", it.next().?);
    try std.testing.expectEqualStrings("World", it.next().?);
    try std.testing.expectEqual(@as(?[]const u8, null), it.next());
}

test "words: snake_case" {
    var it = words("hello_world_test");
    try std.testing.expectEqualStrings("hello", it.next().?);
    try std.testing.expectEqualStrings("world", it.next().?);
    try std.testing.expectEqualStrings("test", it.next().?);
    try std.testing.expectEqual(@as(?[]const u8, null), it.next());
}

test "words: kebab-case" {
    var it = words("hello-world");
    try std.testing.expectEqualStrings("hello", it.next().?);
    try std.testing.expectEqualStrings("world", it.next().?);
}

test "words: empty string" {
    var it = words("");
    try std.testing.expectEqual(@as(?[]const u8, null), it.next());
}

test "words: PascalCase" {
    var it = words("HelloWorld");
    try std.testing.expectEqualStrings("Hello", it.next().?);
    try std.testing.expectEqualStrings("World", it.next().?);
}

test "wordsAlloc: collects words" {
    const ws = try wordsAlloc(std.testing.allocator, "hello_world");
    defer std.testing.allocator.free(ws);
    try std.testing.expectEqual(@as(usize, 2), ws.len);
    try std.testing.expectEqualStrings("hello", ws[0]);
    try std.testing.expectEqualStrings("world", ws[1]);
}

test "wordsAlloc: empty string" {
    const ws = try wordsAlloc(std.testing.allocator, "");
    defer std.testing.allocator.free(ws);
    try std.testing.expectEqual(@as(usize, 0), ws.len);
}

test "wordsAlloc: single word" {
    const ws = try wordsAlloc(std.testing.allocator, "hello");
    defer std.testing.allocator.free(ws);
    try std.testing.expectEqual(@as(usize, 1), ws.len);
}

test "camelCase: from snake_case" {
    const s = try camelCase(std.testing.allocator, "hello_world");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("helloWorld", s);
}

test "camelCase: from PascalCase" {
    const s = try camelCase(std.testing.allocator, "HelloWorld");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("helloWorld", s);
}

test "camelCase: empty string" {
    const s = try camelCase(std.testing.allocator, "");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("", s);
}

test "pascalCase: from snake_case" {
    const s = try pascalCase(std.testing.allocator, "hello_world");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("HelloWorld", s);
}

test "pascalCase: from camelCase" {
    const s = try pascalCase(std.testing.allocator, "helloWorld");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("HelloWorld", s);
}

test "pascalCase: empty string" {
    const s = try pascalCase(std.testing.allocator, "");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("", s);
}

test "snakeCase: from camelCase" {
    const s = try snakeCase(std.testing.allocator, "helloWorld");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("hello_world", s);
}

test "snakeCase: from PascalCase" {
    const s = try snakeCase(std.testing.allocator, "HelloWorld");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("hello_world", s);
}

test "snakeCase: already snake_case" {
    const s = try snakeCase(std.testing.allocator, "hello_world");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("hello_world", s);
}

test "kebabCase: from camelCase" {
    const s = try kebabCase(std.testing.allocator, "helloWorld");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("hello-world", s);
}

test "kebabCase: from snake_case" {
    const s = try kebabCase(std.testing.allocator, "hello_world");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("hello-world", s);
}

test "kebabCase: empty string" {
    const s = try kebabCase(std.testing.allocator, "");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("", s);
}

test "capitalize: lowercase input" {
    const s = try capitalize(std.testing.allocator, "hello");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("Hello", s);
}

test "capitalize: already capitalized" {
    const s = try capitalize(std.testing.allocator, "Hello");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("Hello", s);
}

test "capitalize: empty string" {
    const s = try capitalize(std.testing.allocator, "");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("", s);
}

test "ellipsis: short string unchanged" {
    const s = try ellipsis(std.testing.allocator, "hi", 10);
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("hi", s);
}

test "ellipsis: truncates with dots" {
    const s = try ellipsis(std.testing.allocator, "hello world", 8);
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("hello...", s);
}

test "ellipsis: very short max" {
    const s = try ellipsis(std.testing.allocator, "hello", 2);
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("..", s);
}

test "strRepeat: repeats string" {
    const s = try strRepeat(std.testing.allocator, "ab", 3);
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("ababab", s);
}

test "strRepeat: zero times" {
    const s = try strRepeat(std.testing.allocator, "ab", 0);
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("", s);
}

test "strRepeat: empty input" {
    const s = try strRepeat(std.testing.allocator, "", 5);
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("", s);
}

test "padLeft: pads shorter string" {
    const s = try padLeft(std.testing.allocator, "42", 5, '0');
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("00042", s);
}

test "padLeft: string already long enough" {
    const s = try padLeft(std.testing.allocator, "hello", 3, '0');
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("hello", s);
}

test "padLeft: exact length" {
    const s = try padLeft(std.testing.allocator, "abc", 3, '0');
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("abc", s);
}

test "padRight: pads shorter string" {
    const s = try padRight(std.testing.allocator, "hi", 5, '.');
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("hi...", s);
}

test "padRight: string already long enough" {
    const s = try padRight(std.testing.allocator, "hello", 3, '.');
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("hello", s);
}

test "padRight: exact length" {
    const s = try padRight(std.testing.allocator, "abc", 3, '.');
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("abc", s);
}

test "runeLength: ascii" {
    try std.testing.expectEqual(@as(usize, 5), try runeLength("hello"));
}

test "runeLength: empty" {
    try std.testing.expectEqual(@as(usize, 0), try runeLength(""));
}

test "runeLength: multibyte" {
    // Each CJK char is 3 bytes in UTF-8.
    try std.testing.expectEqual(@as(usize, 3), try runeLength("日本語"));
}

test "runeLength: invalid utf8 returns error" {
    const invalid = [_]u8{ 0xff, 0xfe };
    try std.testing.expectError(error.InvalidUtf8, runeLength(&invalid));
}

test "randomString: correct length" {
    var prng = std.Random.DefaultPrng.init(12345);
    const s = try randomString(std.testing.allocator, 10, prng.random());
    defer std.testing.allocator.free(s);
    try std.testing.expectEqual(@as(usize, 10), s.len);
}

test "randomString: zero length" {
    var prng = std.Random.DefaultPrng.init(0);
    const s = try randomString(std.testing.allocator, 0, prng.random());
    defer std.testing.allocator.free(s);
    try std.testing.expectEqual(@as(usize, 0), s.len);
}

test "randomString: all chars are alphanumeric" {
    var prng = std.Random.DefaultPrng.init(99);
    const s = try randomString(std.testing.allocator, 100, prng.random());
    defer std.testing.allocator.free(s);
    for (s) |c| {
        try std.testing.expect(
            (c >= 'a' and c <= 'z') or
                (c >= 'A' and c <= 'Z') or
                (c >= '0' and c <= '9'),
        );
    }
}
