const HitRecord = @import("../hittable/hit_record.zig").HitRecord;
const Ray = @import("../ray.zig").Ray;
const v = @import("../vector.zig");

pub const Metal = struct {
    albedo: v.Color,

    pub fn scatter(self: Metal, ray: Ray, hit_record: *HitRecord, attenuation: *v.Color, scattered: *Ray) bool {
        const reflected = ray.direction.reflect(hit_record.normal);
        scattered.* = Ray{ .origin = hit_record.p, .direction = reflected };
        attenuation.* = self.albedo;

        return true;
    }
};
