const std = @import("std");
const Allocator = std.mem.Allocator;

/// Iterator that splits a string into words at camelCase, PascalCase,
/// snake_case, kebab-case, and whitespace boundaries.
/// Returned slices borrow from the input string -- they are NOT copies.
/// Do not use returned slices after the input string is freed or goes out of scope.
///
/// Returned by `words()`. See `words()` for usage examples.
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
/// Caller owns the returned slice.
///
/// ```zig
/// const ws = try lo.wordsAlloc(allocator, "camelCase");
/// defer allocator.free(ws);
/// // ws: &.{ "camel", "Case" }
/// ```
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
                try list.append(allocator, std.ascii.toLower(c));
            } else if (i == 0) {
                try list.append(allocator, std.ascii.toUpper(c));
            } else {
                try list.append(allocator, std.ascii.toLower(c));
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
                try list.append(allocator, std.ascii.toUpper(c));
            } else {
                try list.append(allocator, std.ascii.toLower(c));
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
            try list.append(allocator, std.ascii.toLower(c));
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
    result[0] = std.ascii.toUpper(input[0]);
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

/// Trim whitespace from both ends of a string.
///
/// ```zig
/// const s = lo.trim("  hello  ");
/// // s == "hello"
/// ```
pub fn trim(input: []const u8) []const u8 {
    return std.mem.trim(u8, input, &std.ascii.whitespace);
}

/// Trim whitespace from the start (left) of a string.
///
/// ```zig
/// const s = lo.trimStart("  hello  ");
/// // s == "hello  "
/// ```
pub fn trimStart(input: []const u8) []const u8 {
    return std.mem.trimLeft(u8, input, &std.ascii.whitespace);
}

/// Trim whitespace from the end (right) of a string.
///
/// ```zig
/// const s = lo.trimEnd("  hello  ");
/// // s == "  hello"
/// ```
pub fn trimEnd(input: []const u8) []const u8 {
    return std.mem.trimRight(u8, input, &std.ascii.whitespace);
}

/// Check if a string starts with a given prefix.
///
/// ```zig
/// lo.startsWith("hello world", "hello"); // true
/// ```
pub fn startsWith(haystack: []const u8, needle: []const u8) bool {
    return std.mem.startsWith(u8, haystack, needle);
}

/// Check if a string ends with a given suffix.
///
/// ```zig
/// lo.endsWith("hello world", "world"); // true
/// ```
pub fn endsWith(haystack: []const u8, needle: []const u8) bool {
    return std.mem.endsWith(u8, haystack, needle);
}

/// Check if a string contains a substring.
///
/// ```zig
/// lo.includes("hello world", "world"); // true
/// ```
pub fn includes(haystack: []const u8, needle: []const u8) bool {
    return std.mem.indexOf(u8, haystack, needle) != null;
}

/// Convert an entire string to lowercase (ASCII).
/// Caller owns the returned memory.
///
/// ```zig
/// const s = try lo.toLower(alloc, "Hello World");
/// defer alloc.free(s);
/// // s == "hello world"
/// ```
pub fn toLower(allocator: Allocator, input: []const u8) Allocator.Error![]u8 {
    return std.ascii.allocLowerString(allocator, input);
}

/// Convert an entire string to uppercase (ASCII).
/// Caller owns the returned memory.
///
/// ```zig
/// const s = try lo.toUpper(alloc, "Hello World");
/// defer alloc.free(s);
/// // s == "HELLO WORLD"
/// ```
pub fn toUpper(allocator: Allocator, input: []const u8) Allocator.Error![]u8 {
    return std.ascii.allocUpperString(allocator, input);
}

/// Lowercase just the first character of a string (ASCII).
/// Caller owns the returned memory.
///
/// ```zig
/// const s = try lo.lowerFirst(alloc, "Hello");
/// defer alloc.free(s);
/// // s == "hello"
/// ```
pub fn lowerFirst(allocator: Allocator, input: []const u8) Allocator.Error![]u8 {
    if (input.len == 0) {
        return allocator.alloc(u8, 0);
    }
    const result = try allocator.alloc(u8, input.len);
    @memcpy(result, input);
    result[0] = std.ascii.toLower(input[0]);
    return result;
}

/// Extract a substring by start and end byte indices.
/// Indices are clamped to the string length. Returns empty if start >= end.
///
/// ```zig
/// const s = lo.substr("hello", 2, 5);
/// // s == "llo"
/// ```
pub fn substr(input: []const u8, start: usize, end: usize) []const u8 {
    const s = @min(start, input.len);
    const e = @min(end, input.len);
    if (s >= e) return input[0..0];
    return input[s..e];
}

/// Split a string by a delimiter sequence, returning a lazy iterator.
/// Preserves empty tokens (e.g., "a,,b" yields "a", "", "b").
/// Returned slices borrow from the input string -- they are NOT copies.
///
/// ```zig
/// var it = lo.split("one,two,,four", ",");
/// it.next(); // "one"
/// it.next(); // "two"
/// it.next(); // ""
/// it.next(); // "four"
/// ```
pub fn split(input: []const u8, delimiter: []const u8) std.mem.SplitIterator(u8, .sequence) {
    return std.mem.splitSequence(u8, input, delimiter);
}

/// Split a string by a delimiter, collected into an allocated slice.
/// Caller owns the returned outer slice (free with `allocator.free(result)`).
/// Inner slices borrow from `input` -- do not use after `input` is freed.
///
/// ```zig
/// const parts = try lo.splitAlloc(alloc, "a-b-c", "-");
/// defer alloc.free(parts);
/// // parts[0] == "a", parts[1] == "b", parts[2] == "c"
/// ```
pub fn splitAlloc(
    allocator: Allocator,
    input: []const u8,
    delimiter: []const u8,
) Allocator.Error![][]const u8 {
    var it = std.mem.splitSequence(u8, input, delimiter);
    var list = std.ArrayList([]const u8){};
    errdefer list.deinit(allocator);
    while (it.next()) |part| {
        try list.append(allocator, part);
    }
    return list.toOwnedSlice(allocator);
}

/// Join a slice of strings with a separator into a single owned string.
/// Result is always caller-owned (freeable with `allocator.free`),
/// including for empty input.
///
/// ```zig
/// const s = try lo.join(alloc, ", ", &.{"hello", "world"});
/// defer alloc.free(s);
/// // s == "hello, world"
/// ```
pub fn join(
    allocator: Allocator,
    separator: []const u8,
    strings_slice: []const []const u8,
) Allocator.Error![]u8 {
    if (strings_slice.len == 0) {
        return allocator.dupe(u8, "");
    }
    return std.mem.join(allocator, separator, strings_slice);
}

/// Replace the first occurrence of `needle` in `input` with `replacement`.
/// Returns an owned copy. If needle is empty or not found, returns a copy of input.
///
/// ```zig
/// const s = try lo.replace(alloc, "hello hello", "hello", "hi");
/// defer alloc.free(s);
/// // s == "hi hello"
/// ```
pub fn replace(
    allocator: Allocator,
    input: []const u8,
    needle: []const u8,
    replacement: []const u8,
) Allocator.Error![]u8 {
    if (needle.len == 0) {
        return allocator.dupe(u8, input);
    }
    const pos = std.mem.indexOf(u8, input, needle) orelse {
        return allocator.dupe(u8, input);
    };
    const new_len = input.len - needle.len + replacement.len;
    const result = try allocator.alloc(u8, new_len);
    @memcpy(result[0..pos], input[0..pos]);
    @memcpy(result[pos..][0..replacement.len], replacement);
    @memcpy(result[pos + replacement.len ..], input[pos + needle.len ..]);
    return result;
}

/// Replace all occurrences of `needle` in `input` with `replacement`.
/// Returns an owned copy. If needle is empty or not found, returns a copy of input.
///
/// ```zig
/// const s = try lo.replaceAll(alloc, "hello hello", "hello", "hi");
/// defer alloc.free(s);
/// // s == "hi hi"
/// ```
pub fn replaceAll(
    allocator: Allocator,
    input: []const u8,
    needle: []const u8,
    replacement: []const u8,
) Allocator.Error![]u8 {
    if (needle.len == 0) {
        return allocator.dupe(u8, input);
    }
    return std.mem.replaceOwned(u8, allocator, input, needle, replacement);
}

/// Iterator that splits a string into fixed-size byte chunks.
/// The last chunk may be smaller than `size` if the input length
/// is not evenly divisible.
/// Returned slices borrow from the input string -- they are NOT copies.
///
/// ```zig
/// var it = lo.chunkString("abcdefgh", 3);
/// it.next(); // "abc"
/// it.next(); // "def"
/// it.next(); // "gh"
/// it.next(); // null
/// ```
pub const StringChunkIterator = struct {
    input: []const u8,
    size: usize,
    index: usize = 0,

    pub fn next(self: *StringChunkIterator) ?[]const u8 {
        if (self.size == 0 or self.index >= self.input.len) return null;
        const end = @min(self.index + self.size, self.input.len);
        const chunk = self.input[self.index..end];
        self.index = end;
        return chunk;
    }
};

/// Split a string into fixed-size byte chunks via a lazy iterator.
/// Returns null immediately for empty input or zero size.
///
/// ```zig
/// var it = lo.chunkString("abcdefgh", 3);
/// it.next(); // "abc"
/// it.next(); // "def"
/// it.next(); // "gh"
/// ```
pub fn chunkString(input: []const u8, size: usize) StringChunkIterator {
    return .{ .input = input, .size = size };
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

// -- trim tests --

test "trim: whitespace both ends" {
    try std.testing.expectEqualStrings("hello", trim("  hello  "));
}

test "trim: empty string" {
    try std.testing.expectEqualStrings("", trim(""));
}

test "trim: all whitespace" {
    try std.testing.expectEqualStrings("", trim("   \t\n  "));
}

test "trim: no whitespace" {
    try std.testing.expectEqualStrings("no-whitespace", trim("no-whitespace"));
}

test "trimStart: removes leading whitespace" {
    try std.testing.expectEqualStrings("hello  ", trimStart("  hello  "));
}

test "trimEnd: removes trailing whitespace" {
    try std.testing.expectEqualStrings("  hello", trimEnd("  hello  "));
}

test "trimStart: empty string" {
    try std.testing.expectEqualStrings("", trimStart(""));
}

test "trimEnd: empty string" {
    try std.testing.expectEqualStrings("", trimEnd(""));
}

// -- startsWith / endsWith / includes tests --

test "startsWith: matching prefix" {
    try std.testing.expect(startsWith("hello world", "hello"));
}

test "startsWith: empty needle" {
    try std.testing.expect(startsWith("hello", ""));
}

test "startsWith: non-matching" {
    try std.testing.expect(!startsWith("hello", "world"));
}

test "startsWith: empty haystack" {
    try std.testing.expect(!startsWith("", "a"));
}

test "endsWith: matching suffix" {
    try std.testing.expect(endsWith("hello world", "world"));
}

test "endsWith: empty needle" {
    try std.testing.expect(endsWith("hello", ""));
}

test "endsWith: non-matching" {
    try std.testing.expect(!endsWith("hello", "world"));
}

test "includes: substring present" {
    try std.testing.expect(includes("hello world", "world"));
}

test "includes: empty needle" {
    try std.testing.expect(includes("hello", ""));
}

test "includes: substring absent" {
    try std.testing.expect(!includes("hello", "xyz"));
}

test "includes: empty haystack" {
    try std.testing.expect(!includes("", "a"));
}

// -- toLower / toUpper tests --

test "toLower: mixed case" {
    const alloc = std.testing.allocator;
    const s = try toLower(alloc, "Hello World");
    defer alloc.free(s);
    try std.testing.expectEqualStrings("hello world", s);
}

test "toLower: empty string" {
    const alloc = std.testing.allocator;
    const s = try toLower(alloc, "");
    defer alloc.free(s);
    try std.testing.expectEqualStrings("", s);
}

test "toLower: all uppercase" {
    const alloc = std.testing.allocator;
    const s = try toLower(alloc, "HELLO");
    defer alloc.free(s);
    try std.testing.expectEqualStrings("hello", s);
}

test "toUpper: mixed case" {
    const alloc = std.testing.allocator;
    const s = try toUpper(alloc, "Hello World");
    defer alloc.free(s);
    try std.testing.expectEqualStrings("HELLO WORLD", s);
}

test "toUpper: empty string" {
    const alloc = std.testing.allocator;
    const s = try toUpper(alloc, "");
    defer alloc.free(s);
    try std.testing.expectEqualStrings("", s);
}

// -- lowerFirst tests --

test "lowerFirst: uppercase first" {
    const alloc = std.testing.allocator;
    const s = try lowerFirst(alloc, "Hello");
    defer alloc.free(s);
    try std.testing.expectEqualStrings("hello", s);
}

test "lowerFirst: empty string" {
    const alloc = std.testing.allocator;
    const s = try lowerFirst(alloc, "");
    defer alloc.free(s);
    try std.testing.expectEqualStrings("", s);
}

test "lowerFirst: already lowercase" {
    const alloc = std.testing.allocator;
    const s = try lowerFirst(alloc, "hello");
    defer alloc.free(s);
    try std.testing.expectEqualStrings("hello", s);
}

test "lowerFirst: single char" {
    const alloc = std.testing.allocator;
    const s = try lowerFirst(alloc, "H");
    defer alloc.free(s);
    try std.testing.expectEqualStrings("h", s);
}

// -- substr tests --

test "substr: middle to end" {
    try std.testing.expectEqualStrings("llo", substr("hello", 2, 5));
}

test "substr: full string" {
    try std.testing.expectEqualStrings("hello", substr("hello", 0, 5));
}

test "substr: end beyond length" {
    try std.testing.expectEqualStrings("lo", substr("hello", 3, 100));
}

test "substr: start at length" {
    try std.testing.expectEqualStrings("", substr("hello", 5, 10));
}

test "substr: start >= end after clamping" {
    try std.testing.expectEqualStrings("", substr("hello", 4, 2));
}

test "substr: empty input" {
    try std.testing.expectEqualStrings("", substr("", 0, 5));
}

// -- split tests --

test "split: basic delimiter" {
    var it = split("one,two,,four", ",");
    try std.testing.expectEqualStrings("one", it.next().?);
    try std.testing.expectEqualStrings("two", it.next().?);
    try std.testing.expectEqualStrings("", it.next().?);
    try std.testing.expectEqualStrings("four", it.next().?);
    try std.testing.expectEqual(@as(?[]const u8, null), it.next());
}

test "split: delimiter not found" {
    var it = split("hello", ",");
    try std.testing.expectEqualStrings("hello", it.next().?);
    try std.testing.expectEqual(@as(?[]const u8, null), it.next());
}

test "split: empty input" {
    var it = split("", ",");
    try std.testing.expectEqualStrings("", it.next().?);
    try std.testing.expectEqual(@as(?[]const u8, null), it.next());
}

test "split: delimiter only" {
    var it = split(",", ",");
    try std.testing.expectEqualStrings("", it.next().?);
    try std.testing.expectEqualStrings("", it.next().?);
    try std.testing.expectEqual(@as(?[]const u8, null), it.next());
}

// -- splitAlloc tests --

test "splitAlloc: basic" {
    const alloc = std.testing.allocator;
    const result = try splitAlloc(alloc, "a-b-c", "-");
    defer alloc.free(result);
    try std.testing.expectEqual(@as(usize, 3), result.len);
    try std.testing.expectEqualStrings("a", result[0]);
    try std.testing.expectEqualStrings("b", result[1]);
    try std.testing.expectEqualStrings("c", result[2]);
}

test "splitAlloc: empty input" {
    const alloc = std.testing.allocator;
    const result = try splitAlloc(alloc, "", "-");
    defer alloc.free(result);
    try std.testing.expectEqual(@as(usize, 1), result.len);
    try std.testing.expectEqualStrings("", result[0]);
}

test "splitAlloc: consecutive delimiters" {
    const alloc = std.testing.allocator;
    const result = try splitAlloc(alloc, "a,,b", ",");
    defer alloc.free(result);
    try std.testing.expectEqual(@as(usize, 3), result.len);
    try std.testing.expectEqualStrings("a", result[0]);
    try std.testing.expectEqualStrings("", result[1]);
    try std.testing.expectEqualStrings("b", result[2]);
}

// -- join tests --

test "join: basic" {
    const alloc = std.testing.allocator;
    const result = try join(alloc, ", ", &.{ "hello", "world" });
    defer alloc.free(result);
    try std.testing.expectEqualStrings("hello, world", result);
}

test "join: single element" {
    const alloc = std.testing.allocator;
    const result = try join(alloc, "-", &.{"a"});
    defer alloc.free(result);
    try std.testing.expectEqualStrings("a", result);
}

test "join: empty slice" {
    const alloc = std.testing.allocator;
    const result = try join(alloc, ", ", &.{});
    defer alloc.free(result);
    try std.testing.expectEqualStrings("", result);
}

// -- replace tests --

test "replace: first occurrence only" {
    const alloc = std.testing.allocator;
    const result = try replace(alloc, "hello hello", "hello", "hi");
    defer alloc.free(result);
    try std.testing.expectEqualStrings("hi hello", result);
}

test "replace: needle not found" {
    const alloc = std.testing.allocator;
    const result = try replace(alloc, "hello", "xyz", "abc");
    defer alloc.free(result);
    try std.testing.expectEqualStrings("hello", result);
}

test "replace: empty needle" {
    const alloc = std.testing.allocator;
    const result = try replace(alloc, "hello", "", "abc");
    defer alloc.free(result);
    try std.testing.expectEqualStrings("hello", result);
}

test "replace: empty input" {
    const alloc = std.testing.allocator;
    const result = try replace(alloc, "", "a", "b");
    defer alloc.free(result);
    try std.testing.expectEqualStrings("", result);
}

// -- replaceAll tests --

test "replaceAll: all occurrences" {
    const alloc = std.testing.allocator;
    const result = try replaceAll(alloc, "hello hello", "hello", "hi");
    defer alloc.free(result);
    try std.testing.expectEqualStrings("hi hi", result);
}

test "replaceAll: expanding replacement" {
    const alloc = std.testing.allocator;
    const result = try replaceAll(alloc, "aaa", "a", "bb");
    defer alloc.free(result);
    try std.testing.expectEqualStrings("bbbbbb", result);
}

test "replaceAll: needle not found" {
    const alloc = std.testing.allocator;
    const result = try replaceAll(alloc, "hello", "xyz", "abc");
    defer alloc.free(result);
    try std.testing.expectEqualStrings("hello", result);
}

test "replaceAll: empty needle guard" {
    const alloc = std.testing.allocator;
    const result = try replaceAll(alloc, "hello", "", "abc");
    defer alloc.free(result);
    try std.testing.expectEqualStrings("hello", result);
}

// -- chunkString tests --

test "chunkString: basic chunking" {
    var it = chunkString("abcdefgh", 3);
    try std.testing.expectEqualStrings("abc", it.next().?);
    try std.testing.expectEqualStrings("def", it.next().?);
    try std.testing.expectEqualStrings("gh", it.next().?);
    try std.testing.expectEqual(@as(?[]const u8, null), it.next());
}

test "chunkString: exact multiple" {
    var it = chunkString("abc", 3);
    try std.testing.expectEqualStrings("abc", it.next().?);
    try std.testing.expectEqual(@as(?[]const u8, null), it.next());
}

test "chunkString: empty input" {
    var it = chunkString("", 3);
    try std.testing.expectEqual(@as(?[]const u8, null), it.next());
}

test "chunkString: chunk larger than input" {
    var it = chunkString("abc", 10);
    try std.testing.expectEqualStrings("abc", it.next().?);
    try std.testing.expectEqual(@as(?[]const u8, null), it.next());
}

test "chunkString: zero size guard" {
    var it = chunkString("abc", 0);
    try std.testing.expectEqual(@as(?[]const u8, null), it.next());
}

test "chunkString: size of one" {
    var it = chunkString("abc", 1);
    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("b", it.next().?);
    try std.testing.expectEqualStrings("c", it.next().?);
    try std.testing.expectEqual(@as(?[]const u8, null), it.next());
}
