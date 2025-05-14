const std = @import("std");

const MAX_PARSE = std.math.maxInt(u31);
/// MakeUnit creates parseable an Unit type based on provided enum
///
/// The template for such unit is:
/// ```
/// struct SomeUnit{
///   inner_val: i32,
///   unit: SomeUnitEnum,
///   pub fn parse(input: []const u8) SomeUnit { ... }
///   pub fn value(this: SomeUnit) { ... }
///
/// }
/// ```
///
/// SomeUnitEnum should contain list of keywords that could be used for parsing.
/// Keywords are checked with case ignored.
///
/// Beside keywords `mod(this: SomeUnitEnum) anytype` has to be provided - it should return multiplier
/// for unit value
///
pub fn Unit(unitEnum: @TypeOf(enum {}), container_type: type, default_unit: unitEnum, default_count: container_type) type {
    return struct {
        const This = @This();
        const mod = &unitEnum.mod;
        inner_val: container_type = default_count,
        unit: unitEnum = default_unit,

        pub fn value(t: *This) container_type {
            const result: container_type = t.unit.mod(t.inner_val);
            return result;
        }
        pub fn parse(input: []const u8) !This {
            inline for (@typeInfo(unitEnum).@"enum".fields) |field| {
                const unit = field.name;
                if (std.ascii.endsWithIgnoreCase(input, unit)) {
                    const rest = input[0 .. input.len - unit.len];
                    const trimmed = std.mem.trim(u8, rest, &std.ascii.whitespace);
                    const inner_val = try std.fmt.parseInt(container_type, trimmed, 10);

                    return .{ .inner_val = inner_val, .unit = @enumFromInt(field.value) };
                }
            }

            return This{
                .inner_val = try std.fmt.parseInt(container_type, input, 10),
            };
        }
    };
}

test Unit {
    const MemoryEnum = enum(u8) {
        gib,
        mib,
        kib,
        gb,
        mb,
        kb,
        b,

        fn mod(t: @This(), value: u64) u64 {
            const EE: u64 = 1024;
            const SI: u64 = 1000;
            return value * switch (t) {
                .gib => EE * EE * EE,
                .mib => EE * EE,
                .kib => EE,
                .gb => SI * SI * SI,
                .mb => SI * SI,
                .kb => SI,
                .b => 1,
            };
        }
    };
    const Memory = Unit(MemoryEnum, u32, .kb, 50);
    var parsed = try Memory.parse("3 mib");
    try std.testing.expectEqual(3_145_728, parsed.value());
}

test "negative unit works" {
    const TempEnum = enum {
        C,
        K,
        fn mod(this: @This(), value: i16) i16 {
            return switch (this) {
                .K => value,
                .C => 273 + value,
            };
        }
    };
    const Temperature = Unit(TempEnum, i16, .C, 0);
    var parsed = try Temperature.parse("-5C");
    try std.testing.expectEqual(268, parsed.value());
}
