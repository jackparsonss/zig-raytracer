const std = @import("std");
const HitRecord = @import("../hittable/hit_record.zig").HitRecord;
const Ray = @import("../ray.zig").Ray;
const v = @import("../vector.zig");

var rand_state = std.Random.DefaultPrng.init(70);

fn reflectance(cosine: f32, ref_idx: f32) f32 {
    var r0 = (1.0 - ref_idx) / (1.0 + ref_idx);
    r0 = r0 * r0;
    return r0 + (1.0 - r0) * std.math.pow(f32, 1.0 - cosine, 5);
}

pub const Dialetric = struct {
    refraction_index: f32,

    pub fn init(refraction_index: f32) Dialetric {
        return Dialetric{
            .refraction_index = refraction_index,
        };
    }

    pub fn scatter(self: Dialetric, ray: Ray, hit_record: *HitRecord, attenuation: *v.Color, scattered: *Ray) bool {
        attenuation.* = v.Color.init(1.0, 1.0, 1.0);
        const ri: f32 = if (hit_record.front_face) 1.0 / self.refraction_index else self.refraction_index;

        const unit_direction = ray.direction.unitVector();
        const cos_theta = @min(unit_direction.negate().dot(hit_record.normal), 1.0);
        const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);
        const cannot_refract = ri * sin_theta > 1.0;
        var direction: v.Vec3f32 = undefined;
        if (cannot_refract or reflectance(cos_theta, ri) > rand_state.random().float(f32)) {
            direction = unit_direction.reflect(hit_record.normal);
        } else {
            direction = unit_direction.refract(hit_record.normal, ri);
        }

        scattered.* = Ray{
            .origin = hit_record.p,
            .direction = direction,
        };

        return true;
    }
};
