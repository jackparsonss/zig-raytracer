const std = @import("std");
const ztracy = @import("ztracy");

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
    var scene_path: []const u8 = "src/scenes/base.xml";
    var output_path: []const u8 = "output/image.ppm";

    if (args.len > 1) {
        scene_path = args[1];
    }

    if (args.len > 2) {
        if (std.mem.eql(u8, args[2], "png")) {
            output_format = renderer.OutputFormat.PNG;
        } else if (std.mem.eql(u8, args[2], "ppm")) {
            output_format = renderer.OutputFormat.PPM;
        } else {
            std.log.warn("Unknown output format: {s}. Defaulting to PPM.", .{args[2]});
        }
    }

    if (args.len > 3) {
        output_path = args[3];
    }

    var scene = try xml.parseXmlFile(scene_path, gpa);
    defer scene.world.deinit(gpa);

    const tracy_zone = ztracy.ZoneNC(@src(), "Compute Magic", 0x00_ff_00_00);
    defer tracy_zone.End();
    try renderer.write(&scene.camera, &scene.world, output_format, output_path);
}
