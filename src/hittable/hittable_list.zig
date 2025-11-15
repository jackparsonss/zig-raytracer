const std = @import("std");
const ztracy = @import("ztracy");

const HitRecord = @import("hit_record.zig").HitRecord;
const Hittable = @import("hittable.zig").Hittable;
const Ray = @import("../ray.zig").Ray;
const Interval = @import("../interval.zig").Interval;

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

    pub fn hit(self: HittableList, r: *const Ray, ray_t: Interval, rec: *HitRecord) bool {
        const tracy_zone = ztracy.Zone(@src());
        defer tracy_zone.End();
        var temp_rec: HitRecord = undefined;
        var hit_anything = false;
        var closest_so_far = ray_t.max;

        for (self.objects.items) |object| {
            if (object.hit(r, Interval.init(ray_t.min, closest_so_far), &temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec.* = temp_rec;
            }
        }

        return hit_anything;
    }
};
