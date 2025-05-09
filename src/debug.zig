//! zax.debug provides debug utilities
const std = @import("std");

/// simple replacement for std.debug.print("{s}\n", .{"INPUT"});
pub fn println(line: []const u8) void {
    std.debug.print("{s}\n", .{line});
}
