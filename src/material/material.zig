const Metal = @import("metal.zig").Metal;
const Lambertion = @import("lambertion.zig").Lambertion;
const Dialetric = @import("dialetric.zig").Dialetric;
const HitRecord = @import("../hittable/hit_record.zig").HitRecord;
const Ray = @import("../ray.zig").Ray;
const v = @import("../vector.zig");

pub const Material = union(enum) {
    metal: Metal,
    lambertion: Lambertion,
    dialetric: Dialetric,

    pub fn scatter(self: Material, ray: *const Ray, hit_record: *HitRecord, attenuation: *v.Color, scattered: *Ray) bool {
        return switch (self) {
            .metal => |m| m.scatter(ray, hit_record, attenuation, scattered),
            .lambertion => |l| l.scatter(ray, hit_record, attenuation, scattered),
            .dialetric => |d| d.scatter(ray, hit_record, attenuation, scattered),
        };
    }
};
