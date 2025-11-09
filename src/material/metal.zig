const std = @import("std");
const HitRecord = @import("../hittable/hit_record.zig").HitRecord;
const Ray = @import("../ray.zig").Ray;
const v = @import("../vector.zig");

pub threadlocal var rand_state = std.Random.DefaultPrng.init(70);

pub const Metal = struct {
    albedo: v.Color,
    fuzz: f32,

    pub fn init(albedo: v.Color, fuzz: f32) Metal {
        return Metal{
            .albedo = albedo,
            .fuzz = if (fuzz < 1.0) fuzz else 1.0,
        };
    }

    pub fn scatter(self: Metal, ray: Ray, hit_record: *HitRecord, attenuation: *v.Color, scattered: *Ray) bool {
        const r = rand_state.random();
        const reflected = ray.direction.reflect(hit_record.normal).unitVector().add(v.Vec3f32.randomUnitVector(r).scale(self.fuzz));
        scattered.* = Ray{ .origin = hit_record.p, .direction = reflected };
        attenuation.* = self.albedo;

        return true;
    }
};
