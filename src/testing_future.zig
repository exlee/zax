//! [testing_future] is a module containing wrappers around the tests
//! that are failing today, but should be implemented in some undefined future.
//!
//! > Note:
//! >
//! > Those tests will be ran and has to be semantically correct.
//! > They represent known omissions or implementation gaps, but also signal
//! > future difficulties. But also can catch incomplete implementations or
//! > extra context providers.
//!
//! It should be drop-in replacement for the tests with the general
//! implementation being along the lines of:
//!
//! ```zig
//! fn expect(ok: bool) FutureTestOK!void {
//!   std.testing.expect(ok) catch return;
//!   return FutureTestOK;
//! }
//! ```
//!
//!
//!
//! Example usage:
//!
//! ```
//! const testing = zax.testing_future;
//! testing.expect(setVolume(11)) // Volume not yet supported!
//! ```
//!
//! This could be done through reflection, but having a simple
//! manual tests is easier for inspection.

pub const Error = error{
    /// Error raised when test marked as a future one is succeeding.
    FutureTestOK,
};

const std = @import("std");
const t = @import("std").testing;

/// This wrapper around `std.testing.expect` (with inverted outcome)
pub fn expect(ok: bool) .FutureTestOK!void {
    t.expect(ok) catch return;
    return .FutureTestOK;
}

/// This wrapper around `std.testing.expectError` (with inverted outcome)
///
/// Caveats:
/// It does complete inversion, so will catch both no error and error that's not
/// the targeted one.
pub fn expectError(err: anyerror, actual_error_union: anytype) .FutureTestOK!void {
    t.expectError(err, actual_error_union) catch return;
    return .FutureTestOK;
}

pub fn expectEqual(expected: anytype, actual: anytype) .FutureTestOK!void {
    t.expectEqual(expected, actual) catch return;
    return .FutureTestOK;
}

// Testing Helpers
const future_testing = @This();
const zax = .{
    .future_testing = future_testing,
};

test expect {
    // Somewhere in the def files...
    const MAX_VOLUME = 10;

    // Amplifier implementation
    const Amplifier = struct {
        volume: u8 = 0,
        fn setVolume(this: *@This(), volume: u8) bool {
            if (volume > MAX_VOLUME) {
                return false;
            } else {
                this.volume = volume;
                return true;
            }
        }
    };

    var amplifier = Amplifier{};
    {
        const testing = std.testing;
        testing.expect(amplifier.setVolume(10));
        testing.expect(!amplifier.setVolume(100));
    }

    {
        const testing = zax.future_testing;
        testing.expect(amplifier.setVolume(11));
    }
}
