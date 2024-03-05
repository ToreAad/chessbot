const std = @import("std");
const rl = @import("vendor/raylib-zig/build.zig");
const builtin = @import("builtin");

pub fn build_chess_web(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) !void {
    const raylib = rl.getModule(b, "vendor/raylib-zig");
    const raylib_math = rl.math.getModule(b, "vendor/raylib-zig");

    const exe_lib = rl.compileForEmscripten(b, "'$PROJECT_NAME'", "gui/gui.zig", target, optimize);
    exe_lib.addModule("raylib", raylib);
    exe_lib.addModule("raylib-math", raylib_math);

    const chess_module = b.addModule("chess", .{
        .source_file = .{ .path = "chess/chess.zig" },
    });
    exe_lib.addModule("chess", chess_module);
    const raylib_artifact = rl.getRaylib(b, target, optimize);
    // Note that raylib itself is not actually added to the exe_lib output file, so it also needs to be linked with emscripten.
    exe_lib.linkLibrary(raylib_artifact);
    const link_step = try rl.linkWithEmscripten(b, &[_]*std.Build.Step.Compile{ exe_lib, raylib_artifact });
    b.getInstallStep().dependOn(&link_step.step);
    const run_step = try rl.emscriptenRunStep(b);
    run_step.step.dependOn(&link_step.step);
    const run_option = b.step("run-web", "Run web");
    run_option.dependOn(&run_step.step);
}

pub fn link_raylib(exe: *std.Build.Step.Compile, b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) !void {
    const raylib = rl.getModule(b, "vendor/raylib-zig");
    const raylib_math = rl.math.getModule(b, "vendor/raylib-zig");

    rl.link(b, exe, target, optimize);
    exe.addModule("raylib", raylib);
    exe.addModule("raylib-math", raylib_math);
}

fn build_chess_tests(b: *std.Build, target: std.zig.CrossTarget) void {
    const test_step = b.step("test", "Run chess unit tests");

    const NameAndPath = struct {
        name: []const u8,
        path: []const u8,
    };

    const test_files = [_]NameAndPath{
        .{ .name = "colors", .path = "chess/colors.zig" },
        .{ .name = "pieces", .path = "chess/pieces.zig" },
        .{ .name = "position", .path = "chess/position.zig" },
        .{ .name = "square", .path = "chess/square.zig" },
        .{ .name = "board", .path = "chess/board.zig" },
        .{ .name = "game", .path = "chess/game.zig" },
        .{ .name = "rules", .path = "chess/rules.zig" },
        .{ .name = "actions", .path = "chess/actions.zig" },
        .{ .name = "score", .path = "chess/score.zig" },
        .{ .name = "agent", .path = "chess/agent.zig" },
        .{ .name = "cli", .path = "cli/cli.zig" },
        .{ .name = "gui", .path = "gui/gui.zig" },
    };

    const unoptimized = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

    inline for (test_files) |file| {
        const chess_unit_tests = b.addTest(.{
            .name = file.name ++ "_test",
            .root_source_file = .{ .path = file.path },
            .target = target,
            .optimize = unoptimized,
        });

        // install the unit test executables
        b.installArtifact(chess_unit_tests);
        const run_chess_unit_tests = b.addRunArtifact(chess_unit_tests);
        test_step.dependOn(&run_chess_unit_tests.step);
    }
}

fn build_chess_lib(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) *std.Build.CompileStep {
    const chess_lib = b.addSharedLibrary(.{
        .name = "chesslib",
        .root_source_file = .{ .path = "chess/chess.zig" },
        .target = target,
        .optimize = optimize,
    });
    const chess_module = b.addModule("chess", .{
        .source_file = .{ .path = "chess/chess.zig" },
    });

    chess_lib.addModule("chess", chess_module);
    return chess_lib;
}

fn build_chess_gui(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) *std.Build.CompileStep {
    const gui_exe = b.addExecutable(.{
        .name = "chess-gui",
        .root_source_file = .{ .path = "gui/gui.zig" },
        .target = target,
        .optimize = optimize,
    });
    const chess_module = b.addModule("chess", .{
        .source_file = .{ .path = "chess/chess.zig" },
    });

    gui_exe.addModule("chess", chess_module);
    try link_raylib(gui_exe, b, target, optimize);

    const install_content_step = b.addInstallDirectory(.{
        .source_dir = .{ .path = "gui/sprites/" },
        .install_dir = .{ .custom = "" },
        .install_subdir = "bin/" ++ "sprites",
    });

    gui_exe.step.dependOn(&install_content_step.step);
    b.installArtifact(gui_exe);

    const run_step = b.step("run-gui", "Run the chess gui");
    const run_cmd = b.addRunArtifact(gui_exe);
    run_cmd.cwd = std.build.LazyPath.relative("zig-out/bin/");

    run_step.dependOn(&run_cmd.step);
    return gui_exe;
}

fn build_chess_cli(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) *std.Build.CompileStep {
    const cli_exe = b.addExecutable(.{
        .name = "chess-cli",
        .root_source_file = .{ .path = "cli/cli.zig" },
        .target = target,
        .optimize = optimize,
    });

    const chess_module = b.addModule("chess", .{
        .source_file = .{ .path = "chess/chess.zig" },
    });

    cli_exe.addModule("chess", chess_module);

    b.installArtifact(cli_exe);

    const run_step = b.step("run-cli", "Run the chess cli");
    const run_cmd = b.addRunArtifact(cli_exe);
    run_step.dependOn(&run_cmd.step);
    return cli_exe;
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    build_chess_tests(b, target);
    _ = build_chess_gui(b, target, optimize);
    _ = build_chess_lib(b, target, optimize);
    _ = build_chess_cli(b, target, optimize);
    // if building for for emscripten then build the web version

    if (target.getOsTag() == .emscripten) {
        _ = try build_chess_web(b, target, optimize);
    }
}
