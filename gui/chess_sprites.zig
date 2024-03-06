const rl = @import("raylib");
const chess = @import("chess");

const white_pawn_file = @embedFile("sprites/white_pawn.png");
const white_rook_file = @embedFile("sprites/white_rook.png");
const white_knight_file = @embedFile("sprites/white_knight.png");
const white_bishop_file = @embedFile("sprites/white_bishop.png");
const white_queen_file = @embedFile("sprites/white_queen.png");
const white_king_file = @embedFile("sprites/white_king.png");
const black_pawn_file = @embedFile("sprites/black_pawn.png");
const black_rook_file = @embedFile("sprites/black_rook.png");
const black_knight_file = @embedFile("sprites/black_knight.png");
const black_bishop_file = @embedFile("sprites/black_bishop.png");
const black_queen_file = @embedFile("sprites/black_queen.png");
const black_king_file = @embedFile("sprites/black_king.png");

pub const ChessSprites = struct {
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

    pub fn init() !ChessSprites {
        const white_pawn_image = rl.loadImageFromMemory(".png", white_pawn_file);
        defer rl.unloadImage(white_pawn_image);
        const white_pawn = rl.loadTextureFromImage(white_pawn_image);

        const white_rook_image = rl.loadImageFromMemory(".png", white_rook_file);
        defer rl.unloadImage(white_rook_image);
        const white_rook = rl.loadTextureFromImage(white_rook_image);

        const white_knight_image = rl.loadImageFromMemory(".png", white_knight_file);
        defer rl.unloadImage(white_knight_image);
        const white_knight = rl.loadTextureFromImage(white_knight_image);

        const white_bishop_image = rl.loadImageFromMemory(".png", white_bishop_file);
        defer rl.unloadImage(white_bishop_image);
        const white_bishop = rl.loadTextureFromImage(white_bishop_image);

        const white_queen_image = rl.loadImageFromMemory(".png", white_queen_file);
        defer rl.unloadImage(white_queen_image);
        const white_queen = rl.loadTextureFromImage(white_queen_image);

        const white_king_image = rl.loadImageFromMemory(".png", white_king_file);
        defer rl.unloadImage(white_king_image);
        const white_king = rl.loadTextureFromImage(white_king_image);

        const black_pawn_image = rl.loadImageFromMemory(".png", black_pawn_file);
        defer rl.unloadImage(black_pawn_image);
        const black_pawn = rl.loadTextureFromImage(black_pawn_image);

        const black_rook_image = rl.loadImageFromMemory(".png", black_rook_file);
        defer rl.unloadImage(black_rook_image);
        const black_rook = rl.loadTextureFromImage(black_rook_image);

        const black_knight_image = rl.loadImageFromMemory(".png", black_knight_file);
        defer rl.unloadImage(black_knight_image);
        const black_knight = rl.loadTextureFromImage(black_knight_image);

        const black_bishop_image = rl.loadImageFromMemory(".png", black_bishop_file);
        defer rl.unloadImage(black_bishop_image);
        const black_bishop = rl.loadTextureFromImage(black_bishop_image);

        const black_queen_image = rl.loadImageFromMemory(".png", black_queen_file);
        defer rl.unloadImage(black_queen_image);
        const black_queen = rl.loadTextureFromImage(black_queen_image);

        const black_king_image = rl.loadImageFromMemory(".png", black_king_file);
        defer rl.unloadImage(black_king_image);
        const black_king = rl.loadTextureFromImage(black_king_image);

        return ChessSprites{
            .white_pawn = white_pawn,
            .white_rook = white_rook,
            .white_knight = white_knight,
            .white_bishop = white_bishop,
            .white_queen = white_queen,
            .white_king = white_king,
            .black_pawn = black_pawn,
            .black_rook = black_rook,
            .black_knight = black_knight,
            .black_bishop = black_bishop,
            .black_queen = black_queen,
            .black_king = black_king,
        };
    }

    pub fn deinit(self: *ChessSprites) void {
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

    pub fn draw_game(self: *ChessSprites, game: *chess.Game, x_offset: i32, y_offset: i32, square_size: i32) !void {
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
