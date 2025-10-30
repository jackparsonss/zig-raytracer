const std = @import("std");
const v = @import("vector.zig");
const Ray = @import("ray.zig").Ray;

fn ray_color(ray: Ray) v.Color {
    const unit_direction = ray.direction.unitVector();
    const a: f32 = 0.5 * (unit_direction.y() + 1.0);

    return v.Color.init(1, 1, 1).scale(1.0 - a).add(v.Color.init(0.5, 0.7, 1.0).scale(a));
}

pub const PPMFile = struct {
    image_width: u32,
    image_height: u32,
    viewport_width: f32,
    viewport_height: f32,

    pub fn init() PPMFile {
        const aspect_ratio: f32 = 16.0 / 9.0;
        const image_width: i32 = 400;

        comptime var image_height: i32 = @intFromFloat(@as(f32, @floatFromInt(image_width)) / aspect_ratio);
        image_height = if (image_height < 1) 1 else image_height;

        const viewport_height: f32 = 2.0;
        const viewport_width = viewport_height * (image_width / image_height);

        return PPMFile{ .image_height = image_height, .image_width = image_width, .viewport_height = viewport_height, .viewport_width = viewport_width };
    }

    pub fn write(self: PPMFile) !void {
        const file = try std.fs.cwd().createFile("output/image.ppm", .{ .truncate = true });
        defer file.close();

        var write_buffer: [4096]u8 = undefined;
        var file_writer = file.writer(&write_buffer);
        const writer: *std.Io.Writer = &file_writer.interface;

        // TODO: move camera into own struct
        const focal_length = 1.0;
        const camera_center = v.Point.init(0, 0, 0);

        const viewport_u = v.Vec3f32.init(self.viewport_width, 0, 0);
        const viewport_v = v.Vec3f32.init(0, -self.viewport_height, 0);

        const pixel_delta_u = viewport_u.div(@floatFromInt(self.image_width));
        const pixel_delta_v = viewport_v.div(@floatFromInt(self.image_height));

        const viewport_upper_left = camera_center.sub(v.Vec3f32.init(0, 0, focal_length)).sub(viewport_u.div(2)).sub(viewport_v.div(2));
        const pixel00_loc = viewport_upper_left.add(pixel_delta_u.add(pixel_delta_v).scale(0.5));

        try writer.print("P3\n{} {}\n255\n", .{ self.image_width, self.image_height });
        for (0..self.image_height) |j| {
            std.debug.print("\rLines remaining: {}", .{self.image_height - j});
            for (0..self.image_width) |i| {
                const pixel_center = pixel00_loc.add(pixel_delta_u.scale(@floatFromInt(i))).add(pixel_delta_v.scale(@floatFromInt(j)));
                const ray_direction = pixel_center.sub(camera_center);
                const ray = Ray{ .origin = camera_center, .direction = ray_direction };
                const color = ray_color(ray);
                try v.write_color(writer, color);
            }
        }

        std.debug.print("\rDone.                 \n", .{});
        try writer.flush();
    }
};

pub fn run() !void {
    const f = PPMFile.init();
    try f.write();
}
