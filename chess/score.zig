const std = @import("std");
const testing = std.testing;

const Piece = @import("pieces.zig").Piece;
const Colors = @import("colors.zig").Colors;
const Position = @import("position.zig").Position;
const ActionList = @import("actions.zig").ActionList;

const g = @import("game.zig");

fn piece_value(piece: Piece) u32 {
    return switch (piece) {
        .Pawn => 1,
        .Rook => 5,
        .UnmovedRook => 5,
        .Knight => 3,
        .Bishop => 3,
        .Queen => 9,
        .King => 1,
        .UnmovedKing => 1,
        .None => 0,
    };
}

pub const Analysis = struct {
    pieces: u32 = 0,
    can_be_attacked: u32 = 0,
    can_attack: u32 = 0,
    is_defended: u32 = 0,
    checks: u32 = 0,
};

pub fn analyze(game: *g.Game) !Analysis {
    var analysis = Analysis{};
    var i: u8 = 0;
    var king_multiplier: u32 = 0;
    while (i < 8) : (i += 1) {
        var j: u8 = 0;
        while (j < 8) : (j += 1) {
            const square = try game.board.get_square_at(Position{ .file = i, .rank = j });
            if (square.piece == Piece.None) {
                continue;
            }
            if (square.color != game.active_color) {
                continue;
            }
            if (square.piece == Piece.King or square.piece == Piece.UnmovedKing) {
                king_multiplier = 1;
            }
            const value = piece_value(square.piece);
            analysis.pieces += value;
        }
    }
    analysis.pieces *= king_multiplier;
    return analysis;
}

pub fn score(analysis: Analysis) u32 {
    return analysis.pieces;
}

test "get_score" {
    const allocator = std.testing.allocator;
    var game = g.Game{ .allocator = allocator };
    const board_setup =
        \\R...K..R
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;
    try game.board.set_up_from_string(board_setup);
    const analysis = try analyze(&game);
    try testing.expect(score(analysis) == 11);
    game.flip_player();
    const analysis2 = try analyze(&game);
    try testing.expect(score(analysis2) == 1);
    game.flip_player();
}
