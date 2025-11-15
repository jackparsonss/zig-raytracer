const std = @import("std");
const ztracy = @import("ztracy");
const HitRecord = @import("hit_record.zig").HitRecord;
const Ray = @import("../ray.zig").Ray;
const v = @import("../vector.zig");
const Interval = @import("../interval.zig").Interval;
const Material = @import("../material/material.zig").Material;

pub const Sphere = struct {
    center: v.Point,
    radius: f64,
    material: Material,

    pub fn init(center: v.Point, radius: f64, material: Material) Sphere {
        return .{ .center = center, .radius = @max(0, radius), .material = material };
    }

    pub fn hit(self: Sphere, ray: Ray, ray_t: Interval, rec: *HitRecord) bool {
        const tracy_zone = ztracy.Zone(@src());
        defer tracy_zone.End();
        const oc = self.center - ray.origin;
        const a = v.magnitude2(ray.direction);
        const h = v.dot(ray.direction, oc);
        const c = v.magnitude2(oc) - self.radius * self.radius;
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
        const outward_normal = (rec.p - self.center) / v.splat(self.radius);
        rec.set_face_normal(&ray, outward_normal);
        rec.material = self.material;

        return true;
    }
};
