[![CI](https://github.com/OrlovEvgeny/lo.zig/actions/workflows/ci.yml/badge.svg)](https://github.com/OrlovEvgeny/lo.zig/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/OrlovEvgeny/lo.zig)](https://github.com/OrlovEvgeny/lo.zig/releases/latest)
[![Zig](https://img.shields.io/badge/zig-0.15.0-F7A41D?logo=zig&logoColor=white)](https://ziglang.org)

# lo.zig is a Lodash-style Zig library

<p align="center">
<img src="assets/logo.png" alt="lo.zig" width="900"/>
</p>

Generic utility library for Zig

Zero hidden allocations: functions that need memory take an `Allocator`.
Iterator-first: most transformations return lazy iterators.

## Installation

Add `lo.zig` as a dependency in your `build.zig.zon`:

```sh
zig fetch --save git+https://github.com/OrlovEvgeny/lo.zig
```

Then in your `build.zig`:

```zig
const lo_dep = b.dependency("lo", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("lo", lo_dep.module("lo"));
```

## Quick Start

```zig
const lo = @import("lo");

const total = lo.sum(i32, &.{ 1, 2, 3, 4 }); // 10
const head  = lo.first(i32, &.{ 10, 20, 30 }); // 10
const safe  = lo.unwrapOr(i32, null, 42); // 42
```

## Function Index

- [Slice Helpers](#slice-helpers) - first, last, nth, firstOr, lastOr, nthOr, initial, tail, drop, dropRight, dropWhile, dropWhileAlloc, dropRightWhile, take, takeRight, takeWhile, takeWhileAlloc, takeRightWhile, sample, samples
- [Transform](#transform) - map, mapAlloc, mapIndex, filter, filterAlloc, reject, rejectAlloc, compact, compactAlloc, flatten, flattenAlloc, flattenDeep, flatMap, flatMapAlloc, without, forEach, forEachIndex, compactMap, filterMapIter
- [Aggregate](#aggregate) - reduce, reduceRight, sum, sumBy, product, productBy, mean, meanBy, min, max, minBy, maxBy, minMax, minMaxBy, count, countBy, countValues, mode, median, variance, stddev, sampleVariance, sampleStddev, percentile
- [Sort & Order](#sort--order) - sortBy, sortByAlloc, sortByField, sortByFieldAlloc, toSortedAlloc, isSorted, equal, reverse, shuffle
- [Set Operations](#set-operations) - uniq, uniqBy, intersect, union\_, difference, symmetricDifference, findDuplicates, findUniques, elementsMatch, differenceWith, intersectWith, unionWith
- [Partition & Group](#partition--group) - partition, groupBy, chunk, window, scan, scanAlloc
- [Combine](#combine) - concat, splice, interleave, fill, fillRange, repeat, repeatBy, times, timesAlloc
- [Search](#search) - find, findIndex, findLast, findLastIndex, indexOf, lastIndexOf, contains, containsBy, every, some, none, minIndex, maxIndex, binarySearch, lowerBound, upperBound, sortedIndex, sortedLastIndex
- [Map Helpers](#map-helpers) - keys, keysAlloc, values, valuesAlloc, entries, entriesAlloc, fromEntries, mapKeys, mapValues, filterMap, filterKeys, filterValues, pickKeys, omitKeys, invert, merge, assign, mapEntries, mapToSlice, valueOr, hasKey, mapCount, keyBy, associate
- [String Helpers](#string-helpers) - words, wordsAlloc, camelCase, pascalCase, snakeCase, kebabCase, capitalize, lowerFirst, toLower, toUpper, trim, trimStart, trimEnd, startsWith, endsWith, includes, substr, ellipsis, strRepeat, padLeft, padRight, runeLength, randomString, split, splitAlloc, join, replace, replaceAll, chunkString
- [Math](#math) - sum, mean, median, variance, stddev, sampleVariance, sampleStddev, percentile, lerp, remap, clamp, inRange, cumSum, cumProd, rangeAlloc, rangeWithStepAlloc
- [Tuple Helpers](#tuple-helpers) - zip, zipAlloc, zipWith, unzip, enumerate
- [Type Helpers](#type-helpers) - isNull, isNotNull, unwrapOr, coalesce, empty, isEmpty, isNotEmpty, ternary, toConst
- [Types](#types) - Entry, Pair, MinMax, RangeError, PartitionResult, UnzipResult, AssocEntry, and iterator types

---

## Slice Helpers

### first

Returns the first element of a slice, or null if empty.

```zig
lo.first(i32, &.{ 10, 20, 30 }); // 10
```

### last

Returns the last element of a slice, or null if empty.

```zig
lo.last(i32, &.{ 10, 20, 30 }); // 30
```

### nth

Element at the given index. Negative indices count from the end. Returns null if out of bounds.

```zig
lo.nth(i32, &.{ 10, 20, 30 }, -1); // 30
```

### firstOr

Returns the first element, or a default if the slice is empty.

```zig
lo.firstOr(i32, &.{ 10, 20, 30 }, 0); // 10
lo.firstOr(i32, &.{}, 42);             // 42
```

### lastOr

Returns the last element, or a default if the slice is empty.

```zig
lo.lastOr(i32, &.{ 10, 20, 30 }, 0); // 30
lo.lastOr(i32, &.{}, 42);             // 42
```

### nthOr

Element at the given index with a default. Negative indices count from the end.

```zig
lo.nthOr(i32, &.{ 10, 20, 30 }, 1, 0);  // 20
lo.nthOr(i32, &.{ 10, 20, 30 }, -1, 0); // 30
lo.nthOr(i32, &.{ 10, 20, 30 }, 5, 99); // 99
```

### initial

All elements except the last. Empty slice if input is empty.

```zig
lo.initial(i32, &.{ 1, 2, 3 }); // &.{ 1, 2 }
```

### tail

All elements except the first. Empty slice if input is empty.

```zig
lo.tail(i32, &.{ 1, 2, 3 }); // &.{ 2, 3 }
```

### drop

Remove the first n elements, returning the rest as a sub-slice.

```zig
lo.drop(i32, &.{ 1, 2, 3, 4, 5 }, 2); // &.{ 3, 4, 5 }
```

### dropRight

Remove the last n elements, returning the rest as a sub-slice.

```zig
lo.dropRight(i32, &.{ 1, 2, 3, 4, 5 }, 2); // &.{ 1, 2, 3 }
```

### dropWhile

Drop leading elements while the predicate returns true.

```zig
lo.dropWhile(i32, &.{ 1, 2, 3, 4 }, isLessThan3); // &.{ 3, 4 }
```

### dropWhileAlloc

Drop leading elements while the predicate returns true. Allocates a copy. Caller owns the returned slice.

```zig
const result = try lo.dropWhileAlloc(i32, allocator, &.{ 1, 2, 3, 4 }, isLessThan3);
defer allocator.free(result);
// result == &.{ 3, 4 }
```

### dropRightWhile

Drop trailing elements while the predicate returns true.

```zig
lo.dropRightWhile(i32, &.{ 1, 2, 3, 4 }, isGt2); // &.{ 1, 2 }
```

### take

Take the first n elements as a sub-slice.

```zig
lo.take(i32, &.{ 1, 2, 3, 4, 5 }, 3); // &.{ 1, 2, 3 }
```

### takeRight

Take the last n elements as a sub-slice.

```zig
lo.takeRight(i32, &.{ 1, 2, 3, 4, 5 }, 2); // &.{ 4, 5 }
```

### takeWhile

Take leading elements while the predicate returns true.

```zig
lo.takeWhile(i32, &.{ 1, 2, 3, 4 }, isLessThan3); // &.{ 1, 2 }
```

### takeWhileAlloc

Take leading elements while the predicate returns true. Allocates a copy. Caller owns the returned slice.

```zig
const result = try lo.takeWhileAlloc(i32, allocator, &.{ 1, 2, 3, 4 }, isLessThan3);
defer allocator.free(result);
// result == &.{ 1, 2 }
```

### takeRightWhile

Take trailing elements while the predicate returns true.

```zig
lo.takeRightWhile(i32, &.{ 1, 2, 3, 4 }, isGt2); // &.{ 3, 4 }
```

### sample

Random element from a slice. Null if empty.

```zig
var prng = std.Random.DefaultPrng.init(0);
lo.sample(i32, &.{ 1, 2, 3 }, prng.random()); // random element
```

### samples

N random elements from a slice (with replacement). Caller owns the returned slice.

```zig
const s = try lo.samples(i32, allocator, &.{ 1, 2, 3 }, 5, rng);
defer allocator.free(s);
```

---

## Transform

### map

Transform each element. Returns a lazy iterator.

```zig
var it = lo.map(i32, i64, &.{ 1, 2, 3 }, double);
it.next(); // 2
```

### mapAlloc

Transform each element and collect into an allocated slice. Caller owns the returned slice.

```zig
const result = try lo.mapAlloc(i32, i32, allocator, &.{ 1, 2, 3 }, double);
defer allocator.free(result);
```

### mapIndex

Transform each element with its index. Returns a lazy iterator.

```zig
var it = lo.mapIndex(i32, i64, &.{ 10, 20 }, addIndex);
it.next(); // addIndex(10, 0)
```

### filter

Keep elements matching the predicate. Returns a lazy iterator.

```zig
var it = lo.filter(i32, &.{ 1, 2, 3, 4 }, isEven);
it.next(); // 2
it.next(); // 4
```

### filterAlloc

Keep elements matching the predicate, collected into an allocated slice. Caller owns the returned slice.

```zig
const result = try lo.filterAlloc(i32, allocator, &.{ 1, 2, 3, 4 }, isEven);
defer allocator.free(result);
```

### reject

Remove elements matching the predicate. Returns a lazy iterator.

```zig
var it = lo.reject(i32, &.{ 1, 2, 3, 4 }, isEven);
it.next(); // 1
it.next(); // 3
```

### rejectAlloc

Remove elements matching the predicate, collected into an allocated slice. Caller owns the returned slice.

```zig
const result = try lo.rejectAlloc(i32, allocator, &.{ 1, 2, 3, 4 }, isEven);
defer allocator.free(result);
```

### compact

Remove zero/null/default values. Returns a lazy iterator.

```zig
var it = lo.compact(?i32, &.{ 1, null, 3, null });
it.next(); // 1
it.next(); // 3
```

### compactAlloc

Remove zero/null/default values into an allocated slice. Caller owns the returned slice.

```zig
const result = try lo.compactAlloc(?i32, allocator, &.{ 1, null, 3 });
defer allocator.free(result);
```

### flatten

Flatten a slice of slices into a single sequence. Returns a lazy iterator.

```zig
const data = [_][]const i32{ &.{ 1, 2 }, &.{ 3, 4 } };
var it = lo.flatten(i32, &data);
// yields 1, 2, 3, 4
```

### flattenAlloc

Flatten a slice of slices into an allocated slice. Counts total elements first, then allocates once. Caller owns the returned slice.

```zig
const data = [_][]const i32{ &.{ 1, 2 }, &.{ 3, 4, 5 } };
const result = try lo.flattenAlloc(i32, allocator, &data);
defer allocator.free(result);
// result == &.{ 1, 2, 3, 4, 5 }
```

### flattenDeep

Flatten two levels of nesting (`[][][]T` to `[]T`). Caller owns the returned slice.

```zig
const inner = [_][]const i32{ &.{ 1, 2 }, &.{ 3 } };
const outer = [_][]const []const i32{ &inner };
const result = try lo.flattenDeep(i32, allocator, &outer);
defer allocator.free(result);
// result == &.{ 1, 2, 3 }
```

### flatMap

Map each element to a slice, then flatten into a single sequence. Returns a lazy iterator.

```zig
var it = lo.flatMap(i32, u8, &.{ 1, 2 }, toDigits);
```

### flatMapAlloc

Map then flatten, collected into an allocated slice. Caller owns the returned slice.

```zig
const result = try lo.flatMapAlloc(i32, u8, allocator, &.{ 1, 2 }, toDigits);
defer allocator.free(result);
```

### without

Exclude specific values from a slice. Returns a lazy iterator.

```zig
var it = lo.without(i32, &.{ 1, 2, 3, 4 }, &.{ 2, 4 });
// yields 1, 3
```

### forEach

Invoke a function on each element.

```zig
lo.forEach(i32, &.{ 1, 2, 3 }, printFn);
```

### forEachIndex

Invoke a function on each element with its index.

```zig
lo.forEachIndex(i32, &.{ 10, 20 }, printWithIndex);
```

### compactMap

Filter and map in a single pass. The transform returns `?R`; non-null values are collected into an allocated slice. Caller owns the returned slice.

```zig
const toEvenDoubled = struct {
    fn f(x: i32) ?i32 {
        if (@mod(x, 2) == 0) return x * 2;
        return null;
    }
}.f;
const result = try lo.compactMap(i32, i32, allocator, &.{ 1, 2, 3, 4 }, toEvenDoubled);
defer allocator.free(result);
// result == &.{ 4, 8 }
```

### filterMapIter

Filter and map in a single step. Returns a lazy iterator.

```zig
var it = lo.filterMapIter(i32, i32, &.{ 1, 2, 3, 4 }, toEvenDoubled);
it.next(); // 4
it.next(); // 8
it.next(); // null
```

---

## Aggregate

### reduce

Left fold with an accumulator.

```zig
lo.reduce(i32, i32, &.{ 1, 2, 3 }, addFn, 0); // 6
```

### reduceRight

Right fold with an accumulator. Processes elements right to left.

```zig
lo.reduceRight(i32, i32, &.{ 1, 2, 3 }, subtractFn, 0);
```

### sum

Sum all elements in a slice. Returns 0 for empty slices.

```zig
lo.sum(i32, &.{ 1, 2, 3, 4 }); // 10
```

### sumBy

Sum elements after applying a transform function.

```zig
lo.sumBy(i32, i64, &.{ 1, 2, 3 }, double); // 12
```

### product

Multiply all elements in a slice. Returns 1 for empty slices.

```zig
lo.product(i32, &.{ 2, 3, 4 }); // 24
```

### productBy

Multiply elements after applying a transform function.

```zig
lo.productBy(i32, i64, &.{ 2, 3, 4 }, double); // 192
```

### mean

Arithmetic mean of a slice. Returns null for empty slices.

```zig
lo.mean(i32, &.{ 2, 4, 6 }).?; // 4.0
```

### meanBy

Arithmetic mean after applying a transform function.

```zig
const asF64 = struct { fn f(x: i32) f64 { return @floatFromInt(x); } }.f;
lo.meanBy(i32, &vals, asF64).?; // 20.0
```

### min

Returns the minimum value in a slice, or null if empty.

```zig
lo.min(i32, &.{ 3, 1, 2 }); // 1
```

### max

Returns the maximum value in a slice, or null if empty.

```zig
lo.max(i32, &.{ 3, 1, 2 }); // 3
```

### minBy

Returns the minimum element according to a comparator.

```zig
lo.minBy(Point, &points, Point.compareByX); // point with smallest x
```

### maxBy

Returns the maximum element according to a comparator.

```zig
lo.maxBy(Point, &points, Point.compareByX); // point with largest x
```

### minMax

Returns both min and max in a single pass. Null if empty.

```zig
const mm = lo.minMax(i32, &.{ 5, 1, 9, 3 }).?;
// mm.min_val == 1, mm.max_val == 9
```

### minMaxBy

Returns both min and max in a single pass according to a custom comparator. Null if empty.

```zig
const byX = struct { fn f(a: Point, b: Point) std.math.Order {
    return std.math.order(a.x, b.x);
} }.f;
const mm = lo.minMaxBy(Point, &points, byX).?;
// mm.min_val and mm.max_val
```

### count

Count elements satisfying the predicate.

```zig
lo.count(i32, &.{ 1, 2, 3, 4 }, isEven); // 2
```

### countBy

Count elements by a key function. Returns a frequency map.

```zig
var m = try lo.countBy(i32, bool, allocator, &.{ 1, 2, 3, 4, 5 }, isEvenFn);
defer m.deinit();
m.get(true).?;  // 2
m.get(false).?; // 3
```

### countValues

Build a frequency map: value -> number of occurrences. Caller owns the returned map.

```zig
var freq = try lo.countValues(i32, allocator, &.{ 1, 2, 2, 3 });
defer freq.deinit();
freq.get(2).?; // 2
```

### mode

Returns the most frequently occurring value. Smallest value wins on ties. Null for empty slices.

```zig
const m = try lo.mode(i32, allocator, &.{ 1, 2, 2, 3, 2 });
// m == 2
```

### median

Returns the median of a numeric slice, or null if empty. Allocates a temporary copy for sorting.

```zig
const m = try lo.median(i32, allocator, &.{ 1, 2, 3, 4 });
// m == 2.5
```

### variance

Population variance (N denominator). Returns null for empty slices.

```zig
lo.variance(i32, &.{ 2, 4, 4, 4, 5, 5, 7, 9 }); // 4.0
```

### stddev

Standard deviation (sqrt of population variance). Returns null for empty slices.

```zig
lo.stddev(i32, &.{ 2, 4, 4, 4, 5, 5, 7, 9 }); // 2.0
```

### sampleVariance

Sample variance with N-1 denominator (Bessel's correction). Returns null for slices with fewer than 2 elements.

```zig
lo.sampleVariance(i32, &.{ 2, 4, 4, 4, 5, 5, 7, 9 }); // ~4.571
```

### sampleStddev

Sample standard deviation (sqrt of sample variance). Returns null for slices with fewer than 2 elements.

```zig
lo.sampleStddev(i32, &.{ 2, 4, 4, 4, 5, 5, 7, 9 }); // ~2.138
```

### percentile

Returns the nth percentile using linear interpolation. Null for empty slices or if p is outside [0, 100].

```zig
const p = try lo.percentile(i32, allocator, &.{ 1, 2, 3, 4, 5 }, 50.0);
// p == 3.0
```

---

## Sort & Order

### sortBy

Sort a slice in-place by a key extracted via a function. Stable sort.

```zig
var items = [_]i32{ 30, 10, 20 };
lo.sortBy(i32, i32, &items, struct {
    fn f(x: i32) i32 { return x; }
}.f);
// items == { 10, 20, 30 }
```

### sortByAlloc

Returns a sorted copy without mutating the original. Caller owns the returned slice.

```zig
const sorted = try lo.sortByAlloc(i32, i32, allocator, &.{ 30, 10, 20 }, struct {
    fn f(x: i32) i32 { return x; }
}.f);
defer allocator.free(sorted);
// sorted == { 10, 20, 30 }
```

### sortByField

Sort a slice of structs in-place by a named field. Stable sort.

```zig
const Person = struct { name: []const u8, age: u32 };
var items = [_]Person{ .{ .name = "bob", .age = 30 }, .{ .name = "alice", .age = 25 } };
lo.sortByField(Person, &items, .age);
// items[0].age == 25, items[1].age == 30
```

### sortByFieldAlloc

Returns a sorted copy of the slice sorted by a named struct field. Caller owns the returned slice.

```zig
const sorted = try lo.sortByFieldAlloc(Person, allocator, &people, .age);
defer allocator.free(sorted);
```

### toSortedAlloc

Returns a sorted copy in natural ascending order. Caller owns the returned slice.

```zig
const sorted = try lo.toSortedAlloc(i32, allocator, &.{ 3, 1, 2 });
defer allocator.free(sorted);
// sorted == { 1, 2, 3 }
```

### isSorted

True if the slice is sorted according to the comparator.

```zig
lo.isSorted(i32, &.{ 1, 2, 3 }, compareAsc); // true
```

### equal

Element-wise equality of two slices.

```zig
lo.equal(i32, &.{ 1, 2, 3 }, &.{ 1, 2, 3 }); // true
```

### reverse

Reverse a slice in-place.

```zig
var data = [_]i32{ 1, 2, 3 };
lo.reverse(i32, &data);
// data == .{ 3, 2, 1 }
```

### shuffle

Fisher-Yates shuffle in-place.

```zig
var data = [_]i32{ 1, 2, 3, 4, 5 };
lo.shuffle(i32, &data, prng.random());
```

---

## Set Operations

### uniq

Remove duplicate elements. Preserves first occurrence order.

```zig
const u = try lo.uniq(i32, allocator, &.{ 1, 2, 2, 3, 1 });
defer allocator.free(u);
// u == &.{ 1, 2, 3 }
```

### uniqBy

Remove duplicates by a key function. Preserves first occurrence order.

```zig
const u = try lo.uniqBy(Person, u32, allocator, &people, Person.id);
defer allocator.free(u);
```

### intersect

Elements present in both slices. Order follows the first slice.

```zig
const i = try lo.intersect(i32, allocator, &.{ 1, 2, 3 }, &.{ 2, 3, 4 });
defer allocator.free(i);
// i == &.{ 2, 3 }
```

### union\_

Unique elements from both slices combined.

```zig
const u = try lo.union_(i32, allocator, &.{ 1, 2, 3 }, &.{ 2, 3, 4 });
defer allocator.free(u);
// u == &.{ 1, 2, 3, 4 }
```

### difference

Elements in the first slice but not in the second.

```zig
const d = try lo.difference(i32, allocator, &.{ 1, 2, 3 }, &.{ 2, 4 });
defer allocator.free(d);
// d == &.{ 1, 3 }
```

### symmetricDifference

Elements in either slice but not in both.

```zig
const sd = try lo.symmetricDifference(i32, allocator, &.{ 1, 2, 3 }, &.{ 2, 3, 4 });
defer allocator.free(sd);
// sd == &.{ 1, 4 }
```

### findDuplicates

Find elements appearing more than once. Preserves first-occurrence order.

```zig
const dups = try lo.findDuplicates(i32, allocator, &.{ 1, 2, 2, 3, 3, 3 });
defer allocator.free(dups);
// dups == &.{ 2, 3 }
```

### findUniques

Find elements appearing exactly once.

```zig
const uniques = try lo.findUniques(i32, allocator, &.{ 1, 2, 2, 3, 3, 3, 4 });
defer allocator.free(uniques);
// uniques == &.{ 1, 4 }
```

### elementsMatch

True if two slices contain the same elements with the same multiplicities, regardless of order.

```zig
try lo.elementsMatch(i32, allocator, &.{ 1, 2, 3 }, &.{ 3, 2, 1 }); // true
try lo.elementsMatch(i32, allocator, &.{ 1, 1, 2 }, &.{ 1, 2, 2 }); // false
```

### differenceWith

Elements in the first slice but not in the second, using a custom equality predicate.

```zig
const absEq = struct { fn f(a: i32, b: i32) bool { return @abs(a) == @abs(b); } }.f;
const d = try lo.differenceWith(i32, allocator, &.{ 1, 2, 3 }, &.{ -2, 4 }, absEq);
defer allocator.free(d);
// d == &.{ 1, 3 }
```

### intersectWith

Elements present in both slices, using a custom equality predicate.

```zig
const i = try lo.intersectWith(i32, allocator, &.{ 1, -2, 3 }, &.{ 2, 4 }, absEq);
defer allocator.free(i);
// i == &.{ -2 }
```

### unionWith

Unique elements from both slices combined, using a custom equality predicate.

```zig
const u = try lo.unionWith(i32, allocator, &.{ 1, 2 }, &.{ -2, 3 }, absEq);
defer allocator.free(u);
// u == &.{ 1, 2, 3 }
```

---

## Partition & Group

### partition

Split a slice into two: elements matching the predicate and the rest.

```zig
const p = try lo.partition(i32, allocator, &.{ 1, 2, 3, 4 }, isEven);
defer p.deinit(allocator);
// p.matching == &.{ 2, 4 }, p.rest == &.{ 1, 3 }
```

### groupBy

Group elements by a key function. Caller owns the returned map.

```zig
var groups = try lo.groupBy(i32, bool, allocator, &.{ 1, 2, 3, 4 }, isEvenFn);
defer {
    var it = groups.valueIterator();
    while (it.next()) |list| list.deinit(allocator);
    groups.deinit();
}
```

### chunk

Split a slice into chunks of the given size. The last chunk may be smaller. Returns a lazy iterator.

```zig
var it = lo.chunk(i32, &.{ 1, 2, 3, 4, 5 }, 2);
it.next(); // &.{ 1, 2 }
it.next(); // &.{ 3, 4 }
it.next(); // &.{ 5 }
```

### window

Sliding window over a slice. Returns a lazy iterator. Windows borrow from the input (zero allocation).

```zig
var it = lo.window(i32, &.{ 1, 2, 3, 4, 5 }, 3);
it.next(); // &.{ 1, 2, 3 }
it.next(); // &.{ 2, 3, 4 }
it.next(); // &.{ 3, 4, 5 }
it.next(); // null
```

### scan

Like reduce but emits every intermediate result. Returns a lazy iterator.

```zig
const add = struct { fn f(a: i32, b: i32) i32 { return a + b; } }.f;
var it = lo.scan(i32, i32, &.{ 1, 2, 3 }, add, 0);
it.next(); // 1
it.next(); // 3
it.next(); // 6
```

### scanAlloc

Eagerly compute all intermediate accumulator values into an allocated slice. Caller owns the returned slice.

```zig
const add = struct { fn f(a: i32, b: i32) i32 { return a + b; } }.f;
const result = try lo.scanAlloc(i32, i32, allocator, &.{ 1, 2, 3 }, add, 0);
defer allocator.free(result);
// result == &.{ 1, 3, 6 }
```

---

## Combine

### concat

Concatenate multiple slices into a single allocated slice. Caller owns the returned slice.

```zig
const result = try lo.concat(i32, allocator, &.{ &.{ 1, 2 }, &.{ 3, 4 }, &.{5} });
defer allocator.free(result);
// result == { 1, 2, 3, 4, 5 }
```

### splice

Insert elements into a slice at a given index, returning a new allocated slice. Caller owns the returned slice.

```zig
const result = try lo.splice(i32, allocator, &.{ 1, 2, 5, 6 }, 2, &.{ 3, 4 });
defer allocator.free(result);
// result == { 1, 2, 3, 4, 5, 6 }
```

### interleave

Round-robin interleave multiple slices. Returns a lazy iterator.

```zig
var it = lo.interleave(i32, &.{ &.{ 1, 2, 3 }, &.{ 4, 5, 6 } });
it.next(); // 1
it.next(); // 4
it.next(); // 2
it.next(); // 5
```

### fill

Fill all elements with the given value (in-place).

```zig
var data = [_]i32{ 0, 0, 0 };
lo.fill(i32, &data, 42);
// data == .{ 42, 42, 42 }
```

### fillRange

Fill elements in the range [start, end) with the given value (in-place).

```zig
var data = [_]i32{ 1, 2, 3, 4, 5 };
lo.fillRange(i32, &data, 0, 1, 4);
// data == .{ 1, 0, 0, 0, 5 }
```

### repeat

Create a slice of n copies of a value. Caller owns the returned slice.

```zig
const r = try lo.repeat(i32, allocator, 42, 3);
defer allocator.free(r);
// r == &.{ 42, 42, 42 }
```

### repeatBy

Create a slice of n elements produced by a callback. Caller owns the returned slice.

```zig
const r = try lo.repeatBy(i32, allocator, 3, indexSquared);
defer allocator.free(r);
// r == &.{ 0, 1, 4 }
```

### times

Create a lazy iterator that calls a function N times with indices 0..N-1.

```zig
var iter = lo.times(usize, 4, square);
while (iter.next()) |val| { ... }
```

### timesAlloc

Eagerly call a function N times and return the results. Caller owns the returned slice.

```zig
const squares = try lo.timesAlloc(usize, allocator, 4, square);
defer allocator.free(squares);
// squares == { 0, 1, 4, 9 }
```

---

## Search

### find

First element matching the predicate, or null.

```zig
lo.find(i32, &.{ 1, 2, 3, 4 }, isEven); // 2
```

### findIndex

Index of the first element matching the predicate, or null.

```zig
lo.findIndex(i32, &.{ 1, 2, 3 }, isEven); // 1
```

### findLast

Last element matching the predicate, or null.

```zig
lo.findLast(i32, &.{ 1, 2, 3, 4 }, isEven); // 4
```

### findLastIndex

Index of the last element matching the predicate, or null.

```zig
lo.findLastIndex(i32, &.{ 1, 2, 3, 4 }, isEven); // 3
```

### indexOf

Index of the first occurrence of a value, or null.

```zig
lo.indexOf(i32, &.{ 10, 20, 30 }, 20); // 1
```

### lastIndexOf

Index of the last occurrence of a value, or null.

```zig
lo.lastIndexOf(i32, &.{ 1, 2, 3, 2 }, 2); // 3
```

### contains

True if the slice contains the given value.

```zig
lo.contains(i32, &.{ 1, 2, 3 }, 2); // true
```

### containsBy

True if any element satisfies the predicate.

```zig
lo.containsBy(i32, &.{ 1, 2, 3 }, isEven); // true
```

### every

True if all elements satisfy the predicate. True for empty slices.

```zig
lo.every(i32, &.{ 2, 4, 6 }, isEven); // true
```

### some

True if at least one element satisfies the predicate. False for empty slices.

```zig
lo.some(i32, &.{ 1, 2, 3 }, isEven); // true
```

### none

True if no elements satisfy the predicate. True for empty slices.

```zig
lo.none(i32, &.{ 1, 3, 5 }, isEven); // true
```

### minIndex

Returns the index of the minimum element, or null if empty. First occurrence on ties.

```zig
lo.minIndex(i32, &.{ 3, 1, 4, 1, 5 }); // 1
```

### maxIndex

Returns the index of the maximum element, or null if empty. First occurrence on ties.

```zig
lo.maxIndex(i32, &.{ 3, 1, 4, 1, 5 }); // 4
```

### binarySearch

Binary search for a target in a sorted ascending slice. Returns the index or null. O(log n).

```zig
lo.binarySearch(i32, &.{ 1, 3, 5, 7, 9 }, 5); // Some(2)
lo.binarySearch(i32, &.{ 1, 3, 5, 7, 9 }, 4); // null
```

### lowerBound

Index of the first element >= target in a sorted slice. Returns `slice.len` if all are less.

```zig
lo.lowerBound(i32, &.{ 1, 3, 5, 7 }, 4); // 2
lo.lowerBound(i32, &.{ 1, 3, 5, 7 }, 5); // 2
lo.lowerBound(i32, &.{ 1, 3, 5, 7 }, 9); // 4
```

### upperBound

Index of the first element > target in a sorted slice. Returns `slice.len` if all are <= target.

```zig
lo.upperBound(i32, &.{ 1, 3, 5, 7 }, 3); // 2
lo.upperBound(i32, &.{ 1, 3, 5, 7 }, 4); // 2
lo.upperBound(i32, &.{ 1, 3, 5, 7 }, 9); // 4
```

### sortedIndex

Insertion index to maintain sorted order. Equivalent to `lowerBound`.

```zig
lo.sortedIndex(i32, &.{ 1, 3, 5, 7 }, 4); // 2
```

### sortedLastIndex

Insertion index after the last occurrence of a value. Equivalent to `upperBound`.

```zig
lo.sortedLastIndex(i32, &.{ 1, 3, 3, 5 }, 3); // 3
```

---

## Map Helpers

### keys

Iterate over map keys. Returns a lazy iterator.

```zig
var it = lo.keys(u32, u8, &my_map);
while (it.next()) |key| { ... }
```

### keysAlloc

Collect all keys into an allocated slice. Caller owns the returned slice.

```zig
const ks = try lo.keysAlloc(u32, u8, allocator, &my_map);
defer allocator.free(ks);
```

### values

Iterate over map values. Returns a lazy iterator.

```zig
var it = lo.values(u32, u8, &my_map);
while (it.next()) |val| { ... }
```

### valuesAlloc

Collect all values into an allocated slice. Caller owns the returned slice.

```zig
const vs = try lo.valuesAlloc(u32, u8, allocator, &my_map);
defer allocator.free(vs);
```

### entries

Iterate over key-value pairs. Returns a lazy iterator.

```zig
var it = lo.entries(u32, u8, &my_map);
while (it.next()) |e| { _ = e.key; _ = e.value; }
```

### entriesAlloc

Collect all key-value pairs into an allocated slice. Caller owns the returned slice.

```zig
const es = try lo.entriesAlloc(u32, u8, allocator, &my_map);
defer allocator.free(es);
```

### fromEntries

Build a map from a slice of key-value pairs. Caller owns the returned map.

```zig
const pairs = [_]lo.Entry(u32, u8){ .{ .key = 1, .value = 'a' } };
var m = try lo.fromEntries(u32, u8, allocator, &pairs);
defer m.deinit();
```

### mapKeys

Transform map keys using a function. Caller owns the returned map.

```zig
var result = try lo.mapKeys(u32, u8, u64, allocator, &m, timesTwo);
defer result.deinit();
```

### mapValues

Transform map values using a function. Caller owns the returned map.

```zig
var result = try lo.mapValues(u32, u8, u16, allocator, &m, multiply);
defer result.deinit();
```

### filterMap

Filter map entries by a predicate on key and value. Caller owns the returned map.

```zig
var result = try lo.filterMap(u32, u8, allocator, &m, keyGt1);
defer result.deinit();
```

### filterKeys

Filter map entries by a predicate on the key. Caller owns the returned map.

```zig
var result = try lo.filterKeys(u32, u8, allocator, &m, isEven);
defer result.deinit();
```

### filterValues

Filter map entries by a predicate on the value. Caller owns the returned map.

```zig
var result = try lo.filterValues(u32, u8, allocator, &m, isPositive);
defer result.deinit();
```

### pickKeys

Keep only entries with the specified keys. Caller owns the returned map.

```zig
var result = try lo.pickKeys(u32, u8, allocator, &m, &.{ 1, 3 });
defer result.deinit();
```

### omitKeys

Remove entries with the specified keys. Caller owns the returned map.

```zig
var result = try lo.omitKeys(u32, u8, allocator, &m, &.{ 2, 3 });
defer result.deinit();
```

### invert

Swap keys and values. Caller owns the returned map.

```zig
var result = try lo.invert(u32, u8, allocator, &m);
defer result.deinit();
```

### merge

Merge entries from source into dest. Source values overwrite on conflict.

```zig
try lo.merge(u32, u8, &dest, &source);
```

### assign

Merge N maps into one with last-write-wins semantics. Caller owns the returned map.

```zig
var result = try lo.assign(u32, u8, allocator, &.{ &m1, &m2 });
defer result.deinit();
```

### mapEntries

Transform both keys and values of a map. Caller owns the returned map.

```zig
var result = try lo.mapEntries(u32, u8, u64, u16, allocator, &m, xform);
defer result.deinit();
```

### mapToSlice

Transform map entries into an allocated slice. Caller owns the returned slice.

```zig
const result = try lo.mapToSlice(u32, u8, u64, allocator, &m, sumKeyVal);
defer allocator.free(result);
```

### valueOr

Get a value from the map, or return a default if the key is absent.

```zig
lo.valueOr(u32, u8, &my_map, 999, 0); // 0 if 999 not in map
```

### hasKey

True if the map contains the given key.

```zig
lo.hasKey(u32, u8, &m, 1); // true
```

### mapCount

Number of entries in the map.

```zig
lo.mapCount(u32, u8, &m); // 3
```

### keyBy

Convert a slice to a map indexed by an extracted key. Last element wins on duplicate keys.

```zig
var m = try lo.keyBy(Person, u32, allocator, &people, getAge);
defer m.deinit();
```

### associate

Convert a slice to a map with custom key and value extraction. Last element wins on duplicate keys.

```zig
var m = try lo.associate(Person, u32, []const u8, allocator, &people, toEntry);
defer m.deinit();
```

---

## String Helpers

### words

Split a string into words at camelCase, PascalCase, snake\_case, kebab-case, and whitespace boundaries. Returns a lazy iterator.

```zig
var it = lo.words("helloWorld");
it.next(); // "hello"
it.next(); // "World"
```

### wordsAlloc

Split a string into words, collected into an allocated slice. Caller owns the returned slice.

```zig
const ws = try lo.wordsAlloc(allocator, "camelCase");
defer allocator.free(ws);
// ws: &.{ "camel", "Case" }
```

### camelCase

Convert a string to camelCase. Caller owns the returned string.

```zig
const s = try lo.camelCase(allocator, "hello_world");
defer allocator.free(s);
// s == "helloWorld"
```

### pascalCase

Convert a string to PascalCase. Caller owns the returned string.

```zig
const s = try lo.pascalCase(allocator, "hello_world");
defer allocator.free(s);
// s == "HelloWorld"
```

### snakeCase

Convert a string to snake\_case. Caller owns the returned string.

```zig
const s = try lo.snakeCase(allocator, "helloWorld");
defer allocator.free(s);
// s == "hello_world"
```

### kebabCase

Convert a string to kebab-case. Caller owns the returned string.

```zig
const s = try lo.kebabCase(allocator, "helloWorld");
defer allocator.free(s);
// s == "hello-world"
```

### capitalize

Capitalize the first letter of a string. Caller owns the returned string.

```zig
const s = try lo.capitalize(allocator, "hello");
defer allocator.free(s);
// s == "Hello"
```

### lowerFirst

Lowercase just the first character (ASCII). Caller owns the returned string.

```zig
const s = try lo.lowerFirst(allocator, "Hello");
defer allocator.free(s);
// s == "hello"
```

### toLower

Convert an entire string to lowercase (ASCII). Caller owns the returned string.

```zig
const s = try lo.toLower(allocator, "Hello World");
defer allocator.free(s);
// s == "hello world"
```

### toUpper

Convert an entire string to uppercase (ASCII). Caller owns the returned string.

```zig
const s = try lo.toUpper(allocator, "Hello World");
defer allocator.free(s);
// s == "HELLO WORLD"
```

### trim

Trim whitespace from both ends of a string. Returns a sub-slice (zero-copy).

```zig
lo.trim("  hello  "); // "hello"
```

### trimStart

Trim whitespace from the start of a string. Returns a sub-slice (zero-copy).

```zig
lo.trimStart("  hello  "); // "hello  "
```

### trimEnd

Trim whitespace from the end of a string. Returns a sub-slice (zero-copy).

```zig
lo.trimEnd("  hello  "); // "  hello"
```

### startsWith

Check if a string starts with a given prefix.

```zig
lo.startsWith("hello world", "hello"); // true
```

### endsWith

Check if a string ends with a given suffix.

```zig
lo.endsWith("hello world", "world"); // true
```

### includes

Check if a string contains a substring.

```zig
lo.includes("hello world", "world"); // true
```

### substr

Extract a substring by start and end byte indices. Indices are clamped. Returns a sub-slice (zero-copy).

```zig
lo.substr("hello", 2, 5); // "llo"
```

### ellipsis

Truncate a string and add "..." if it exceeds max\_len. Caller owns the returned string.

```zig
const s = try lo.ellipsis(allocator, "hello world", 8);
defer allocator.free(s);
// s == "hello..."
```

### strRepeat

Repeat a string n times. Caller owns the returned string.

```zig
const s = try lo.strRepeat(allocator, "ab", 3);
defer allocator.free(s);
// s == "ababab"
```

### padLeft

Left-pad a string to the given length. Caller owns the returned string.

```zig
const s = try lo.padLeft(allocator, "42", 5, '0');
defer allocator.free(s);
// s == "00042"
```

### padRight

Right-pad a string to the given length. Caller owns the returned string.

```zig
const s = try lo.padRight(allocator, "hi", 5, '.');
defer allocator.free(s);
// s == "hi..."
```

### runeLength

Count the number of Unicode codepoints in a UTF-8 string. Returns `error.InvalidUtf8` for invalid input.

```zig
try lo.runeLength("hello");     // 5
try lo.runeLength("\xc3\xa9");  // 1
```

### randomString

Generate a random alphanumeric string. Caller owns the returned string.

```zig
const s = try lo.randomString(allocator, 10, prng.random());
defer allocator.free(s);
```

### split

Split a string by a delimiter sequence. Returns a lazy iterator. Preserves empty tokens.

```zig
var it = lo.split("one,two,,four", ",");
it.next(); // "one"
it.next(); // "two"
it.next(); // ""
it.next(); // "four"
```

### splitAlloc

Split a string by a delimiter, collected into an allocated slice. Caller owns the returned outer slice.

```zig
const parts = try lo.splitAlloc(allocator, "a-b-c", "-");
defer allocator.free(parts);
// parts[0] == "a", parts[1] == "b", parts[2] == "c"
```

### join

Join a slice of strings with a separator. Caller owns the returned string.

```zig
const s = try lo.join(allocator, ", ", &.{ "hello", "world" });
defer allocator.free(s);
// s == "hello, world"
```

### replace

Replace the first occurrence of a needle. Caller owns the returned string.

```zig
const s = try lo.replace(allocator, "hello hello", "hello", "hi");
defer allocator.free(s);
// s == "hi hello"
```

### replaceAll

Replace all occurrences of a needle. Caller owns the returned string.

```zig
const s = try lo.replaceAll(allocator, "hello hello", "hello", "hi");
defer allocator.free(s);
// s == "hi hi"
```

### chunkString

Split a string into fixed-size byte chunks. Returns a lazy iterator. The last chunk may be smaller.

```zig
var it = lo.chunkString("abcdefgh", 3);
it.next(); // "abc"
it.next(); // "def"
it.next(); // "gh"
```

---

## Math

### sum

Sum all elements. Returns 0 for empty slices.

```zig
lo.sum(i32, &.{ 1, 2, 3, 4 }); // 10
```

### mean

Arithmetic mean. Returns null for empty slices.

```zig
lo.mean(i32, &.{ 2, 4, 6 }).?; // 4.0
```

### median

Median value. Allocates a temporary sorted copy. Null for empty slices.

```zig
const m = try lo.median(i32, allocator, &.{ 1, 2, 3, 4 });
// m == 2.5
```

### variance

Population variance (N denominator). Null for empty slices.

```zig
lo.variance(i32, &.{ 2, 4, 4, 4, 5, 5, 7, 9 }); // 4.0
```

### stddev

Standard deviation (sqrt of population variance). Null for empty slices.

```zig
lo.stddev(i32, &.{ 2, 4, 4, 4, 5, 5, 7, 9 }); // 2.0
```

### sampleVariance

Sample variance with N-1 denominator (Bessel's correction). Null for slices with fewer than 2 elements.

```zig
lo.sampleVariance(i32, &.{ 2, 4, 4, 4, 5, 5, 7, 9 }); // ~4.571
```

### sampleStddev

Sample standard deviation (sqrt of sample variance). Null for slices with fewer than 2 elements.

```zig
lo.sampleStddev(i32, &.{ 2, 4, 4, 4, 5, 5, 7, 9 }); // ~2.138
```

### percentile

Nth percentile using linear interpolation. Null for empty slices or p outside [0, 100].

```zig
const p = try lo.percentile(i32, allocator, &.{ 1, 2, 3, 4, 5 }, 50.0);
// p == 3.0
```

### lerp

Linear interpolation between two values. Float-only.

```zig
lo.lerp(f64, 0.0, 10.0, 0.5); // 5.0
```

### remap

Remap a value from one range to another. Float-only.

```zig
lo.remap(f64, 5.0, 0.0, 10.0, 0.0, 100.0); // 50.0
```

### clamp

Clamp a value to the range [lo, hi].

```zig
lo.clamp(i32, 15, 0, 10); // 10
lo.clamp(i32, -5, 0, 10); // 0
lo.clamp(i32, 5, 0, 10);  // 5
```

### inRange

Check if a value falls within the half-open range [start, end). Returns false if start >= end.

```zig
lo.inRange(i32, 3, 1, 5); // true
lo.inRange(i32, 5, 1, 5); // false (end is exclusive)
```

### cumSum

Cumulative sum. Caller owns the returned slice.

```zig
const result = try lo.cumSum(i32, allocator, &.{ 1, 2, 3, 4 });
defer allocator.free(result);
// result == { 1, 3, 6, 10 }
```

### cumProd

Cumulative product. Caller owns the returned slice.

```zig
const result = try lo.cumProd(i32, allocator, &.{ 1, 2, 3, 4 });
defer allocator.free(result);
// result == { 1, 2, 6, 24 }
```

### rangeAlloc

Allocate a slice containing integers in [start, end). Caller owns the returned slice.

```zig
const r = try lo.rangeAlloc(i32, allocator, 0, 5);
defer allocator.free(r);
// r == .{ 0, 1, 2, 3, 4 }
```

### rangeWithStepAlloc

Allocate a range with a custom step. Returns `error.InvalidArgument` for step 0. Caller owns the returned slice.

```zig
const r = try lo.rangeWithStepAlloc(i32, allocator, 0, 10, 3);
defer allocator.free(r);
// r == .{ 0, 3, 6, 9 }
```

---

## Tuple Helpers

### zip

Pair elements from two slices. Returns a lazy iterator. Stops at the shorter slice.

```zig
var it = lo.zip(i32, u8, &.{ 1, 2 }, &.{ 'a', 'b' });
it.next(); // .{ .a = 1, .b = 'a' }
```

### zipAlloc

Pair elements from two slices into an allocated slice. Caller owns the returned slice.

```zig
const pairs = try lo.zipAlloc(i32, u8, allocator, &.{ 1, 2 }, &.{ 'a', 'b' });
defer allocator.free(pairs);
```

### zipWith

Zip two slices with a transform function. Returns a lazy iterator.

```zig
var it = lo.zipWith(i32, i32, i32, &.{ 1, 2 }, &.{ 3, 4 }, addFn);
it.next(); // 4
it.next(); // 6
```

### unzip

Split a slice of pairs into two separate slices. Call `deinit(allocator)` to free.

```zig
const r = try lo.unzip(i32, u8, allocator, &pairs);
defer r.deinit(allocator);
```

### enumerate

Pair each element with its index. Returns a lazy iterator.

```zig
var it = lo.enumerate(i32, &.{ 10, 20, 30 });
it.next(); // .{ .a = 0, .b = 10 }
it.next(); // .{ .a = 1, .b = 20 }
```

---

## Type Helpers

### isNull

Returns true if the optional value is null.

```zig
const x: ?i32 = null;
lo.isNull(i32, x); // true
```

### isNotNull

Returns true if the optional value is non-null.

```zig
const x: ?i32 = 42;
lo.isNotNull(i32, x); // true
```

### unwrapOr

Unwrap an optional, returning the fallback if null.

```zig
const x: ?i32 = null;
lo.unwrapOr(i32, x, 99); // 99
```

### coalesce

Returns the first non-null value from a slice of optionals, or null if all are null.

```zig
const vals = [_]?i32{ null, null, 42, 7 };
lo.coalesce(i32, &vals); // 42
```

### empty

Returns the zero/default value for a type.

```zig
lo.empty(i32);  // 0
lo.empty(bool); // false
```

### isEmpty

Returns true if the value equals the zero/default for its type.

```zig
lo.isEmpty(i32, 0);   // true
lo.isEmpty(i32, 42);  // false
```

### isNotEmpty

Returns true if the value does not equal the zero/default for its type.

```zig
lo.isNotEmpty(i32, 42); // true
lo.isNotEmpty(i32, 0);  // false
```

### ternary

Selects one of two values based on a boolean condition. Both branches are evaluated eagerly.

```zig
lo.ternary(i32, true, 10, 20);  // 10
lo.ternary(i32, false, 10, 20); // 20
```

### toConst

Convert a mutable slice to a const slice.

```zig
var buf = [_]i32{ 1, 2, 3 };
const view = lo.toConst(i32, &buf);
```

---

## Types

These are type constructors and result types used by the functions above.

### Entry

Generic key-value pair for map utilities.

```zig
const e = lo.Entry(u32, u8){ .key = 1, .value = 'a' };
```

### Pair

Generic pair type used by zip operations.

```zig
const p = lo.Pair(i32, u8){ .a = 42, .b = 'z' };
```

### MinMax

Result type returned by `minMax()`, holding `.min_val` and `.max_val`.

### RangeError

Error set for `rangeWithStepAlloc`. Includes `InvalidArgument` for zero step.

### PartitionResult

Result type from `partition()` holding `.matching` and `.rest` slices. Call `deinit(allocator)` to free.

### UnzipResult

Result type from `unzip()` holding `.a` and `.b` slices. Call `deinit(allocator)` to free.

### AssocEntry

Generic key-value entry type used by `associate`.

```zig
const entry = lo.AssocEntry([]const u8, u32){ .key = "alice", .value = 30 };
```

### Iterator Types

The following iterator types are returned by their corresponding functions. They all implement a `next() -> ?T` method, and most provide a `collect(allocator) -> ![]T` method for eager evaluation.

| Iterator | Returned by |
|---|---|
| `MapIterator` | `map()` |
| `MapIndexIterator` | `mapIndex()` |
| `FilterIterator` | `filter()` |
| `RejectIterator` | `reject()` |
| `FlattenIterator` | `flatten()` |
| `FlatMapIterator` | `flatMap()` |
| `CompactIterator` | `compact()` |
| `ChunkIterator` | `chunk()` |
| `FilterMapIterator` | `filterMapIter()` |
| `WithoutIterator` | `without()` |
| `ScanIterator` | `scan()` |
| `WindowIterator` | `window()` |
| `InterleaveIterator` | `interleave()` |
| `TimesIterator` | `times()` |
| `KeyIterator` | `keys()` |
| `ValueIterator` | `values()` |
| `EntryIterator` | `entries()` |
| `ZipIterator` | `zip()` |
| `ZipWithIterator` | `zipWith()` |
| `EnumerateIterator` | `enumerate()` |
| `WordIterator` | `words()` |
| `StringChunkIterator` | `chunkString()` |

## License

See [LICENSE](LICENSE).
