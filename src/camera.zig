const std = @import("std");
const v = @import("vector.zig");
const h = @import("hittable.zig");
const Ray = @import("ray.zig").Ray;
const Interval = @import("interval.zig").Interval;

pub threadlocal var rand_state = std.Random.DefaultPrng.init(70);

pub const Camera = struct {
    aspect_ratio: f32,
    focal_length: f32,
    image_width: u32,
    image_height: u32,
    center: v.Point,
    pixel00_loc: v.Point,
    samples_per_pixel: u32,
    pixel_samples_scale: f32,
    pixel_delta_u: v.Vec3f32,
    pixel_delta_v: v.Vec3f32,
    max_depth: u32,

    pub fn init(aspect_ratio: f32, image_width: u32, samples_per_pixel: u32, max_depth: u32) Camera {
        var image_height: u32 = @intFromFloat(@as(f32, @floatFromInt(image_width)) / aspect_ratio);
        image_height = if (image_height < 1) 1 else image_height;

        const viewport_height: f32 = 2.0;
        const viewport_width = viewport_height * (@as(f32, @floatFromInt(image_width)) / @as(f32, @floatFromInt(image_height)));

        const focal_length = 1.0;
        const center = v.Point.init(0, 0, 0);

        const viewport_u = v.Vec3f32.init(viewport_width, 0, 0);
        const viewport_v = v.Vec3f32.init(0, -viewport_height, 0);

        const pixel_delta_u = viewport_u.div(@floatFromInt(image_width));
        const pixel_delta_v = viewport_v.div(@floatFromInt(image_height));

        const viewport_upper_left = center.sub(v.Vec3f32.init(0, 0, focal_length)).sub(viewport_u.div(2)).sub(viewport_v.div(2));
        const pixel00_loc = viewport_upper_left.add(pixel_delta_u.add(pixel_delta_v).scale(0.5));

        const pixel_samples_scale = 1.0 / @as(f32, @floatFromInt(samples_per_pixel));

        return .{
            .aspect_ratio = aspect_ratio,
            .image_width = image_width,
            .image_height = image_height,
            .focal_length = focal_length,
            .center = center,
            .pixel00_loc = pixel00_loc,
            .pixel_delta_u = pixel_delta_u,
            .pixel_delta_v = pixel_delta_v,
            .samples_per_pixel = samples_per_pixel,
            .pixel_samples_scale = pixel_samples_scale,
            .max_depth = max_depth,
        };
    }

    pub fn render(self: Camera, world: *h.HittableList, writer: *std.Io.Writer) !void {
        try writer.print("P3\n{} {}\n255\n", .{ self.image_width, self.image_height });
        for (0..self.image_height) |j| {
            const percentage = @as(u32, @intCast(j)) * 100 / self.image_height;
            std.debug.print("\rProgress: {}% ", .{percentage});
            for (0..self.image_width) |i| {
                var pixel_color = v.Color.init(0, 0, 0);
                for (0..self.samples_per_pixel) |_| {
                    const r = self.get_ray(i, j);
                    pixel_color = pixel_color.add(ray_color(r, self.max_depth, world));
                }
                pixel_color = pixel_color.scale(self.pixel_samples_scale);
                try v.write_color(writer, pixel_color);
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
        const ray_direction = pixel_sample.sub(self.center);

        return Ray{ .origin = self.center, .direction = ray_direction };
    }

    fn sample_square() v.Vec3f32 {
        const rand = rand_state.random();
        return v.Vec3f32.init(rand.float(f32) - 0.5, rand.float(f32) - 0.5, 0);
    }

    pub fn ray_color(ray: Ray, depth: u32, world: *const h.HittableList) v.Color {
        if (depth <= 0) {
            return v.Color.init(0, 0, 0);
        }

        var rec: h.HitRecord = undefined;
        const rand = rand_state.random();
        if (world.hit(ray, Interval.init(0.001, std.math.inf(f32)), &rec)) {
            const direction = rec.normal.add(v.Vec3f32.randomUnitVector(rand));
            return ray_color(Ray{ .origin = rec.p, .direction = direction }, depth - 1, world).scale(0.3);
        }

        const unit_direction = ray.direction.unitVector();
        const a: f32 = 0.5 * (unit_direction.y() + 1.0);
        return v.Color.init(1, 1, 1).scale(1.0 - a).add(v.Color.init(0.5, 0.7, 1.0).scale(a));
    }
};
