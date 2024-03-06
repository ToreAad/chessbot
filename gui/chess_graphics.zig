const std = @import("std");
const rl = @import("raylib");
const chess = @import("chess");

const ChessSprites = @import("chess_sprites.zig").ChessSprites;
const draw_board = @import("chess_board.zig").draw_board;

pub const ChessGraphics = struct {
    chess_sprites: ChessSprites,

    pub fn init() !ChessGraphics {
        const chess_sprites = try ChessSprites.init();
        return ChessGraphics{ .chess_sprites = chess_sprites };
    }

    pub fn deinit(self: *ChessGraphics) void {
        self.chess_sprites.deinit();
    }

    pub fn draw(
        self: *ChessGraphics,
        x_offset: i32,
        y_offset: i32,
        square_size: i32,
        game: *chess.Game,
    ) !void {
        draw_board(x_offset, y_offset, square_size);
        try self.chess_sprites.draw_game(game, x_offset, y_offset, square_size);
    }
};
