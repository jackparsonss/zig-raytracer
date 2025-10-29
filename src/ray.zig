const vector = @import("vector.zig");
const Point = vector.Point;
const Vec3 = vector.Vec3f32;

pub const Ray = struct {
    origin: Point,
    direction: Vec3,

    pub fn at(self: Ray, t: f32) Point {
        return self.origin.add(self.direction.scale(t));
    }
};
