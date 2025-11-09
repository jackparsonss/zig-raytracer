const std = @import("std");
const Interval = @import("interval.zig").Interval;

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

        pub fn random(r: std.Random) Self {
            const T_info = @typeInfo(T);
            return switch (T_info) {
                .float => Self.init(r.float(T), r.float(T), r.float(T)),
                .int => Self.init(r.int(T), r.int(T), r.int(T)),
                else => @compileError("Unsupported type for random vector generation"),
            };
        }

        pub fn randomRange(r: std.Random, min: T, max: T) Self {
            const T_info = @typeInfo(T);
            return switch (T_info) {
                .float => {
                    const xval = r.float(T) * (max - min) + min;
                    const yval = r.float(T) * (max - min) + min;
                    const zval = r.float(T) * (max - min) + min;
                    return Self.init(xval, yval, zval);
                },
                .int => {
                    const xval = r.intRange(T, min, max);
                    const yval = r.intRange(T, min, max);
                    const zval = r.intRange(T, min, max);
                    return Self.init(xval, yval, zval);
                },
                else => @compileError("Unsupported type for random vector generation"),
            };
        }

        pub fn randomUnitVector(r: std.Random) Self {
            while (true) {
                const p = Self.randomRange(r, -1, 1);
                const lensq = p.lengthSquared();
                if (std.math.floatEpsAt(T, 0) < lensq and lensq <= 1) {
                    return p.div(@sqrt(lensq));
                }
            }
        }

        pub fn nearZero(self: Self) bool {
            const s: T = 1e-8;
            return (@abs(self.e[0]) < s) and (@abs(self.e[1]) < s) and (@abs(self.e[2]) < s);
        }

        pub fn reflect(v: Self, n: Self) Self {
            return v.sub(n.scale(2 * v.dot(n)));
        }

        pub fn refract(uv: Self, n: Self, etai_over_etat: T) Self {
            const cos_theta = @min(uv.negate().dot(n), 1.0);
            const r_out_perp = uv.add(n.scale(cos_theta)).scale(etai_over_etat);
            const r_out_parallel = n.scale(-@sqrt(@abs(1.0 - r_out_perp.lengthSquared())));
            return r_out_perp.add(r_out_parallel);
        }

        pub fn randomOnHemisphere(r: std.Random, normal: Self) Self {
            const on_unit_sphere = Self.randomUnitVector(r);
            if (normal.dot(on_unit_sphere) > 0.0) {
                return on_unit_sphere;
            }

            return on_unit_sphere.negate();
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

const intensity: Interval = Interval.init(0.000, 0.999);

fn linearToGamma(linear_component: f32) f32 {
    if (linear_component > 0) {
        return @sqrt(linear_component);
    }

    return 0;
}

pub fn write_color(writer: *std.Io.Writer, color: Color) !void {
    const x = linearToGamma(color.x());
    const y = linearToGamma(color.y());
    const z = linearToGamma(color.z());

    const ir: i32 = @intFromFloat(256 * intensity.clamp(x));
    const ig: i32 = @intFromFloat(256 * intensity.clamp(y));
    const ib: i32 = @intFromFloat(256 * intensity.clamp(z));

    try writer.print("{} {} {}\n", .{ ir, ig, ib });
}
