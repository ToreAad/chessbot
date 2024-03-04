const std = @import("std");
const rl = @import("raylib");

const chess = @import("chess");

fn draw_square(x: i32, y: i32, size: i32, color: rl.Color) void {
    rl.drawRectangle(x, y, size, size, color);
}

fn draw_board(x_offset: i32, y_offset: i32, square_size: i32) void {
    var file: u8 = 0;
    while (file < 8) : (file += 1) {
        var rank: u8 = 0;
        while (rank < 8) : (rank += 1) {
            const x = file * square_size;
            const y = rank * square_size;
            const color = if ((file + rank) % 2 == 0) rl.Color.white else rl.Color.dark_gray;
            draw_square(x_offset + x, y_offset + y, square_size, color);
        }
    }
}

const ChessSprites = struct {
    white_pawn: rl.Texture2D,
    white_rook: rl.Texture2D,
    white_knight: rl.Texture2D,
    white_bishop: rl.Texture2D,
    white_queen: rl.Texture2D,
    white_king: rl.Texture2D,
    black_pawn: rl.Texture2D,
    black_rook: rl.Texture2D,
    black_knight: rl.Texture2D,
    black_bishop: rl.Texture2D,
    black_queen: rl.Texture2D,
    black_king: rl.Texture2D,

    fn init(self: *ChessSprites) !void {
        self.white_pawn = rl.loadTexture("sprites/white_pawn.png");
        self.white_rook = rl.loadTexture("sprites/white_rook.png");
        self.white_knight = rl.loadTexture("sprites/white_knight.png");
        self.white_bishop = rl.loadTexture("sprites/white_bishop.png");
        self.white_queen = rl.loadTexture("sprites/white_queen.png");
        self.white_king = rl.loadTexture("sprites/white_king.png");
        self.black_pawn = rl.loadTexture("sprites/black_pawn.png");
        self.black_rook = rl.loadTexture("sprites/black_rook.png");
        self.black_knight = rl.loadTexture("sprites/black_knight.png");
        self.black_bishop = rl.loadTexture("sprites/black_bishop.png");
        self.black_queen = rl.loadTexture("sprites/black_queen.png");
        self.black_king = rl.loadTexture("sprites/black_king.png");
    }

    fn deinit(self: *ChessSprites) void {
        rl.unloadTexture(self.white_pawn);
        rl.unloadTexture(self.white_rook);
        rl.unloadTexture(self.white_knight);
        rl.unloadTexture(self.white_bishop);
        rl.unloadTexture(self.white_queen);
        rl.unloadTexture(self.white_king);
        rl.unloadTexture(self.black_pawn);
        rl.unloadTexture(self.black_rook);
        rl.unloadTexture(self.black_knight);
        rl.unloadTexture(self.black_bishop);
        rl.unloadTexture(self.black_queen);
        rl.unloadTexture(self.black_king);
    }

    fn draw_piece(self: *ChessSprites, x: i32, y: i32, size: i32, piece: chess.Piece, color: chess.Colors) !void {
        const tex = switch (color) {
            chess.Colors.White => switch (piece) {
                chess.Piece.Pawn => self.white_pawn,
                chess.Piece.Rook => self.white_rook,
                chess.Piece.UnmovedRook => self.white_rook,
                chess.Piece.Knight => self.white_knight,
                chess.Piece.Bishop => self.white_bishop,
                chess.Piece.Queen => self.white_queen,
                chess.Piece.King => self.white_king,
                chess.Piece.UnmovedKing => self.white_king,
                else => {
                    return error.PieceIsNone;
                },
            },
            chess.Colors.Black => switch (piece) {
                chess.Piece.Pawn => self.black_pawn,
                chess.Piece.Rook => self.black_rook,
                chess.Piece.UnmovedRook => self.black_rook,
                chess.Piece.Knight => self.black_knight,
                chess.Piece.Bishop => self.black_bishop,
                chess.Piece.Queen => self.black_queen,
                chess.Piece.King => self.black_king,
                chess.Piece.UnmovedKing => self.black_king,
                else => {
                    return error.PieceIsNone;
                },
            },
        };

        rl.drawTextureRec(
            tex,
            rl.Rectangle{
                .x = 0,
                .y = 0,
                .width = @as(f32, @floatFromInt(size)),
                .height = @as(f32, @floatFromInt(size)),
            },
            rl.Vector2{
                .x = @as(f32, @floatFromInt(x)),
                .y = @as(f32, @floatFromInt(y)),
            },
            rl.Color.white,
        );
    }

    fn draw_game(self: *ChessSprites, game: *chess.Game, x_offset: i32, y_offset: i32, square_size: i32) !void {
        var file: u8 = 0;
        while (file < 8) : (file += 1) {
            var rank: u8 = 0;
            while (rank < 8) : (rank += 1) {
                const pos = chess.Position{
                    .file = file,
                    .rank = rank,
                };
                const square = try game.board.get_square_at(pos);
                if (square.empty) {
                    continue;
                }
                const x = file * square_size;
                const y = rank * square_size;
                try self.draw_piece(x_offset + x, y_offset + y, square_size, square.piece, square.color);
            }
        }
    }
};

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

    var sprites: ChessSprites = undefined;
    try sprites.init();
    defer sprites.deinit();
    var white_player: chess.agent.RandomAgent = undefined;
    var black_player: chess.agent.RandomAgent = undefined;
    white_player.init();
    black_player.init();

    var revert_action_list = std.ArrayList(chess.GameState).init(gpa.allocator());
    defer revert_action_list.deinit();

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

        const padding_x = (screenWidth - (8 * squareSize)) / 2;
        const padding_y = (screenHeight - (8 * squareSize)) / 2;

        draw_board(padding_x, padding_y, squareSize);
        try sprites.draw_game(&game, padding_x, padding_y, squareSize);

        rl.endDrawing();
    }
}
