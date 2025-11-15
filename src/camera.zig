const std = @import("std");
const ztracy = @import("ztracy");
const vec = @import("vector.zig");
const h = @import("hittable.zig");
const Ray = @import("ray.zig").Ray;
const Interval = @import("interval.zig").Interval;

pub threadlocal var rand_state = std.Random.DefaultPrng.init(70);

pub const Camera = struct {
    aspect_ratio: f64,
    image_width: u32,
    image_height: u32,
    center: vec.Point,
    pixel00_loc: vec.Point,
    samples_per_pixel: u32,
    pixel_samples_scale: f64,
    pixel_delta_u: vec.Vec3,
    pixel_delta_v: vec.Vec3,
    max_depth: u32,
    fov: f64,
    lookat: vec.Point,
    lookfrom: vec.Point,
    vup: vec.Vec3,
    defocus_angle: f64,
    defocus_dist: f64,
    defocus_disk_u: vec.Vec3,
    defocus_disk_v: vec.Vec3,

    pub fn init(aspect_ratio: f64, image_width: u32, samples_per_pixel: u32, max_depth: u32, fov: f64, lookat: vec.Point, lookfrom: vec.Point, vup: vec.Vec3, defocus_angle: f64, defocus_dist: f64) Camera {
        var image_height: u32 = @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio);
        image_height = if (image_height < 1) 1 else image_height;

        const center = lookfrom;
        const theta = std.math.degreesToRadians(fov);
        const hval = @tan(theta / 2.0);

        const viewport_height = 2 * hval * defocus_dist;
        const viewport_width = viewport_height * (@as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height)));

        const w = vec.unit(lookfrom - lookat);
        const u = vec.unit(vec.cross(vup, w));
        const v = vec.cross(w, u);

        const viewport_u = u * vec.splat(viewport_width);
        const viewport_v = -v * vec.splat(viewport_height);

        const pixel_delta_u = viewport_u / vec.splat(@as(f64, @floatFromInt(image_width)));
        const pixel_delta_v = viewport_v / vec.splat(@as(f64, @floatFromInt(image_height)));

        const viewport_upper_left = center - w * vec.splat(defocus_dist) - viewport_u / vec.splat(2) - viewport_v / vec.splat(2);
        const pixel00_loc = viewport_upper_left + (pixel_delta_u + pixel_delta_v) * vec.splat(0.5);

        const defocus_radius = defocus_dist * @tan(std.math.degreesToRadians(defocus_angle / 2.0));
        const pixel_samples_scale = 1.0 / @as(f64, @floatFromInt(samples_per_pixel));

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
            .defocus_disk_u = u * vec.splat(defocus_radius),
            .defocus_disk_v = v * vec.splat(defocus_radius),
        };
    }

    pub fn renderToBuffer(self: Camera, world: *h.HittableList) ![]const [3]u8 {
        const tracy_zone = ztracy.Zone(@src());
        defer tracy_zone.End();

        var pbuf: [1024]u8 = undefined;
        const pr = std.Progress.start(.{
            .draw_buffer = &pbuf,
            .estimated_total_items = self.image_height,
            .root_name = "ray tracer",
        });
        defer pr.end();

        var smp_allocator_state = ztracy.TracyAllocator.init(std.heap.smp_allocator);
        const gpa = smp_allocator_state.allocator();
        var out_buf: [][3]u8 = try gpa.alloc([3]u8, self.image_width * self.image_height);
        var pool: std.Thread.Pool = undefined;
        try pool.init(.{
            .allocator = gpa,
            .n_jobs = (std.Thread.getCpuCount() catch unreachable) - 1,
        });

        var wg: std.Thread.WaitGroup = .{};

        for (0..self.image_height) |j| {
            pool.spawnWg(&wg, computeRow, .{
                self,
                j,
                world,
                out_buf[j * self.image_width ..][0..self.image_width],
                pr,
            });
        }

        pool.waitAndWork(&wg);
        return out_buf;
    }

    pub fn computeRow(self: Camera, height: usize, world: *h.HittableList, out: [][3]u8, pr: std.Progress.Node) void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        const threadName = std.fmt.allocPrintSentinel(allocator, "Thread {d}", .{height}, 0) catch unreachable;
        ztracy.SetThreadName(threadName);
        allocator.free(threadName);
        defer _ = gpa.deinit();

        const tracy_zone = ztracy.Zone(@src());
        defer tracy_zone.End();
        defer pr.completeOne();

        for (0..self.image_width) |i| {
            var pixel_color: vec.Color = vec.zero;

            for (0..self.samples_per_pixel) |_| {
                const r = self.get_ray(i, height);
                pixel_color += ray_color(&r, self.max_depth, world);
            }
            pixel_color *= vec.splat(self.pixel_samples_scale);

            const x: u8 = @intFromFloat(vec.toGamma(pixel_color[0]) * 255.999);
            const y: u8 = @intFromFloat(vec.toGamma(pixel_color[1]) * 255.999);
            const z: u8 = @intFromFloat(vec.toGamma(pixel_color[2]) * 255.999);
            out[i] = .{ x, y, z };
        }
    }

    pub fn get_ray(self: Camera, i: usize, j: usize) Ray {
        @setFloatMode(.optimized);
        const offset = Camera.sample_square();
        const if64: f64 = @floatFromInt(i);
        const jf64: f64 = @floatFromInt(j);
        const uvec = self.pixel_delta_u * vec.splat(if64 + vec.x(offset));
        const vvec = self.pixel_delta_v * vec.splat(jf64 + vec.y(offset));
        const pixel_sample = self.pixel00_loc + uvec + vvec;

        const ray_origin = if (self.defocus_angle <= 0) self.center else self.defocus_sample_disk();
        const ray_direction = pixel_sample - ray_origin;

        return Ray.init(ray_origin, ray_direction);
    }

    fn defocus_sample_disk(self: Camera) vec.Vec3 {
        const rand = rand_state.random();
        const p = vec.randomUnitDisk(rand);
        return self.center + self.defocus_disk_u * vec.splat(vec.x(p)) + self.defocus_disk_v * vec.splat(vec.y(p));
    }

    fn sample_square() vec.Vec3 {
        const rand = rand_state.random();
        return .{ rand.float(f64) - 0.5, rand.float(f64) - 0.5, 0 };
    }

    pub fn ray_color(ray: *const Ray, depth: u32, world: *const h.HittableList) vec.Color {
        const tracy_zone = ztracy.Zone(@src());
        defer tracy_zone.End();
        @setFloatMode(.optimized);
        if (depth <= 0) {
            return vec.zero;
        }

        var rec: h.HitRecord = undefined;
        if (world.hit(ray, Interval.init(0.001, std.math.inf(f64)), &rec)) {
            var scattered: Ray = undefined;
            var attenuation: vec.Color = undefined;
            if (rec.material.scatter(ray, &rec, &attenuation, &scattered)) {
                return attenuation * ray_color(&scattered, depth - 1, world);
            }
            return vec.zero;
        }

        const unit_direction = vec.unit(ray.direction);
        const a: f64 = 0.5 * (vec.y(unit_direction) + 1.0);
        return vec.one * vec.splat(1.0 - a) + vec.Color{ 0.5, 0.7, 1.0 } * vec.splat(a);
    }
};
