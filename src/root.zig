//! zax is Zig utils by Alexander.
//!
//! It contains mostly small utilities and helpers.
//! What's in (right now):
//! - testing_future - test helpers for tests that fail today,
//!   but shouldn't in the future
//! - debug - container for debug utils
//! - build_helpers - helpers for build.zig
const std = @import("std");

pub const debug = @import("debug.zig");
pub const testing_future = @import("testing_future.zig");
pub const build_helpers = @import("build_helpers.zig");
