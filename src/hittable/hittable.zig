const HitRecord = @import("hit_record.zig").HitRecord;
const Sphere = @import("sphere.zig").Sphere;
const Ray = @import("../ray.zig").Ray;

pub const Hittable = union(enum) {
    sphere: Sphere,

    pub fn hit(self: Hittable, ray: Ray, ray_tmin: f32, ray_tmax: f32, rec: *HitRecord) bool {
        return switch (self) {
            .sphere => |sphere| sphere.hit(ray, ray_tmin, ray_tmax, rec),
        };
    }
};
