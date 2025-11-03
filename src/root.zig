const std = @import("std");
const v = @import("vector.zig");
const Ray = @import("ray.zig").Ray;
const h = @import("hittable.zig");
const Interval = @import("interval.zig").Interval;
const Camera = @import("camera.zig").Camera;

pub const PPMFile = struct {
    camera: Camera,

    pub fn init() PPMFile {
        const aspect_ratio: f32 = 16.0 / 9.0;
        const image_width: u32 = 400;

        const camera = Camera.init(aspect_ratio, image_width);
        return PPMFile{ .camera = camera };
    }

    pub fn write(self: PPMFile, world: *h.HittableList) !void {
        const file = try std.fs.cwd().createFile("output/image.ppm", .{ .truncate = true });
        defer file.close();

        var write_buffer: [4096]u8 = undefined;
        var file_writer = file.writer(&write_buffer);
        const writer: *std.Io.Writer = &file_writer.interface;

        try self.camera.render(world, writer);
    }
};

pub fn run() !void {
    const gpa = std.heap.page_allocator;
    var world = h.HittableList.init();
    defer world.deinit(gpa);

    try world.add(.{ .sphere = h.Sphere.init(v.Point.init(0, 0, -1), 0.5) }, gpa);
    try world.add(.{ .sphere = h.Sphere.init(v.Point.init(0, -100.5, -1), 100) }, gpa);

    const f = PPMFile.init();
    try f.write(&world);
}
