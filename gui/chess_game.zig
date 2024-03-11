const std = @import("std");
const rl = @import("raylib");
const chess = @import("chess");
const ChessGraphics = @import("chess_graphics.zig").ChessGraphics;

pub const ChessGame = struct {
    game: chess.Game,
    chess_graphics: ChessGraphics,
    white_player: chess.agent.RandomAgent,
    black_player: chess.agent.RandomAgent,
    revert_action_list: std.ArrayList(chess.GameState),
    padding_x: i32,
    padding_y: i32,
    squareSize: i32,
    screenWidth: i32,
    screenHeight: i32,
    allocator: std.mem.Allocator,

    pub fn init(
        squareSize: i32,
        allocator: std.mem.Allocator,
    ) !ChessGame {
        const screenWidth = 10 * squareSize;
        const screenHeight = 10 * squareSize;

        var game = chess.Game{ .allocator = allocator };
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

        const chess_graphics = try ChessGraphics.init();
        const white_player = chess.agent.RandomAgent.init();
        const black_player = chess.agent.RandomAgent.init();

        const revert_action_list = std.ArrayList(chess.GameState).init(allocator);

        const padding_x = @divTrunc((screenWidth - (8 * squareSize)), 2);
        const padding_y = @divTrunc((screenHeight - (8 * squareSize)), 2);

        return ChessGame{
            .game = game,
            .chess_graphics = chess_graphics,
            .white_player = white_player,
            .black_player = black_player,
            .revert_action_list = revert_action_list,
            .padding_x = padding_x,
            .padding_y = padding_y,
            .squareSize = squareSize,
            .screenWidth = screenWidth,
            .screenHeight = screenHeight,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ChessGame) void {
        self.chess_graphics.deinit();
        self.revert_action_list.deinit();
    }

    pub fn update_draw_frame(self: *ChessGame) !void {
        if (rl.isKeyPressed(rl.KeyboardKey.key_right)) {
            if (self.game.active_color == chess.Colors.White) {
                const action = try self.white_player.get_action(&self.game);
                const revert_action = try self.game.apply_action(action);
                try self.revert_action_list.append(revert_action);
            } else {
                const action = try self.black_player.get_action(&self.game);
                const revert_action = try self.game.apply_action(action);
                try self.revert_action_list.append(revert_action);
            }
        } else if (rl.isKeyPressed(rl.KeyboardKey.key_left)) {
            if (self.revert_action_list.items.len > 0) {
                const revert_action = self.revert_action_list.pop();
                self.game.undo_action(revert_action.revert_action());
            }
        }

        rl.beginDrawing();
        rl.clearBackground(rl.Color.light_gray);
        try self.chess_graphics.draw(self.padding_x, self.padding_y, self.squareSize, &self.game);
        rl.endDrawing();
    }
};
