const std = @import("std");
const rl = @import("raylib");
const chess = @import("chess");
const ChessGraphics = @import("chess_graphics.zig").ChessGraphics;
const GuiState = @import("gui_state.zig").GuiState;

pub const ChessGame = struct {
    state: GuiState,
    chess_graphics: ChessGraphics,

    pub fn init(
        squareSize: i32,
        allocator: std.mem.Allocator,
    ) !ChessGame {
        const chess_graphics = try ChessGraphics.init();

        const offset_x = squareSize;
        const offset_y = squareSize;

        const gui_state = try GuiState.init(
            allocator,
            offset_x,
            offset_y,
            squareSize,
        );

        return ChessGame{
            .state = gui_state,
            .chess_graphics = chess_graphics,
        };
    }

    pub fn deinit(self: *ChessGame) void {
        self.chess_graphics.deinit();
    }

    pub fn update_draw_frame(self: *ChessGame) !void {
        try self.state.update();

        rl.beginDrawing();
        rl.clearBackground(rl.Color.light_gray);
        try self.chess_graphics.draw(&self.state);
        rl.endDrawing();
    }
};
