const std = @import("std");
const v = @import("vector.zig");
const Ray = @import("ray.zig").Ray;
const h = @import("hittable.zig");
const m = @import("material.zig");
const Interval = @import("interval.zig").Interval;
const Camera = @import("camera.zig").Camera;

pub const PPMFile = struct {
    camera: Camera,

    pub fn init() PPMFile {
        const aspect_ratio = 16.0 / 9.0;
        const image_width = 400;
        const samples_per_pixel = 10;
        const max_depth = 10;
        const fov = 90.0;

        const lookfrom = v.Point.init(0, 0, 0);
        const lookat = v.Point.init(0, 0, -1);
        const vup = v.Vec3f32.init(0, 1, 0);

        const defocus_angle = 0.0;
        const defocus_dist = 10.0;

        const camera = Camera.init(
            aspect_ratio,
            image_width,
            samples_per_pixel,
            max_depth,
            fov,
            lookat,
            lookfrom,
            vup,
            defocus_angle,
            defocus_dist,
        );
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

    const material_ground: m.Material = .{ .lambertion = m.Lambertion{ .albedo = v.Color.init(0.8, 0.8, 0.0) } };
    const material_center: m.Material = .{ .lambertion = m.Lambertion{ .albedo = v.Color.init(0.1, 0.2, 0.5) } };
    const material_left: m.Material = .{ .dialetric = m.Dialetric.init(1.5) };
    const material_bubble: m.Material = .{ .dialetric = m.Dialetric.init(1.0 / 1.5) };
    const material_right: m.Material = .{ .metal = m.Metal.init(v.Color.init(0.8, 0.6, 0.2), 1.0) };

    try world.add(.{ .sphere = h.Sphere.init(v.Point.init(0.0, -100.5, -1.0), 100, material_ground) }, gpa);
    try world.add(.{ .sphere = h.Sphere.init(v.Point.init(0.0, 0.0, -1.2), 0.5, material_center) }, gpa);
    try world.add(.{ .sphere = h.Sphere.init(v.Point.init(-1.0, 0.0, -1.0), 0.5, material_left) }, gpa);
    try world.add(.{ .sphere = h.Sphere.init(v.Point.init(-1.0, 0.0, -1.0), 0.4, material_bubble) }, gpa);
    try world.add(.{ .sphere = h.Sphere.init(v.Point.init(1.0, 0.0, -1.0), 0.5, material_right) }, gpa);

    const f = PPMFile.init();
    try f.write(&world);
}
