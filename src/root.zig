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
        const fov = 20.0;

        const lookfrom: v.Point = .{ 13, 2, 3 };
        const lookat: v.Point = .{ 0, 0, 0 };
        const vup: v.Vec3 = .{ 0, 1, 0 };

        const defocus_angle = 0.6;
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

pub threadlocal var rand_state = std.Random.DefaultPrng.init(70);

pub fn run() !void {
    const gpa = std.heap.page_allocator;
    var world = h.HittableList.init();
    defer world.deinit(gpa);

    const rnd = rand_state.random();
    const ground_material: m.Material = .{ .lambertion = m.Lambertion{ .albedo = .{ 0.5, 0.5, 0.5 } } };
    try world.objects.append(gpa, .{ .sphere = h.Sphere.init(.{ 0, -1000, 0 }, 1000, ground_material) });

    var i: i32 = -11;
    while (i < 11) : (i += 1) {
        var j: i32 = -11;
        while (j < 11) : (j += 1) {
            const choose_mat = rnd.float(f64);
            const center: v.Point = .{
                @as(f64, @floatFromInt(i)) + 0.9 * rnd.float(f64),
                0.2,
                @as(f64, @floatFromInt(j)) + 0.9 * rnd.float(f64),
            };

            if (v.magnitude(center - v.Point{ 4, 0.2, 0 }) > 0.9) {
                if (choose_mat < 0.8) {
                    // diffuse
                    const albedo = v.random(rnd) * v.random(rnd);
                    const sphere_material: m.Material = .{ .lambertion = m.Lambertion{ .albedo = albedo } };
                    try world.objects.append(gpa, .{ .sphere = h.Sphere.init(center, 0.2, sphere_material) });
                } else if (choose_mat < 0.95) {
                    // metal
                    const albedo = v.randomRange(rnd, 0.5, 1);
                    const fuzz = rnd.float(f64) * 0.5;
                    const sphere_material: m.Material = .{ .metal = m.Metal.init(albedo, fuzz) };
                    try world.objects.append(gpa, .{ .sphere = h.Sphere.init(center, 0.2, sphere_material) });
                } else {
                    // glass
                    const sphere_material: m.Material = .{ .dialetric = m.Dialetric.init(1.5) };
                    try world.objects.append(gpa, .{ .sphere = h.Sphere.init(center, 0.2, sphere_material) });
                }
            }
        }
    }

    const material1: m.Material = .{ .dialetric = m.Dialetric.init(1.5) };
    try world.objects.append(gpa, .{ .sphere = h.Sphere.init(.{ 0, 1, 0 }, 1.0, material1) });

    const material2: m.Material = .{ .lambertion = m.Lambertion{ .albedo = .{ 0.4, 0.2, 0.1 } } };
    try world.objects.append(gpa, .{ .sphere = h.Sphere.init(.{ -4, 1, 0 }, 1.0, material2) });

    const material3: m.Material = .{ .metal = m.Metal.init(.{ 0.7, 0.6, 0.5 }, 0.0) };
    try world.objects.append(gpa, .{ .sphere = h.Sphere.init(.{ 4, 1, 0 }, 1.0, material3) });

    const f = PPMFile.init();
    try f.write(&world);
}
