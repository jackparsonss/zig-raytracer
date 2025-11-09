const std = @import("std");
const vec = @import("vector.zig");
const h = @import("hittable.zig");
const Ray = @import("ray.zig").Ray;
const Interval = @import("interval.zig").Interval;

pub threadlocal var rand_state = std.Random.DefaultPrng.init(70);

const pi: f32 = 3.1415926535897932385;
fn degrees_to_radians(degrees: f32) f32 {
    return degrees * pi / 180.0;
}

pub const Camera = struct {
    aspect_ratio: f32,
    image_width: u32,
    image_height: u32,
    center: vec.Point,
    pixel00_loc: vec.Point,
    samples_per_pixel: u32,
    pixel_samples_scale: f32,
    pixel_delta_u: vec.Vec3f32,
    pixel_delta_v: vec.Vec3f32,
    max_depth: u32,
    fov: f32,
    lookat: vec.Point,
    lookfrom: vec.Point,
    vup: vec.Vec3f32,
    defocus_angle: f32,
    defocus_dist: f32,
    defocus_disk_u: vec.Vec3f32,
    defocus_disk_v: vec.Vec3f32,

    pub fn init(aspect_ratio: f32, image_width: u32, samples_per_pixel: u32, max_depth: u32, fov: f32, lookat: vec.Point, lookfrom: vec.Point, vup: vec.Vec3f32, defocus_angle: f32, defocus_dist: f32) Camera {
        var image_height: u32 = @intFromFloat(@as(f32, @floatFromInt(image_width)) / aspect_ratio);
        image_height = if (image_height < 1) 1 else image_height;

        const center = lookfrom;
        const theta = degrees_to_radians(fov);
        const hval = @tan(theta / 2.0);

        const viewport_height = 2 * hval * defocus_dist;
        const viewport_width = viewport_height * (@as(f32, @floatFromInt(image_width)) / @as(f32, @floatFromInt(image_height)));

        const w = lookfrom.sub(lookat).unitVector();
        const u = vup.cross(w).unitVector();
        const v = w.cross(u);

        const viewport_u = u.scale(viewport_width);
        const viewport_v = v.negate().scale(viewport_height);

        const pixel_delta_u = viewport_u.div(@floatFromInt(image_width));
        const pixel_delta_v = viewport_v.div(@floatFromInt(image_height));

        const viewport_upper_left = center.sub(w.scale(defocus_dist)).sub(viewport_u.div(2)).sub(viewport_v.div(2));
        const pixel00_loc = viewport_upper_left.add(pixel_delta_u.add(pixel_delta_v).scale(0.5));

        const defocus_radius = defocus_dist * @tan(degrees_to_radians(defocus_angle / 2.0));
        const pixel_samples_scale = 1.0 / @as(f32, @floatFromInt(samples_per_pixel));

        return .{
            .aspect_ratio = aspect_ratio,
            .image_width = image_width,
            .image_height = image_height,
            .center = center,
            .pixel00_loc = pixel00_loc,
            .pixel_delta_u = pixel_delta_u,
            .pixel_delta_v = pixel_delta_v,
            .samples_per_pixel = samples_per_pixel,
            .pixel_samples_scale = pixel_samples_scale,
            .max_depth = max_depth,
            .fov = fov,
            .lookat = lookat,
            .lookfrom = lookfrom,
            .vup = vup,
            .defocus_angle = defocus_angle,
            .defocus_dist = defocus_dist,
            .defocus_disk_u = u.scale(defocus_radius),
            .defocus_disk_v = v.scale(defocus_radius),
        };
    }

    pub fn render(self: Camera, world: *h.HittableList, writer: *std.Io.Writer) !void {
        try writer.print("P3\n{} {}\n255\n", .{ self.image_width, self.image_height });
        for (0..self.image_height) |j| {
            const percentage = @as(u32, @intCast(j)) * 100 / self.image_height;
            std.debug.print("\rProgress: {}% ", .{percentage});
            for (0..self.image_width) |i| {
                var pixel_color = vec.Color.init(0, 0, 0);
                for (0..self.samples_per_pixel) |_| {
                    const r = self.get_ray(i, j);
                    pixel_color = pixel_color.add(ray_color(r, self.max_depth, world));
                }
                pixel_color = pixel_color.scale(self.pixel_samples_scale);
                try vec.write_color(writer, pixel_color);
            }
        }

        std.debug.print("\rDone.                     \n", .{});
        try writer.flush();
    }

    pub fn get_ray(self: Camera, i: usize, j: usize) Ray {
        const offset = Camera.sample_square();
        const if32: f32 = @floatFromInt(i);
        const jf32: f32 = @floatFromInt(j);
        const uvec = self.pixel_delta_u.scale(if32 + offset.x());
        const vvec = self.pixel_delta_v.scale(jf32 + offset.y());
        const pixel_sample = self.pixel00_loc.add(uvec).add(vvec);

        const ray_origin = if (self.defocus_angle <= 0) self.center else self.defocus_sample_disk();
        const ray_direction = pixel_sample.sub(self.center);

        return Ray{ .origin = ray_origin, .direction = ray_direction };
    }

    fn defocus_sample_disk(self: Camera) vec.Vec3f32 {
        const rand = rand_state.random();
        const p = vec.Vec3f32.randomInUnitDisk(rand);
        return self.center.add(self.defocus_disk_u.scale(p.x()).add(self.defocus_disk_v.scale(p.y())));
    }

    fn sample_square() vec.Vec3f32 {
        const rand = rand_state.random();
        return vec.Vec3f32.init(rand.float(f32) - 0.5, rand.float(f32) - 0.5, 0);
    }

    pub fn ray_color(ray: Ray, depth: u32, world: *const h.HittableList) vec.Color {
        if (depth <= 0) {
            return vec.Color.init(0, 0, 0);
        }

        var rec: h.HitRecord = undefined;
        if (world.hit(ray, Interval.init(0.001, std.math.inf(f32)), &rec)) {
            var scattered: Ray = undefined;
            var attenuation: vec.Color = undefined;
            if (rec.material.scatter(ray, &rec, &attenuation, &scattered)) {
                return attenuation.mul(ray_color(scattered, depth - 1, world));
            }
            return vec.Color.init(0, 0, 0);
        }

        const unit_direction = ray.direction.unitVector();
        const a: f32 = 0.5 * (unit_direction.y() + 1.0);
        return vec.Color.init(1, 1, 1).scale(1.0 - a).add(vec.Color.init(0.5, 0.7, 1.0).scale(a));
    }
};
