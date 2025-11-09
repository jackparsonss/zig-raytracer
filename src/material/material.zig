const Metal = @import("metal.zig").Metal;
const Lambertion = @import("lambertion.zig").Lambertion;
const HitRecord = @import("../hittable/hit_record.zig").HitRecord;
const Ray = @import("../ray.zig").Ray;
const v = @import("../vector.zig");

pub const Material = union(enum) {
    metal: Metal,
    lambertion: Lambertion,

    pub fn scatter(self: Material, ray: Ray, hit_record: *HitRecord, attenuation: v.Color, scattered: Ray) bool {
        return switch (self) {
            .metal => |metal| metal.scatter(ray, hit_record, attenuation, scattered),
            .lambertion => |l| l.scatter(hit_record, attenuation, scattered),
        };
    }
};
