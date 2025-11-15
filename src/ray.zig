const vector = @import("vector.zig");
const Point = vector.Point;
const Vec3 = vector.Vec3;

pub const Ray = struct {
    origin: Point,
    direction: Vec3,
    time: f64,

    pub fn init(origin: Point, direction: Vec3) Ray {
        return Ray{ .origin = origin, .direction = direction, .time = 0 };
    }

    pub fn initAtTime(origin: Point, direction: Vec3, time: f64) Ray {
        return Ray{ .origin = origin, .direction = direction, .time = time };
    }

    pub fn at(self: Ray, t: f64) Point {
        return @mulAdd(Vec3, @splat(t), self.direction, self.origin);
    }
};
