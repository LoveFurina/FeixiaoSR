const std = @import("std");
const builtin = @import("builtin");
const network = @import("network.zig");
const handlers = @import("handlers.zig");

pub const std_options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        else => .info,
    },
};

pub fn main() !void {
    try network.listen();
}
