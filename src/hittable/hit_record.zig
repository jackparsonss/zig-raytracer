const v = @import("../vector.zig");
const Ray = @import("../ray.zig").Ray;

pub const HitRecord = struct {
    p: v.Point,
    normal: v.Vec3f32,
    t: f32,
    front_face: bool,
    pub fn set_face_normal(self: *HitRecord, ray: *const Ray, outward_normal: v.Vec3f32) void {
        self.front_face = v.Vec3f32.dot(ray.direction, outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.negate();
    }
};
