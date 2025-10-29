const std = @import("std");
const raytracer = @import("raytracer");

pub fn main() !void {
    try raytracer.run();
}
