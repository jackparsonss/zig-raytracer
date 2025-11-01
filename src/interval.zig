const std = @import("std");

pub const Interval = struct {
    min: f32,
    max: f32,

    pub fn init(min: f32, max: f32) Interval {
        return .{ .min = min, .max = max };
    }

    pub fn size(self: Interval) f32 {
        return self.max - self.min;
    }

    pub fn contains(self: Interval, value: f32) bool {
        return self.min <= value and value <= self.max;
    }

    pub fn surrounds(self: Interval, value: f32) bool {
        return self.min < value and value < self.max;
    }
};

pub const empty = Interval.init(std.math.floatMax(f32), std.math.floatMin(f32));
pub const universe = Interval.init(std.math.floatMin(f32), std.math.floatMax(f32));
