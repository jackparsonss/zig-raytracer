const std = @import("std");
const ztracy = @import("ztracy");
const HitRecord = @import("../hittable/hit_record.zig").HitRecord;
const Ray = @import("../ray.zig").Ray;
const v = @import("../vector.zig");

var rand_state = std.Random.DefaultPrng.init(70);

pub const Lambertion = struct {
    albedo: v.Color,

    pub fn scatter(self: Lambertion, ray: *const Ray, hit_record: *HitRecord, attenuation: *v.Color, scattered: *Ray) bool {
        const tracy_zone = ztracy.Zone(@src());
        defer tracy_zone.End();
        _ = ray;
        const r = rand_state.random();
        var scatter_direction = hit_record.normal + v.randomUnit(r);
        if (v.nearZero(scatter_direction)) {
            scatter_direction = hit_record.normal;
        }

        scattered.* = Ray.init(hit_record.p, scatter_direction);
        attenuation.* = self.albedo;

        return true;
    }
};
