//! Build contains helpers for working with Build.zig
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
    pub inline fn mod(this: *const Simple, comptime name: []const u8) *std.Build.Module {
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

pub const TestOption = struct {
    /// Should it have special {test-name}-debug steps
    /// that is a lldb wrap over test?
    gen_lldb_tests: bool = true,
    /// Should it build test module binary in $INSTALL_PATH/tests/{test-name}
    /// (For debugging/profiling/etc.)
    gen_test_binaries: bool = true,
    /// Filter to use for steps.
    /// Use std.Build.option to easily specify one
    test_filters: ?[]const []const u8,
};

/// Easily add testing helpers/binaries/lldb wraps
///
/// Usage:
///
/// Either directly, e.g.
/// ```
/// helpers.easyTest(test_step, "adder", adder_mod, .{})
/// ```
///
/// or in inline loop:
///
/// ```
/// inline for (
///    .{
///        .{ "test_a", a_mod },
///        .{ "test_b", b_mod },
///        .{ "test_c", c_mod },
///    },
/// ) |pair| {
///    const name, const mod = pair;
///    helpers.easyTest(test_step, name, mod, .{});
/// }
/// ```
pub inline fn easyTest(
    test_step: *std.Build.Step,
    comptime test_name: []const u8,
    mod: *std.Build.Module,
    opts: TestOption,
) void {
    const b = test_step.owner;

    const local_test_step = b.step(
        comptimePrint("{s}-test", .{test_name}),
        comptimePrint("Run {s} unit tests", .{test_name}),
    );

    const unit_test = b.addTest(.{
        .root_module = mod,
        .name = test_name,
    });
    const test_artifact = b.addRunArtifact(unit_test);

    if (opts.test_filters) |f| {
        unit_test.filters = f;
    }

    // Probaby could be parametrized
    if (opts.gen_lldb_tests) {
        const lldb = b.addSystemCommand(&.{
            "lldb",
            "-o",
            "run",
        });
        const local_lldb_step = b.step(
            comptimePrint("{s}-debug", .{test_name}),
            comptimePrint("Debug {s} tests under lldb", .{test_name}),
        );

        local_lldb_step.dependOn(&lldb.step);
        lldb.addArtifactArg(unit_test);
    }

    if (opts.gen_test_binaries) {
        const test_install_destination: [:0]const u8 = std.fmt.comptimePrint("tests/{s}", .{test_name});
        const install_artifact = b.addInstallArtifact(unit_test, .{ .dest_sub_path = test_install_destination });

        b.getInstallStep().dependOn(&install_artifact.step);
    }

    test_step.dependOn(&test_artifact.step);
    local_test_step.dependOn(&test_artifact.step);
}
