const std = @import("std");

pub const Interval = struct {
    min: f64,
    max: f64,

    pub fn init(min: f64, max: f64) Interval {
        return .{ .min = min, .max = max };
    }

    pub fn size(self: Interval) f64 {
        return self.max - self.min;
    }

    pub fn contains(self: Interval, value: f64) bool {
        return self.min <= value and value <= self.max;
    }

    pub fn surrounds(self: Interval, value: f64) bool {
        return self.min < value and value < self.max;
    }

    pub fn clamp(self: Interval, value: f64) f64 {
        if (value < self.min) {
            return self.min;
        }

        if (value > self.max) {
            return self.max;
        }

        return value;
    }
};

pub const empty = Interval.init(std.math.floatMax(f64), std.math.floatMin(f64));
pub const universe = Interval.init(std.math.floatMin(f64), std.math.floatMax(f64));
