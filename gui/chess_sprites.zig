const rl = @import("raylib");
const chess = @import("chess");

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

    fn load_texture(comptime file: []const u8) !rl.Texture2D {
        const image_file = @embedFile(file);
        const image = rl.loadImageFromMemory(".png", image_file);
        defer rl.unloadImage(image);
        return rl.loadTextureFromImage(image);
    }

    pub fn init() !ChessSprites {
        const white_pawn = try load_texture("sprites/white_pawn.png");
        const white_rook = try load_texture("sprites/white_rook.png");
        const white_knight = try load_texture("sprites/white_knight.png");
        const white_bishop = try load_texture("sprites/white_bishop.png");
        const white_queen = try load_texture("sprites/white_queen.png");
        const white_king = try load_texture("sprites/white_king.png");
        const black_pawn = try load_texture("sprites/black_pawn.png");
        const black_rook = try load_texture("sprites/black_rook.png");
        const black_knight = try load_texture("sprites/black_knight.png");
        const black_bishop = try load_texture("sprites/black_bishop.png");
        const black_queen = try load_texture("sprites/black_queen.png");
        const black_king = try load_texture("sprites/black_king.png");

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

    pub fn draw_piece(self: *ChessSprites, x: f32, y: f32, size: f32, piece: chess.Piece, color: chess.Colors) !void {
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
                .width = size,
                .height = size,
            },
            rl.Vector2{
                .x = x,
                .y = y,
            },
            rl.Color.white,
        );
    }
};
