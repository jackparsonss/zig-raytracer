const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Get libxml2 flags from pkg-config
    const xml2_cflags = b.run(&.{ "pkg-config", "--cflags", "libxml-2.0" });

    const mod = b.addModule("raytracer", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    // Link to the module that uses @cImport
    mod.linkSystemLibrary("xml2", .{});

    // Parse and add include paths from pkg-config
    var it = std.mem.tokenizeScalar(u8, xml2_cflags, ' ');
    while (it.next()) |flag| {
        if (std.mem.startsWith(u8, flag, "-I")) {
            const path = flag[2..];
            mod.addIncludePath(.{ .cwd_relative = path });
        }
    }

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

    // Add include path to exe as well
    it = std.mem.tokenizeScalar(u8, xml2_cflags, ' ');
    while (it.next()) |flag| {
        if (std.mem.startsWith(u8, flag, "-I")) {
            const path = flag[2..];
            exe.root_module.addIncludePath(.{ .cwd_relative = path });
        }
    }

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
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

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
