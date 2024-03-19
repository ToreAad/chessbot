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

    fn draw_menu(
        self: *ChessGraphics,
        state: *GuiState,
    ) !void {
        _ = state;
        _ = self;
        const screenWidth = rl.getScreenWidth();
        const screenHeight = rl.getScreenHeight();
        const fontSize = 20;
        const text = "Press space to start the game";
        const textWidth = rl.measureText(text, fontSize);
        const x = @divTrunc((screenWidth - textWidth), 2);
        const y = @divTrunc(screenHeight, 2);
        rl.drawText(text, x, y, fontSize, rl.Color.white);
    }

    fn draw_gameplay(
        self: *ChessGraphics,
        state: *GuiState,
    ) !void {
        for (state.tiles) |tile| {
            tile.draw();
        }
        try self.draw_sprites(state);
    }

    fn draw_ending(
        self: *ChessGraphics,
        state: *GuiState,
    ) !void {
        _ = state;
        _ = self;
        const screenWidth = rl.getScreenWidth();
        const screenHeight = rl.getScreenHeight();
        const fontSize = 20;
        const text = "Press space to restart the game";
        const textWidth = rl.measureText(text, fontSize);
        const x = @divTrunc((screenWidth - textWidth), 2);
        const y = @divTrunc(screenHeight, 2);
        rl.drawText(text, x, y, fontSize, rl.Color.white);
    }

    pub fn draw(
        self: *ChessGraphics,
        state: *GuiState,
    ) !void {
        switch (state.screen) {
            .Menu => try self.draw_menu(state),
            .Gameplay => try self.draw_gameplay(state),
            .Ending => try self.draw_ending(state),
        }
    }
};
