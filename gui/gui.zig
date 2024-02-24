const std = @import("std");
const r = @cImport({
    @cInclude("raylib.h");
    @cInclude("raygui.h");
});

const chess = @import("chess");

fn draw_square(x: i32, y: i32, size: i32, color: r.Color) void {
    r.DrawRectangle(x, y, size, size, color);
}

fn draw_board(x_offset: i32, y_offset: i32, square_size: i32) void {
    var file: u8 = 0;
    while (file < 8) : (file += 1) {
        var rank: u8 = 0;
        while (rank < 8) : (rank += 1) {
            const x = file * square_size;
            const y = rank * square_size;
            const color = if ((file + rank) % 2 == 0) r.WHITE else r.DARKGRAY;
            draw_square(x_offset + x, y_offset + y, square_size, color);
        }
    }
}

const ChessSprites = struct {
    white_pawn: r.Texture2D,
    white_rook: r.Texture2D,
    white_knight: r.Texture2D,
    white_bishop: r.Texture2D,
    white_queen: r.Texture2D,
    white_king: r.Texture2D,
    black_pawn: r.Texture2D,
    black_rook: r.Texture2D,
    black_knight: r.Texture2D,
    black_bishop: r.Texture2D,
    black_queen: r.Texture2D,
    black_king: r.Texture2D,

    fn init(self: *ChessSprites) !void {
        self.white_pawn = r.LoadTexture("sprites/white_pawn.png");
        self.white_rook = r.LoadTexture("sprites/white_rook.png");
        self.white_knight = r.LoadTexture("sprites/white_knight.png");
        self.white_bishop = r.LoadTexture("sprites/white_bishop.png");
        self.white_queen = r.LoadTexture("sprites/white_queen.png");
        self.white_king = r.LoadTexture("sprites/white_king.png");
        self.black_pawn = r.LoadTexture("sprites/black_pawn.png");
        self.black_rook = r.LoadTexture("sprites/black_rook.png");
        self.black_knight = r.LoadTexture("sprites/black_knight.png");
        self.black_bishop = r.LoadTexture("sprites/black_bishop.png");
        self.black_queen = r.LoadTexture("sprites/black_queen.png");
        self.black_king = r.LoadTexture("sprites/black_king.png");
    }

    fn deinit(self: *ChessSprites) void {
        r.UnloadTexture(self.white_pawn);
        r.UnloadTexture(self.white_rook);
        r.UnloadTexture(self.white_knight);
        r.UnloadTexture(self.white_bishop);
        r.UnloadTexture(self.white_queen);
        r.UnloadTexture(self.white_king);
        r.UnloadTexture(self.black_pawn);
        r.UnloadTexture(self.black_rook);
        r.UnloadTexture(self.black_knight);
        r.UnloadTexture(self.black_bishop);
        r.UnloadTexture(self.black_queen);
        r.UnloadTexture(self.black_king);
    }

    fn draw_piece(self: *ChessSprites, x: i32, y: i32, size: i32, piece: chess.Piece, color: chess.Colors) !void {
        const tex = switch (color) {
            chess.Colors.White => switch (piece) {
                chess.Piece.Pawn => self.white_pawn,
                chess.Piece.Rook => self.white_rook,
                chess.Piece.Knight => self.white_knight,
                chess.Piece.Bishop => self.white_bishop,
                chess.Piece.Queen => self.white_queen,
                chess.Piece.King => self.white_king,
                else => {
                    return error.PieceIsNone;
                },
            },
            chess.Colors.Black => switch (piece) {
                chess.Piece.Pawn => self.black_pawn,
                chess.Piece.Rook => self.black_rook,
                chess.Piece.Knight => self.black_knight,
                chess.Piece.Bishop => self.black_bishop,
                chess.Piece.Queen => self.black_queen,
                chess.Piece.King => self.black_king,
                else => {
                    return error.PieceIsNone;
                },
            },
        };

        r.DrawTextureRec(
            tex,
            r.Rectangle{
                .x = 0,
                .y = 0,
                .width = @as(f32, @floatFromInt(size)),
                .height = @as(f32, @floatFromInt(size)),
            },
            r.Vector2{
                .x = @as(f32, @floatFromInt(x)),
                .y = @as(f32, @floatFromInt(y)),
            },
            r.WHITE,
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

    r.InitWindow(screenWidth, screenHeight, "Chess Bot");
    r.SetTargetFPS(144);
    defer r.CloseWindow();

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

    while (!r.WindowShouldClose()) {
        if (r.IsKeyPressed(r.KEY_RIGHT)) {
            if (game.active_color == chess.Colors.White) {
                const action = try white_player.get_action(&game);
                const revert_action = try game.apply_action(action);
                try revert_action_list.append(revert_action);
            } else {
                const action = try black_player.get_action(&game);
                const revert_action = try game.apply_action(action);
                try revert_action_list.append(revert_action);
            }
        } else if (r.IsKeyPressed(r.KEY_LEFT)) {
            if (revert_action_list.items.len > 0) {
                const revert_action = revert_action_list.pop();
                game.undo_action(revert_action.revert_action());
            }
        }

        r.BeginDrawing();
        r.ClearBackground(r.LIGHTGRAY);

        const padding_x = (screenWidth - (8 * squareSize)) / 2;
        const padding_y = (screenHeight - (8 * squareSize)) / 2;

        draw_board(padding_x, padding_y, squareSize);
        try sprites.draw_game(&game, padding_x, padding_y, squareSize);

        r.EndDrawing();
    }
}