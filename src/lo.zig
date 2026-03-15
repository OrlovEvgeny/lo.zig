/// lo.zig — Generic utility library for Zig.
///
/// Provides helpers for slices, hash maps, math, strings, and tuples.
/// Zero hidden allocations: functions that need memory take an Allocator.
/// Iterator-first: most transformations return lazy iterators.
///
/// ```zig
/// const lo = @import("lo");
///
/// const result = lo.sum(i32, &.{ 1, 2, 3, 4 }); // 10
/// const first = lo.first(i32, &.{ 10, 20, 30 }); // 10
/// ```
pub const types = @import("types.zig");
pub const math = @import("math.zig");
pub const slice = @import("slice.zig");
pub const hash_map = @import("map.zig");
pub const strings = @import("strings.zig");
pub const tuples = @import("tuples.zig");

// Re-export types.zig
pub const isNull = types.isNull;
pub const isNotNull = types.isNotNull;
pub const unwrapOr = types.unwrapOr;
pub const coalesce = types.coalesce;
pub const empty = types.empty;
pub const isEmpty = types.isEmpty;
pub const toConst = types.toConst;
pub const isNotEmpty = types.isNotEmpty;
pub const ternary = types.ternary;

// Re-export math.zig
pub const sum = math.sum;
pub const sumBy = math.sumBy;
pub const product = math.product;
pub const productBy = math.productBy;
pub const mean = math.mean;
pub const meanBy = math.meanBy;
pub const min = math.min;
pub const max = math.max;
pub const minBy = math.minBy;
pub const maxBy = math.maxBy;
pub const minMax = math.minMax;
pub const MinMax = math.MinMax;
pub const clamp = math.clamp;
pub const rangeAlloc = math.rangeAlloc;
pub const rangeWithStepAlloc = math.rangeWithStepAlloc;
pub const RangeError = math.RangeError;
pub const mode = math.mode;
pub const median = math.median;
pub const variance = math.variance;
pub const stddev = math.stddev;
pub const percentile = math.percentile;
pub const inRange = math.inRange;
pub const lerp = math.lerp;
pub const remap = math.remap;
pub const cumSum = math.cumSum;
pub const cumProd = math.cumProd;

// Re-export slice.zig
pub const first = slice.first;
pub const last = slice.last;
pub const nth = slice.nth;
pub const contains = slice.contains;
pub const containsBy = slice.containsBy;
pub const indexOf = slice.indexOf;
pub const lastIndexOf = slice.lastIndexOf;
pub const sample = slice.sample;
pub const samples = slice.samples;
pub const drop = slice.drop;
pub const dropRight = slice.dropRight;
pub const dropWhile = slice.dropWhile;
pub const dropRightWhile = slice.dropRightWhile;
pub const take = slice.take;
pub const takeRight = slice.takeRight;
pub const takeWhile = slice.takeWhile;
pub const takeRightWhile = slice.takeRightWhile;
pub const initial = slice.initial;
pub const tail = slice.tail;
pub const find = slice.find;
pub const findIndex = slice.findIndex;
pub const findLast = slice.findLast;
pub const findLastIndex = slice.findLastIndex;
pub const every = slice.every;
pub const some = slice.some;
pub const none = slice.none;
pub const count = slice.count;
pub const countValues = slice.countValues;
pub const reduce = slice.reduce;
pub const reduceRight = slice.reduceRight;
pub const forEach = slice.forEach;
pub const forEachIndex = slice.forEachIndex;
pub const MapIterator = slice.MapIterator;
pub const map = slice.map;
pub const mapAlloc = slice.mapAlloc;
pub const MapIndexIterator = slice.MapIndexIterator;
pub const mapIndex = slice.mapIndex;
pub const FilterIterator = slice.FilterIterator;
pub const filter = slice.filter;
pub const filterAlloc = slice.filterAlloc;
pub const RejectIterator = slice.RejectIterator;
pub const reject = slice.reject;
pub const rejectAlloc = slice.rejectAlloc;
pub const FlattenIterator = slice.FlattenIterator;
pub const flatten = slice.flatten;
pub const flattenAlloc = slice.flattenAlloc;
pub const FlatMapIterator = slice.FlatMapIterator;
pub const flatMap = slice.flatMap;
pub const flatMapAlloc = slice.flatMapAlloc;
pub const CompactIterator = slice.CompactIterator;
pub const compact = slice.compact;
pub const compactAlloc = slice.compactAlloc;
pub const ChunkIterator = slice.ChunkIterator;
pub const chunk = slice.chunk;
pub const WithoutIterator = slice.WithoutIterator;
pub const without = slice.without;
pub const uniq = slice.uniq;
pub const uniqBy = slice.uniqBy;
pub const groupBy = slice.groupBy;
pub const PartitionResult = slice.PartitionResult;
pub const partition = slice.partition;
pub const intersect = slice.intersect;
pub const union_ = slice.union_;
pub const difference = slice.difference;
pub const symmetricDifference = slice.symmetricDifference;
pub const reverse = slice.reverse;
pub const shuffle = slice.shuffle;
pub const fill = slice.fill;
pub const fillRange = slice.fillRange;
pub const repeat = slice.repeat;
pub const repeatBy = slice.repeatBy;
pub const isSorted = slice.isSorted;
pub const equal = slice.equal;
pub const sortBy = slice.sortBy;
pub const sortByAlloc = slice.sortByAlloc;
pub const concat = slice.concat;
pub const splice = slice.splice;
pub const AssocEntry = slice.AssocEntry;
pub const keyBy = slice.keyBy;
pub const associate = slice.associate;
pub const countBy = slice.countBy;
pub const findDuplicates = slice.findDuplicates;
pub const findUniques = slice.findUniques;

// Re-export map.zig
pub const Entry = hash_map.Entry;
pub const KeyIterator = hash_map.KeyIterator;
pub const ValueIterator = hash_map.ValueIterator;
pub const EntryIterator = hash_map.EntryIterator;
pub const keys = hash_map.keys;
pub const keysAlloc = hash_map.keysAlloc;
pub const values = hash_map.values;
pub const valuesAlloc = hash_map.valuesAlloc;
pub const entries = hash_map.entries;
pub const entriesAlloc = hash_map.entriesAlloc;
pub const fromEntries = hash_map.fromEntries;
pub const mapKeys = hash_map.mapKeys;
pub const mapValues = hash_map.mapValues;
pub const filterMap = hash_map.filterMap;
pub const pickKeys = hash_map.pickKeys;
pub const omitKeys = hash_map.omitKeys;
pub const invert = hash_map.invert;
pub const merge = hash_map.merge;
pub const valueOr = hash_map.valueOr;
pub const hasKey = hash_map.hasKey;
pub const mapCount = hash_map.mapCount;
pub const mapEntries = hash_map.mapEntries;
pub const mapToSlice = hash_map.mapToSlice;
pub const filterKeys = hash_map.filterKeys;
pub const filterValues = hash_map.filterValues;
pub const assign = hash_map.assign;

// Re-export strings.zig
pub const WordIterator = strings.WordIterator;
pub const words = strings.words;
pub const wordsAlloc = strings.wordsAlloc;
pub const camelCase = strings.camelCase;
pub const pascalCase = strings.pascalCase;
pub const snakeCase = strings.snakeCase;
pub const kebabCase = strings.kebabCase;
pub const capitalize = strings.capitalize;
pub const ellipsis = strings.ellipsis;
pub const strRepeat = strings.strRepeat;
pub const padLeft = strings.padLeft;
pub const padRight = strings.padRight;
pub const runeLength = strings.runeLength;
pub const randomString = strings.randomString;
pub const trim = strings.trim;
pub const trimStart = strings.trimStart;
pub const trimEnd = strings.trimEnd;
pub const startsWith = strings.startsWith;
pub const endsWith = strings.endsWith;
pub const includes = strings.includes;
pub const toLower = strings.toLower;
pub const toUpper = strings.toUpper;
pub const lowerFirst = strings.lowerFirst;
pub const substr = strings.substr;
pub const split = strings.split;
pub const splitAlloc = strings.splitAlloc;
pub const join = strings.join;
pub const replace = strings.replace;
pub const replaceAll = strings.replaceAll;
pub const StringChunkIterator = strings.StringChunkIterator;
pub const chunkString = strings.chunkString;

// Re-export tuples.zig
pub const Pair = tuples.Pair;
pub const ZipIterator = tuples.ZipIterator;
pub const zip = tuples.zip;
pub const zipAlloc = tuples.zipAlloc;
pub const UnzipResult = tuples.UnzipResult;
pub const unzip = tuples.unzip;
pub const ZipWithIterator = tuples.ZipWithIterator;
pub const zipWith = tuples.zipWith;
pub const EnumerateIterator = tuples.EnumerateIterator;
pub const enumerate = tuples.enumerate;

test {
    @import("std").testing.refAllDecls(@This());
}
