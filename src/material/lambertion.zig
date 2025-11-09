const HitRecord = @import("../hittable/hit_record.zig").HitRecord;
const Ray = @import("../ray.zig").Ray;
const v = @import("../vector.zig");
const rand_state = @import("../camera.zig").rand_state;

pub const Lambertion = struct {
    albedo: v.Color,

    pub fn scatter(self: Lambertion, hit_record: *HitRecord, attenuation: *v.Color, scattered: *Ray) bool {
        const r = rand_state.random();
        var scatter_direction = hit_record.normal.add(v.Vec3f32.randomUnitVector(r));
        if (scatter_direction.nearZero()) {
            scatter_direction = hit_record.normal;
        }

        scattered.* = Ray{
            .origin = hit_record.p,
            .direction = scatter_direction,
        };
        attenuation.* = self.albedo;

        return true;
    }
};
