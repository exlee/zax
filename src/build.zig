//! Build contains helpers for working with BuildZig

const std = @import("std");
const comptimePrint = std.fmt.comptimePrint;

/// Simple Module builder.
/// It allows quick creation of modules in Build.
const Simple = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    build: *std.Build,

    fn mod(this: *const Simple, comptime name: []const u8) *std.Build.Module {
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
fn addImportToAllModules(b: *std.Build, name: []const u8, mod: *std.Build.Module) void {
    for (b.modules.values()) |m| {
        if (m == mod) {
            continue;
        }
        m.addImport(name, mod);
    }
}
