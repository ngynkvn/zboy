const std = @import("std");
const specs = @import("system/specs.zig");
const testing = std.testing;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "system" {
    _ = specs;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
