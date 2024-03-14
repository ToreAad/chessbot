const std = @import("std");
const rl = @import("raylib");
const chess = @import("chess");

const ChessSprites = @import("chess_sprites.zig").ChessSprites;
const GuiState = @import("gui_state.zig").GuiState;

pub const ChessGraphics = struct {
    chess_sprites: ChessSprites,

    pub fn init() !ChessGraphics {
        const chess_sprites = try ChessSprites.init();
        return ChessGraphics{ .chess_sprites = chess_sprites };
    }

    pub fn deinit(self: *ChessGraphics) void {
        self.chess_sprites.deinit();
    }

    fn draw_sprites(
        self: *ChessGraphics,
        state: *GuiState,
    ) !void {
        var file: u8 = 0;
        while (file < 8) : (file += 1) {
            var rank: u8 = 0;
            while (rank < 8) : (rank += 1) {
                const pos = chess.Position{
                    .file = file,
                    .rank = rank,
                };
                const square = try state.game.board.get_square_at(pos);
                if (square.empty) {
                    continue;
                }
                const index = (rank * 8) + file;
                const tile = state.tiles[index];
                const x = tile.rect.x;
                const y = tile.rect.y;
                const square_size = tile.rect.width;

                try self.chess_sprites.draw_piece(x, y, square_size, square.piece, square.color);
            }
        }
    }

    pub fn draw(
        self: *ChessGraphics,
        state: *GuiState,
    ) !void {
        for (state.tiles) |tile| {
            tile.draw();
        }
        try self.draw_sprites(state);
    }
};
