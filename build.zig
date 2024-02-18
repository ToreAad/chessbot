const std = @import("std");
const raySdk = @import("vendor/raylib/src/build.zig");
const builtin = @import("builtin");

fn build_chess_lib(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) *std.Build.CompileStep {
    const test_step = b.step("test", "Run chess unit tests");

    const chess_files = [_][]const u8{
        "colors",
        "pieces",
        "position",
        "square",
        "board",
        "game",
        "rules",
        "actions",
        "score",
        "agent",
        "cli",
        "gui",
    };

    const unoptimized = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

    inline for (chess_files) |file| {
        const chess_unit_tests = b.addTest(.{
            .name = file ++ "_test",
            .root_source_file = .{ .path = "chess/" ++ file ++ ".zig" },
            .target = target,
            .optimize = unoptimized,
        });

        // install the unit test executables
        b.installArtifact(chess_unit_tests);
        const run_chess_unit_tests = b.addRunArtifact(chess_unit_tests);
        test_step.dependOn(&run_chess_unit_tests.step);
    }

    const chess_lib = b.addStaticLibrary(.{
        .name = "chess",
        .root_source_file = .{ .path = "chess/chess.zig" },
        .target = target,
        .optimize = optimize,
    });
    return chess_lib;
}

fn build_chess_gui(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) *std.Build.CompileStep {
    const gui_exe = b.addExecutable(.{
        .name = "chess-gui",
        .root_source_file = .{ .path = "chess/gui.zig" },
        .target = target,
        .optimize = optimize,
    });
    const raylib = raySdk.addRaylib(b, target, optimize, .{});
    gui_exe.addIncludePath(.{ .path = "vendor/raylib/src" });
    gui_exe.linkLibrary(raylib);

    gui_exe.addIncludePath(.{ .path = "vendor/raygui/src" });

    gui_exe.addCSourceFile(.{ .file = std.build.LazyPath.relative("vendor/raygui-amend/raygui.c"), .flags = &.{ "-g", "-O3" } }); // Add the Raygui C source file, if any
    gui_exe.linkSystemLibrary("c"); // Link with the C standard library

    b.installArtifact(gui_exe);

    const run_step = b.step("run-gui", "Run the chess gui");
    const run_cmd = b.addRunArtifact(gui_exe);
    run_step.dependOn(&run_cmd.step);
    return gui_exe;
}

fn build_chess_cli(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) *std.Build.CompileStep {
    const cli_exe = b.addExecutable(.{
        .name = "chess-cli",
        .root_source_file = .{ .path = "chess/cli.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(cli_exe);

    const run_step = b.step("run-cli", "Run the chess cli");
    const run_cmd = b.addRunArtifact(cli_exe);
    run_step.dependOn(&run_cmd.step);
    return cli_exe;
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = build_chess_gui(b, target, optimize);
    _ = build_chess_lib(b, target, optimize);
    _ = build_chess_cli(b, target, optimize);
}
