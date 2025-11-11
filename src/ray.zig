const vector = @import("vector.zig");
const Point = vector.Point;
const Vec3 = vector.Vec3;

pub const Ray = struct {
    origin: Point,
    direction: Vec3,

    pub fn at(self: Ray, t: f64) Point {
        return self.origin + self.direction * vector.splat(t);
    }
};
