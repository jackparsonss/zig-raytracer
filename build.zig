const std = @import("std");

pub fn build(b: *std.Build) void {
    const options = .{
        .enable_ztracy = b.option(
            bool,
            "enable_ztracy",
            "Enable Tracy profile markers",
        ) orelse false,
        .enable_fibers = b.option(
            bool,
            "enable_fibers",
            "Enable Tracy fiber support",
        ) orelse false,
        .on_demand = b.option(
            bool,
            "on_demand",
            "Build tracy with TRACY_ON_DEMAND",
        ) orelse false,
    };

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("raytracer", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "raytracer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "raytracer", .module = mod },
            },
        }),
    });

    exe.linkLibC();
    exe.linkSystemLibrary("xml2");

    if (target.result.os.tag == .macos) {
        mod.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include/libxml2" });
        exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
        exe.root_module.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include/libxml2" });
    } else {
        const xml2_cflags_out = b.run(&.{ "pkg-config", "--cflags", "libxml-2.0" });
        const xml2_cflags = std.mem.trim(u8, xml2_cflags_out, " \n\r");
        // Parse and add include paths from pkg-config
        var it = std.mem.tokenizeScalar(u8, xml2_cflags, ' ');
        while (it.next()) |flag| {
            if (std.mem.startsWith(u8, flag, "-I")) {
                const path = flag[2..];
                mod.addIncludePath(.{ .cwd_relative = path });
                exe.root_module.addIncludePath(.{ .cwd_relative = path });
            }
        }
    }

    const ztracy = b.dependency("ztracy", .{
        .enable_ztracy = options.enable_ztracy,
        .enable_fibers = options.enable_fibers,
        .on_demand = options.on_demand,
    });
    exe.root_module.addImport("ztracy", ztracy.module("root"));
    exe.linkLibrary(ztracy.artifact("tracy"));
    mod.addImport("ztracy", ztracy.module("root"));

    const zigimg_dependency = b.dependency("zigimg", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zigimg", zigimg_dependency.module("zigimg"));
    mod.addImport("zigimg", zigimg_dependency.module("zigimg"));

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    const format = b.option(
        []const u8,
        "format",
        "The output format, either 'ppm' or 'png'",
    ) orelse "ppm";

    const scene_name = b.option(
        []const u8,
        "scene",
        "The name of the scene file in 'src/scenes/'",
    ) orelse "base.xml";

    const scene_path = b.fmt("src/scenes/{s}", .{scene_name});

    const output_name = b.option(
        []const u8,
        "output",
        "The name of the file to output to in 'output/'",
    ) orelse "image";

    const output_path = b.fmt("output/{s}.{s}", .{ output_name, format });

    run_cmd.addArgs(&.{ scene_path, format, output_path });
    run_cmd.step.dependOn(b.getInstallStep());

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
