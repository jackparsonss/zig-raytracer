const std = @import("std");
const v = @import("vector.zig");
const h = @import("hittable.zig");
const Ray = @import("ray.zig").Ray;
const Interval = @import("interval.zig").Interval;

pub const Camera = struct {
    aspect_ratio: f32,
    focal_length: f32,
    image_width: u32,
    image_height: u32,
    center: v.Point,
    pixel00_loc: v.Point,
    pixel_delta_u: v.Vec3f32,
    pixel_delta_v: v.Vec3f32,

    pub fn init(aspect_ratio: f32, image_width: u32) Camera {
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

        return .{
            .aspect_ratio = aspect_ratio,
            .image_width = image_width,
            .image_height = image_height,
            .focal_length = focal_length,
            .center = center,
            .pixel00_loc = pixel00_loc,
            .pixel_delta_u = pixel_delta_u,
            .pixel_delta_v = pixel_delta_v,
        };
    }

    pub fn render(self: Camera, world: h.HittableList, writer: *std.Io.Writer) !void {
        try writer.print("P3\n{} {}\n255\n", .{ self.image_width, self.image_height });
        for (0..self.image_height) |j| {
            std.debug.print("\rLines remaining: {}", .{self.image_height - j});
            for (0..self.image_width) |i| {
                const pixel_center = self.pixel00_loc.add(self.pixel_delta_u.scale(@floatFromInt(i))).add(self.pixel_delta_v.scale(@floatFromInt(j)));
                const ray_direction = pixel_center.sub(self.center);
                const ray = Ray{ .origin = self.center, .direction = ray_direction };
                const color = ray_color(ray, &world);
                try v.write_color(writer, color);
            }
        }

        std.debug.print("\rDone.                 \n", .{});
        try writer.flush();
    }

    pub fn ray_color(ray: Ray, world: *const h.HittableList) v.Color {
        var rec: h.HitRecord = undefined;
        if (world.hit(ray, Interval.init(0, std.math.inf(f32)), &rec)) {
            return rec.normal.add(v.Color.init(1, 1, 1)).scale(0.5);
        }

        const unit_direction = ray.direction.unitVector();
        const a: f32 = 0.5 * (unit_direction.y() + 1.0);
        return v.Color.init(1, 1, 1).scale(1.0 - a).add(v.Color.init(0.5, 0.7, 1.0).scale(a));
    }
};
