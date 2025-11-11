const v = @import("../vector.zig");
const Ray = @import("../ray.zig").Ray;
const Material = @import("../material/material.zig").Material;

pub const HitRecord = struct {
    p: v.Point,
    normal: v.Vec3,
    material: Material,
    t: f64,
    front_face: bool,
    pub fn set_face_normal(self: *HitRecord, ray: *const Ray, outward_normal: v.Vec3) void {
        self.front_face = v.dot(ray.direction, outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else -outward_normal;
    }
};
