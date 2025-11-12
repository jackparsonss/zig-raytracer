const std = @import("std");
const c = @cImport({
    @cInclude("libxml/parser.h");
    @cInclude("libxml/tree.h");
});
const Camera = @import("camera.zig").Camera;
const HittableList = @import("hittable.zig").HittableList;
const Hittable = @import("hittable.zig").Hittable;
const Sphere = @import("hittable/sphere.zig").Sphere;
const vec = @import("vector.zig");
const Material = @import("material/material.zig").Material;
const Lambertion = @import("material/lambertion.zig").Lambertion;
const Metal = @import("material/metal.zig").Metal;
const Dialetric = @import("material/dialetric.zig").Dialetric;

const XmlError = error{
    ParseError,
    EmptyDocument,
    NodeNotFound,
    InvalidValue,
    InvalidType,
};

const Context = struct {
    allocator: std.mem.Allocator,
    doc: *c.xmlDoc,

    fn getContent(self: Context, node: *c.xmlNode) ![]const u8 {
        const content = c.xmlNodeGetContent(node);
        if (content == null) {
            return error.InvalidValue;
        }
        defer if (c.xmlFree) |free_fn| free_fn(content);
        return self.allocator.dupe(u8, std.mem.sliceTo(content, 0));
    }

    fn getProp(self: Context, node: *c.xmlNode, name: []const u8) ![]const u8 {
        const c_name = try self.allocator.dupeZ(u8, name);
        defer self.allocator.free(c_name);
        const prop = c.xmlGetProp(node, c_name.ptr);
        if (prop == null) {
            return error.InvalidValue;
        }
        defer if (c.xmlFree) |free_fn| free_fn(prop);
        return self.allocator.dupe(u8, std.mem.sliceTo(prop, 0));
    }

    fn getFloatProp(self: Context, node: *c.xmlNode, name: []const u8) !f64 {
        const str = try self.getProp(node, name);
        defer self.allocator.free(str);
        return std.fmt.parseFloat(f64, str);
    }

    fn getVec3Prop(self: Context, node: *c.xmlNode) !vec.Vec3 {
        const x = try self.getFloatProp(node, "x");
        const y = try self.getFloatProp(node, "y");
        const z = try self.getFloatProp(node, "z");
        return vec.Vec3{ x, y, z };
    }

    fn getRGBProp(self: Context, node: *c.xmlNode) !vec.Vec3 {
        const r = try self.getFloatProp(node, "r");
        const g = try self.getFloatProp(node, "g");
        const b = try self.getFloatProp(node, "b");
        return vec.Color{ r, g, b };
    }

    fn findNode(_: Context, parent: *c.xmlNode, name: []const u8) !*c.xmlNode {
        var node = parent.*.children;
        while (node != null) : (node = node.*.next) {
            if (node.*.type == c.XML_ELEMENT_NODE and std.mem.eql(u8, name, std.mem.sliceTo(node.*.name, 0))) {
                return node;
            }
        }
        return error.NodeNotFound;
    }

    fn getFloatContent(self: Context, parent: *c.xmlNode, name: []const u8) !f64 {
        const node = try self.findNode(parent, name);
        const content = try self.getContent(node);
        defer self.allocator.free(content);
        if (std.mem.indexOf(u8, content, "/")) |idx| {
            const num = try std.fmt.parseFloat(f64, content[0..idx]);
            const den = try std.fmt.parseFloat(f64, content[idx + 1 ..]);
            return num / den;
        }
        return std.fmt.parseFloat(f64, content);
    }

    fn getU32Content(self: Context, parent: *c.xmlNode, name: []const u8) !u32 {
        const node = try self.findNode(parent, name);
        const content = try self.getContent(node);
        defer self.allocator.free(content);
        return std.fmt.parseInt(u32, content, 10);
    }

    fn getVec3Content(self: Context, parent: *c.xmlNode, name: []const u8) !vec.Vec3 {
        const node = try self.findNode(parent, name);
        return self.getVec3Prop(node);
    }
};

pub const Scene = struct {
    camera: Camera,
    world: HittableList,

    pub fn deinit(self: Scene, gpa: std.mem.Allocator) void {
        const world = &self.world;
        world.deinit(gpa);
    }
};

fn parseMaterial(ctx: Context, node: *c.xmlNode) !Material {
    const material_type = try ctx.getProp(node, "type");
    defer ctx.allocator.free(material_type);

    if (std.mem.eql(u8, material_type, "lambertian")) {
        const albedo_node = try ctx.findNode(node, "albedo");
        const albedo = try ctx.getRGBProp(albedo_node);
        return Material{ .lambertion = Lambertion{ .albedo = albedo } };
    } else if (std.mem.eql(u8, material_type, "metal")) {
        const albedo_node = try ctx.findNode(node, "albedo");
        const albedo = try ctx.getRGBProp(albedo_node);
        const fuzz = try ctx.getFloatProp(node, "fuzz");
        return Material{ .metal = Metal.init(albedo, fuzz) };
    } else if (std.mem.eql(u8, material_type, "dielectric")) {
        const ior = try ctx.getFloatContent(node, "ior");
        return Material{ .dialetric = Dialetric.init(ior) };
    }

    return error.InvalidType;
}

fn parseSphere(ctx: Context, node: *c.xmlNode) !Hittable {
    const center = try ctx.getVec3Content(node, "center");
    const radius = try ctx.getFloatContent(node, "radius");
    const material_node = try ctx.findNode(node, "material");
    const material = try parseMaterial(ctx, material_node);

    const sphere = Sphere.init(center, radius, material);
    return Hittable{ .sphere = sphere };
}

fn parseObjects(ctx: Context, node: *c.xmlNode, world: *HittableList) !void {
    var child = node.*.children;
    while (child != null) : (child = child.*.next) {
        if (child.*.type == c.XML_ELEMENT_NODE) {
            if (std.mem.eql(u8, std.mem.sliceTo(child.*.name, 0), "sphere")) {
                const sphere = try parseSphere(ctx, child);
                try world.add(sphere, ctx.allocator);
            }
        }
    }
}

fn parseCamera(ctx: Context, node: *c.xmlNode) !Camera {
    const aspect_ratio = try ctx.getFloatContent(node, "aspect_ratio");
    const image_width = try ctx.getU32Content(node, "image_width");
    const samples_per_pixel = try ctx.getU32Content(node, "samples_per_pixel");
    const max_depth = try ctx.getU32Content(node, "max_depth");
    const fov = try ctx.getFloatContent(node, "fov");
    const lookfrom = try ctx.getVec3Content(node, "lookfrom");
    const lookat = try ctx.getVec3Content(node, "lookat");
    const vup = try ctx.getVec3Content(node, "vup");
    const defocus_angle = try ctx.getFloatContent(node, "defocus_angle");
    const defocus_dist = try ctx.getFloatContent(node, "defocus_dist");

    return Camera.init(aspect_ratio, image_width, samples_per_pixel, max_depth, fov, lookat, lookfrom, vup, defocus_angle, defocus_dist);
}

pub fn parseXmlFile(filename: []const u8, allocator: std.mem.Allocator) !Scene {
    const c_filename = try allocator.dupeZ(u8, filename);
    defer allocator.free(c_filename);

    const doc = c.xmlReadFile(c_filename.ptr, null, 0);
    if (doc == null) {
        std.debug.print("Error: could not parse file {s}\n", .{filename});
        return error.ParseError;
    }
    defer c.xmlFreeDoc(doc);

    const root = c.xmlDocGetRootElement(doc);
    if (root == null) {
        std.debug.print("Error: empty document\n", .{});
        return error.EmptyDocument;
    }

    const ctx = Context{ .allocator = allocator, .doc = doc };

    var camera: ?Camera = null;
    var world = HittableList.init();

    var node = root.*.children;
    while (node != null) : (node = node.*.next) {
        if (node.*.type == c.XML_ELEMENT_NODE) {
            const name = std.mem.sliceTo(node.*.name, 0);
            if (std.mem.eql(u8, name, "camera")) {
                camera = try parseCamera(ctx, node);
            } else if (std.mem.eql(u8, name, "objects")) {
                try parseObjects(ctx, node, &world);
            }
        }
    }

    c.xmlCleanupParser();

    if (camera == null) {
        return error.NodeNotFound;
    }

    return Scene{
        .camera = camera.?,
        .world = world,
    };
}
