const std = @import("std");
const ztracy = @import("ztracy");
const HitRecord = @import("../hittable/hit_record.zig").HitRecord;
const Ray = @import("../ray.zig").Ray;
const v = @import("../vector.zig");

pub threadlocal var rand_state = std.Random.DefaultPrng.init(70);

pub const Metal = struct {
    albedo: v.Color,
    fuzz: f64,

    pub fn init(albedo: v.Color, fuzz: f64) Metal {
        return Metal{
            .albedo = albedo,
            .fuzz = if (fuzz < 1.0) fuzz else 1.0,
        };
    }

    pub fn scatter(self: Metal, ray: *const Ray, hit_record: *HitRecord, attenuation: *v.Color, scattered: *Ray) bool {
        const tracy_zone = ztracy.Zone(@src());
        defer tracy_zone.End();
        const r = rand_state.random();
        const reflected = v.reflect(v.unit(ray.direction), hit_record.normal) + v.splat(self.fuzz) * v.randomUnit(r);
        scattered.* = Ray.init(hit_record.p, reflected);
        attenuation.* = self.albedo;

        return v.dot(scattered.direction, hit_record.normal) > 0;
    }
};
