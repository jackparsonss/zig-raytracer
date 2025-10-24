const std = @import("std");

pub const PPMFile = struct {
    width: u32,
    height: u32,

    pub fn write(self: PPMFile) !void {
        const file = try std.fs.cwd().createFile("output/image.ppm", .{ .truncate = true });
        defer file.close();

        var write_buffer: [4096]u8 = undefined;
        var file_writer = file.writer(&write_buffer);

        const writer: *std.Io.Writer = &file_writer.interface;
        try writer.print("P3\n{} {}\n255\n", .{ self.width, self.height });
        for (0..self.height) |j| {
            for (0..self.width) |i| {
                const r: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(self.width - 1));
                const g: f32 = @as(f32, @floatFromInt(j)) / @as(f32, @floatFromInt(self.height - 1));
                const b: f32 = 0.0;

                const ir: i32 = @as(i32, @intFromFloat(255.999 * r));
                const ig: i32 = @as(i32, @intFromFloat(255.999 * g));
                const ib: i32 = @as(i32, @intFromFloat(255.999 * b));

                try writer.print("{} {} {}\n", .{ ir, ig, ib });
            }
        }

        try writer.flush();
    }
};

pub fn run() !void {
    const f = PPMFile{ .width = 256, .height = 256 };
    try f.write();
}
