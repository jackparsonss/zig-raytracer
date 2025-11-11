const std = @import("std");
const HitRecord = @import("../hittable/hit_record.zig").HitRecord;
const Ray = @import("../ray.zig").Ray;
const v = @import("../vector.zig");

var rand_state = std.Random.DefaultPrng.init(70);

fn reflectance(cosine: f64, ref_idx: f64) f64 {
    var r0 = (1.0 - ref_idx) / (1.0 + ref_idx);
    r0 = r0 * r0;
    return r0 + (1.0 - r0) * std.math.pow(f64, 1.0 - cosine, 5);
}

pub const Dialetric = struct {
    refraction_index: f64,

    pub fn init(refraction_index: f64) Dialetric {
        return Dialetric{
            .refraction_index = refraction_index,
        };
    }

    pub fn scatter(self: Dialetric, ray: Ray, hit_record: *HitRecord, attenuation: *v.Color, scattered: *Ray) bool {
        attenuation.* = v.one;
        const ri: f64 = if (hit_record.front_face) 1.0 / self.refraction_index else self.refraction_index;

        const unit_direction = v.unit(ray.direction);
        const cos_theta = @min(v.dot(-unit_direction, hit_record.normal), 1.0);
        const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);
        const cannot_refract = ri * sin_theta > 1.0;
        var direction: v.Vec3 = undefined;
        if (cannot_refract or reflectance(cos_theta, ri) > rand_state.random().float(f64)) {
            direction = v.reflect(unit_direction, hit_record.normal);
        } else {
            direction = v.refract(unit_direction, hit_record.normal, ri);
        }

        scattered.* = Ray{
            .origin = hit_record.p,
            .direction = direction,
        };

        return true;
    }
};
