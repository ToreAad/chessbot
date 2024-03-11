const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");
const ChessGame = @import("chess_game.zig").ChessGame;

pub fn main() !void {
    const squareSize = 64;
    const screenWidth = 10 * squareSize;
    const screenHeight = 10 * squareSize;

    rl.initWindow(screenWidth, screenHeight, "Chess Bot");
    defer rl.closeWindow();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var game = try ChessGame.init(squareSize, allocator);
    defer game.deinit();

    if (builtin.os.tag == .emscripten) {
        const emscripten = std.os.emscripten;
        emscripten.emscripten_set_main_loop_arg(
            game.update_draw_frame,
            &game,
            60,
            true,
        );
    } else {
        rl.setTargetFPS(60);
        while (!rl.windowShouldClose()) {
            try game.update_draw_frame();
        }
    }
}
