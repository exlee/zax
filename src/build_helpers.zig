//! Build contains helpers for working with BuildZig
//!
//! In order to use those in your build.zig use following
//! code.
//!
//! ```
//! const zax = b.dependency("zax", .{});
//! // Use zax_mod if you want to add import to other modules.
//!
//! const zax_mod = zax.module("zax");
//!
//! _ = b.addModule("zax", .{
//!     .root_source_file = zax_mod.root_source_file,
//! });
//! const zb = @import("zax").helpers;
//! ```
//!

const std = @import("std");
const comptimePrint = std.fmt.comptimePrint;

/// Simple Module builder.
/// It allows quick creation of modules in Build.
/// Prefill with base data (optimize/target/build) first.
pub const Simple = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    build: *std.Build,

    /// Creates *Module out of name, e.g.
    /// `file_mod = S.mod("file")` returns module using src/file.zig
    pub fn mod(this: *const Simple, comptime name: []const u8) *std.Build.Module {
        return this.build.addModule(name, .{
            .root_source_file = this.build.path(
                comptimePrint("src/{s}.zig", .{name}),
            ),
            .target = this.target,
            .optimize = this.optimize,
        });
    }
};

/// Adds import to all defined modules (but not themselves)
pub fn addImportToAllModules(
    b: *std.Build,
    name: []const u8,
    mod: *std.Build.Module,
) void {
    for (b.modules.values()) |m| {
        if (m == mod) {
            continue;
        }
        m.addImport(name, mod);
    }
}
