const std = @import("std");
const HitRecord = @import("../hittable/hit_record.zig").HitRecord;
const Ray = @import("../ray.zig").Ray;
const v = @import("../vector.zig");

var rand_state = std.Random.DefaultPrng.init(70);

pub const Dialetric = struct {
    refraction_index: f32,

    pub fn init(refraction_index: f32) Dialetric {
        return Dialetric{
            .refraction_index = refraction_index,
        };
    }

    pub fn scatter(self: Dialetric, ray: Ray, hit_record: *HitRecord, attenuation: *v.Color, scattered: *Ray) bool {
        attenuation.* = v.Color.init(0, 0, 0);
        const ri: f32 = if (hit_record.front_face) 1.0 / self.refraction_index else self.refraction_index;

        const unit_direction = ray.direction.unitVector();
        const refracted = unit_direction.refract(hit_record.normal, ri);

        scattered.* = Ray{
            .origin = hit_record.p,
            .direction = refracted,
        };

        return true;
    }
};
