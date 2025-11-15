const HitRecord = @import("hit_record.zig").HitRecord;
const Sphere = @import("sphere.zig").Sphere;
const Ray = @import("../ray.zig").Ray;
const Interval = @import("../interval.zig").Interval;

pub const Hittable = union(enum) {
    sphere: Sphere,

    pub fn hit(self: Hittable, ray: *const Ray, ray_t: Interval, rec: *HitRecord) bool {
        return switch (self) {
            .sphere => |sphere| sphere.hit(ray, ray_t, rec),
        };
    }
};
