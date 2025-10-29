const std = @import("std");

pub fn Vec3(comptime T: type) type {
    return struct {
        const Self = @This();

        e: [3]T,

        pub fn init(e0: T, e1: T, e2: T) Self {
            return Self{ .e = .{ e0, e1, e2 } };
        }

        pub fn zero() Self {
            return Self{ .e = .{ 0, 0, 0 } };
        }

        pub fn x(self: Self) T {
            return self.e[0];
        }

        pub fn y(self: Self) T {
            return self.e[1];
        }

        pub fn z(self: Self) T {
            return self.e[2];
        }

        pub fn negate(self: Self) Self {
            return Self{ .e = .{ -self.e[0], -self.e[1], -self.e[2] } };
        }

        pub fn addAssign(self: *Self, v: Self) void {
            inline for (0..3) |i| {
                self.e[i] += v.e[i];
            }
        }

        pub fn mulAssign(self: *Self, t: T) void {
            inline for (0..3) |i| {
                self.e[i] *= t;
            }
        }

        pub fn divAssign(self: *Self, t: T) void {
            const inv = 1.0 / t;
            inline for (0..3) |i| {
                self.e[i] *= inv;
            }
        }

        pub fn length(self: Self) T {
            return @sqrt(self.lengthSquared());
        }

        pub fn lengthSquared(self: Self) T {
            var sum: T = 0;
            inline for (0..3) |i| {
                sum += self.e[i] * self.e[i];
            }
            return sum;
        }

        pub fn add(u: Self, v: Self) Self {
            var result: Self = undefined;
            inline for (0..3) |i| {
                result.e[i] = u.e[i] + v.e[i];
            }
            return result;
        }

        pub fn sub(u: Self, v: Self) Self {
            var result: Self = undefined;
            inline for (0..3) |i| {
                result.e[i] = u.e[i] - v.e[i];
            }
            return result;
        }

        pub fn mul(u: Self, v: Self) Self {
            var result: Self = undefined;
            inline for (0..3) |i| {
                result.e[i] = u.e[i] * v.e[i];
            }
            return result;
        }

        pub fn scale(v: Self, t: T) Self {
            var result: Self = undefined;
            inline for (0..3) |i| {
                result.e[i] = v.e[i] * t;
            }
            return result;
        }

        pub fn div(v: Self, t: T) Self {
            const inv = 1.0 / t;
            var result: Self = undefined;
            inline for (0..3) |i| {
                result.e[i] = v.e[i] * inv;
            }
            return result;
        }

        pub fn dot(u: Self, v: Self) T {
            var sum: T = 0;
            inline for (0..3) |i| {
                sum += u.e[i] * v.e[i];
            }
            return sum;
        }

        pub fn cross(u: Self, v: Self) Self {
            return Self.init(
                u.e[1] * v.e[2] - u.e[2] * v.e[1],
                u.e[2] * v.e[0] - u.e[0] * v.e[2],
                u.e[0] * v.e[1] - u.e[1] * v.e[0],
            );
        }

        pub fn unitVector(v: Self) Self {
            return v.div(v.length());
        }

        pub fn format(self: Self, writer: *std.Io.Writer) !void {
            try writer.print("{d} {d} {d}\n", .{ self.e[0], self.e[1], self.e[2] });
        }
    };
}

pub const Vec3f64 = Vec3(f64);
pub const Vec3f32 = Vec3(f32);
pub const Point = Vec3f32;
pub const Color = Vec3f32;

pub fn write_color(writer: *std.Io.Writer, color: Color) !void {
    const ir: i32 = @as(i32, @intFromFloat(255.999 * color.x()));
    const ig: i32 = @as(i32, @intFromFloat(255.999 * color.y()));
    const ib: i32 = @as(i32, @intFromFloat(255.999 * color.z()));

    try writer.print("{} {} {}\n", .{ ir, ig, ib });
}
