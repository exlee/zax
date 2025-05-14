const std = @import("std");

/// zax build helpers
pub const helpers = @import("src/build_helpers.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const simple = helpers.Simple{
        .target = target,
        .optimize = optimize,
        .build = b,
    };

    const zax = b.addModule("zax", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    _ = b.addModule("bzax", .{
        .root_source_file = b.path("src/build_helpers.zig.zig"),
        .target = target,
        .optimize = optimize,
    });

    const generators_mod = simple.mod("generators");

    const lib_unit_tests = b.addTest(.{
        .root_module = zax,
    });

    const docs = b.addInstallDirectory(.{
        .source_dir = lib_unit_tests.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "../docs",
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    helpers.easyTest(test_step, "generators", generators_mod, .{});
    test_step.dependOn(&run_lib_unit_tests.step);
    const docs_step = b.step("docs", "Build Docs");

    const check_step = b.step("check", "LSP Check");
    check_step.dependOn(test_step);
    docs_step.dependOn(&docs.step);
}
