const HitRecord = @import("hit_record.zig").HitRecord;
const Ray = @import("../ray.zig").Ray;
const v = @import("../vector.zig");
const Interval = @import("../interval.zig").Interval;
const Material = @import("../material/material.zig").Material;

pub const Sphere = struct {
    center: v.Point,
    radius: f32,
    material: Material,

    pub fn init(center: v.Point, radius: f32, material: Material) Sphere {
        return .{ .center = center, .radius = @max(0, radius), .material = material };
    }

    pub fn hit(self: Sphere, ray: Ray, ray_t: Interval, rec: *HitRecord) bool {
        const oc = self.center.sub(ray.origin);
        const a = ray.direction.lengthSquared();
        const h = v.Vec3f32.dot(ray.direction, oc);
        const c = oc.lengthSquared() - self.radius * self.radius;
        const discriminant = h * h - a * c;

        if (discriminant < 0) {
            return false;
        }

        const sqrtd = @sqrt(discriminant);
        var root = (h - sqrtd) / a;
        if (!ray_t.surrounds(root)) {
            root = (h + sqrtd) / a;
            if (!ray_t.surrounds(root)) {
                return false;
            }
        }

        rec.t = root;
        rec.p = ray.at(rec.t);
        const outward_normal = rec.p.sub(self.center).div(self.radius);
        rec.set_face_normal(&ray, outward_normal);
        rec.mat = self.material;

        return true;
    }
};
