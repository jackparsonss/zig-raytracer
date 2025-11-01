const HitRecord = @import("hit_record.zig").HitRecord;
const Ray = @import("../ray.zig").Ray;
const v = @import("../vector.zig");

pub const Sphere = struct {
    center: v.Point,
    radius: f32,

    pub fn init(center: v.Point, radius: f32) Sphere {
        return .{ .center = center, .radius = @max(0, radius) };
    }

    pub fn hit(self: Sphere, ray: Ray, ray_tmin: f32, ray_tmax: f32, rec: *HitRecord) bool {
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
        if (root <= ray_tmin or ray_tmax <= root) {
            root = (h + sqrtd) / a;
            if (root <= ray_tmin or ray_tmax <= root) {
                return false;
            }
        }

        rec.t = root;
        rec.p = ray.at(rec.t);
        const outward_normal = rec.p.sub(self.center).div(self.radius);
        rec.set_face_normal(&ray, outward_normal);

        return true;
    }
};
