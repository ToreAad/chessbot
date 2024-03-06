const std = @import("std");
const rl = @import("raylib");
const chess = @import("chess");

const ChessGraphics = @import("chess_graphics.zig").ChessGraphics;

pub fn main() !void {
    const squareSize = 64;
    const screenWidth = 10 * squareSize;
    const screenHeight = 10 * squareSize;

    rl.initWindow(screenWidth, screenHeight, "Chess Bot");
    rl.setTargetFPS(144);
    defer rl.closeWindow();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var game = chess.Game{ .allocator = gpa.allocator() };
    game.set_up();

    const board_setup =
        \\ RNBQKBNR
        \\ PPPPPPPP
        \\ ........
        \\ ........
        \\ ........
        \\ ........
        \\ pppppppp
        \\ rnbqkbnr
    ;
    try game.board.set_up_from_string(board_setup);

    var chess_graphics = try ChessGraphics.init();
    defer chess_graphics.deinit();
    var white_player = chess.agent.RandomAgent.init();
    var black_player = chess.agent.RandomAgent.init();

    var revert_action_list = std.ArrayList(chess.GameState).init(gpa.allocator());
    defer revert_action_list.deinit();

    const padding_x = (screenWidth - (8 * squareSize)) / 2;
    const padding_y = (screenHeight - (8 * squareSize)) / 2;
    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(rl.KeyboardKey.key_right)) {
            if (game.active_color == chess.Colors.White) {
                const action = try white_player.get_action(&game);
                const revert_action = try game.apply_action(action);
                try revert_action_list.append(revert_action);
            } else {
                const action = try black_player.get_action(&game);
                const revert_action = try game.apply_action(action);
                try revert_action_list.append(revert_action);
            }
        } else if (rl.isKeyPressed(rl.KeyboardKey.key_left)) {
            if (revert_action_list.items.len > 0) {
                const revert_action = revert_action_list.pop();
                game.undo_action(revert_action.revert_action());
            }
        }

        rl.beginDrawing();
        rl.clearBackground(rl.Color.light_gray);

        try chess_graphics.draw(padding_x, padding_y, squareSize, &game);

        rl.endDrawing();
    }
}
