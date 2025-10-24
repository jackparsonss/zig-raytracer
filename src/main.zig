const std = @import("std");
const raytracer = @import("raytracer");

pub fn main() !void {
    std.debug.print("HI\n", .{});
    try raytracer.run();
}
