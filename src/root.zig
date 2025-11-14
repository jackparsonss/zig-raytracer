const std = @import("std");
const v = @import("vector.zig");
const Ray = @import("ray.zig").Ray;
const h = @import("hittable.zig");
const m = @import("material.zig");
const Interval = @import("interval.zig").Interval;
const Camera = @import("camera.zig").Camera;
const renderer = @import("renderer.zig");
const xml = @import("xml.zig");

pub threadlocal var rand_state = std.Random.DefaultPrng.init(70);

pub fn run() !void {
    const gpa = std.heap.page_allocator;
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    var output_format = renderer.OutputFormat.PPM;

    if (args.len > 1) {
        if (std.mem.eql(u8, args[1], "png")) {
            output_format = renderer.OutputFormat.PNG;
        } else if (std.mem.eql(u8, args[1], "ppm")) {
            output_format = renderer.OutputFormat.PPM;
        } else {
            std.log.warn("Unknown output format: {s}. Defaulting to PPM.", .{args[1]});
        }
    }

    var scene = try xml.parseXmlFile("src/scenes/base.xml", gpa);
    defer scene.world.deinit(gpa);

    try renderer.write(&scene.camera, &scene.world, output_format);
}
