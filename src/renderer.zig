const std = @import("std");
const zigimg = @import("zigimg");
const h = @import("hittable.zig");
const Camera = @import("camera.zig").Camera;
const ztracy = @import("ztracy");

pub const OutputFormat = enum {
    PPM,
    PNG,
};

pub const Renderer = struct {
    camera: *Camera,

    pub fn init(camera: *Camera) Renderer {
        return Renderer{ .camera = camera };
    }

    pub fn render(self: Renderer, world: *h.HittableList, writer: *std.Io.Writer) !void {
        try self.camera.render(world, writer);
    }
};

pub fn write(
    camera: *Camera,
    world: *h.HittableList,
    output_format: OutputFormat,
    output_path: []const u8,
) !void {
    const renderer = Renderer.init(camera);
    const pixel_buffer = try renderer.camera.renderToBuffer(world);
    switch (output_format) {
        .PPM => {
            const file = try std.fs.cwd().createFile(output_path, .{ .truncate = true });
            defer file.close();

            var write_buffer: [4096]u8 = undefined;
            var file_writer = file.writer(&write_buffer);
            const writer: *std.Io.Writer = &file_writer.interface;

            try writer.print("P6\n{} {}\n255\n", .{ camera.image_width, camera.image_height });
            try writer.writeSliceEndian(u8, std.mem.sliceAsBytes(pixel_buffer), .little);
            try writer.flush();
        },
        .PNG => {
            var smp_allocator_state = ztracy.TracyAllocator.init(std.heap.smp_allocator);
            const allocator = smp_allocator_state.allocator();
            defer allocator.free(pixel_buffer);

            var image = try zigimg.Image.create(allocator, camera.image_width, camera.image_height, .rgba32);
            defer image.deinit(allocator);

            const image_slice = std.mem.sliceAsBytes(image.pixels.rgba32);
            for (pixel_buffer, 0..) |pixel, i| {
                image_slice[i * 4 + 0] = pixel[0];
                image_slice[i * 4 + 1] = pixel[1];
                image_slice[i * 4 + 2] = pixel[2];
                image_slice[i * 4 + 3] = 255;
            }

            var write_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
            try image.writeToFilePath(allocator, output_path, &write_buffer, .{ .png = .{} });
            return;
        },
    }
}
