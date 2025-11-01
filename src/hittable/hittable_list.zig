const std = @import("std");

const HitRecord = @import("hit_record.zig").HitRecord;
const Hittable = @import("hittable.zig").Hittable;
const Ray = @import("../ray.zig").Ray;

pub const HittableList = struct {
    objects: std.ArrayList(Hittable),

    pub fn init() HittableList {
        return .{ .objects = .empty };
    }

    pub fn deinit(self: *HittableList, gpa: std.mem.Allocator) void {
        self.objects.deinit(gpa);
    }

    pub fn clear(self: *HittableList) void {
        self.objects.clearRetainingCapacity();
    }

    pub fn add(self: *HittableList, object: Hittable, gpa: std.mem.Allocator) !void {
        try self.objects.append(gpa, object);
    }

    pub fn hit(self: HittableList, r: Ray, ray_tmin: f32, ray_tmax: f32, rec: *HitRecord) bool {
        var temp_rec: HitRecord = undefined;
        var hit_anything = false;
        var closest_so_far = ray_tmax;

        for (self.objects.items) |object| {
            if (object.hit(r, ray_tmin, closest_so_far, &temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec.* = temp_rec;
            }
        }

        return hit_anything;
    }
};
