const std = @import("std");
const testing = std.testing;

const Position = struct {
    file: u8,
    rank: u8,
};

const W_QR1 = Position{ .file = 0, .rank = 0 };
const W_QN1 = Position{ .file = 1, .rank = 0 };
const W_QB1 = Position{ .file = 2, .rank = 0 };
const W_Q1 = Position{ .file = 3, .rank = 0 };
const W_K1 = Position{ .file = 4, .rank = 0 };
const W_KB1 = Position{ .file = 5, .rank = 0 };
const W_KN1 = Position{ .file = 6, .rank = 0 };
const W_KR1 = Position{ .file = 7, .rank = 0 };
const W_QR2 = Position{ .file = 0, .rank = 1 };
const W_QN2 = Position{ .file = 1, .rank = 1 };
const W_QB2 = Position{ .file = 2, .rank = 1 };
const W_Q2 = Position{ .file = 3, .rank = 1 };
const W_K2 = Position{ .file = 4, .rank = 1 };
const W_KB2 = Position{ .file = 5, .rank = 1 };
const W_KN2 = Position{ .file = 6, .rank = 1 };
const W_KR2 = Position{ .file = 7, .rank = 1 };

const B_QR1 = Position{ .file = 0, .rank = 7 };
const B_QN1 = Position{ .file = 1, .rank = 7 };
const B_QB1 = Position{ .file = 2, .rank = 7 };
const B_Q1 = Position{ .file = 3, .rank = 7 };
const B_K1 = Position{ .file = 4, .rank = 7 };
const B_KB1 = Position{ .file = 5, .rank = 7 };
const B_KN1 = Position{ .file = 6, .rank = 7 };
const B_KR1 = Position{ .file = 7, .rank = 7 };
const B_QR2 = Position{ .file = 0, .rank = 6 };
const B_QN2 = Position{ .file = 1, .rank = 6 };
const B_QB2 = Position{ .file = 2, .rank = 6 };
const B_Q2 = Position{ .file = 3, .rank = 6 };
const B_K2 = Position{ .file = 4, .rank = 6 };
const B_KB2 = Position{ .file = 5, .rank = 6 };
const B_KN2 = Position{ .file = 6, .rank = 6 };
const B_KR2 = Position{ .file = 7, .rank = 6 };

const SquareFlags = enum(u32) {
    Black = 0b10,
    Pawn = 0b100,
    Knight = 0b1000,
    Bishop = 0b10000,
    Rook = 0b100000,
    Queen = 0b1000000,
    King = 0b10000000,
    Moved = 0b100000000,
};

const Piece = enum(u32) {
    Pawn = @intFromEnum(SquareFlags.Pawn),
    Knight = @intFromEnum(SquareFlags.Knight),
    Bishop = @intFromEnum(SquareFlags.Bishop),
    Rook = @intFromEnum(SquareFlags.Rook),
    Queen = @intFromEnum(SquareFlags.Queen),
    King = @intFromEnum(SquareFlags.King),
};

const Colors = enum(u32) {
    White = 0,
    Black = @intFromEnum(SquareFlags.Black),
};

fn is_occupied(state: u32) bool {
    return state > 0;
}

fn is_empty(state: u32) bool {
    return state == 0;
}

fn set_white(state: u32) u32 {
    return state ^ @intFromEnum(SquareFlags.Black);
}

fn set_black(state: u32) u32 {
    return state | @intFromEnum(SquareFlags.Black);
}

fn is_black(state: u32) bool {
    return (state & @intFromEnum(SquareFlags.Black)) > 0;
}

fn is_white(state: u32) bool {
    return (state & @intFromEnum(SquareFlags.Black)) == 0;
}

fn get_color(state: u32) Colors {
    if (is_black(state)) {
        return Colors.Black;
    } else {
        return Colors.White;
    }
}

fn set_moved(state: u32) u32 {
    return state | @intFromEnum(SquareFlags.Moved);
}

fn is_moved(state: u32) bool {
    return (state & @intFromEnum(SquareFlags.Moved)) > 0;
}

fn get_piece(state: u32) Piece {
    const val = state & 0b11111100;
    return @enumFromInt(val);
}

fn set_piece(state: u32, piece: Piece) u32 {
    return state | @intFromEnum(piece);
}

const Move = struct {
    from: Position,
    to: Position,
};

const Board = struct {
    pieces: [8][8]u32 = [8][8]u32{
        [8]u32{ 0, 0, 0, 0, 0, 0, 0, 0 },
        [8]u32{ 0, 0, 0, 0, 0, 0, 0, 0 },
        [8]u32{ 0, 0, 0, 0, 0, 0, 0, 0 },
        [8]u32{ 0, 0, 0, 0, 0, 0, 0, 0 },
        [8]u32{ 0, 0, 0, 0, 0, 0, 0, 0 },
        [8]u32{ 0, 0, 0, 0, 0, 0, 0, 0 },
        [8]u32{ 0, 0, 0, 0, 0, 0, 0, 0 },
        [8]u32{ 0, 0, 0, 0, 0, 0, 0, 0 },
    },

    fn set_up(board: *Board) void {
        var file: u8 = 0;
        while (file < 8) : (file += 1) {
            var rank: u8 = 0;
            while (rank < 8) : (rank += 1) {
                board.pieces[file][rank] = 0;
            }
        }

        board.pieces[W_QR1.file][W_QR1.rank] = set_piece(board.pieces[W_QR1.file][W_QR1.rank], Piece.Rook);
        board.pieces[W_QN1.file][W_QN1.rank] = set_piece(board.pieces[W_QN1.file][W_QN1.rank], Piece.Knight);
        board.pieces[W_QB1.file][W_QB1.rank] = set_piece(board.pieces[W_QB1.file][W_QB1.rank], Piece.Bishop);
        board.pieces[W_Q1.file][W_Q1.rank] = set_piece(board.pieces[W_Q1.file][W_Q1.rank], Piece.Queen);
        board.pieces[W_K1.file][W_K1.rank] = set_piece(board.pieces[W_K1.file][W_K1.rank], Piece.King);
        board.pieces[W_KB1.file][W_KB1.rank] = set_piece(board.pieces[W_KB1.file][W_KB1.rank], Piece.Bishop);
        board.pieces[W_KN1.file][W_KN1.rank] = set_piece(board.pieces[W_KN1.file][W_KN1.rank], Piece.Knight);
        board.pieces[W_KR1.file][W_KR1.rank] = set_piece(board.pieces[W_KR1.file][W_KR1.rank], Piece.Rook);
        board.pieces[W_QR2.file][W_QR2.rank] = set_piece(board.pieces[W_QR2.file][W_QR2.rank], Piece.Pawn);
        board.pieces[W_QN2.file][W_QN2.rank] = set_piece(board.pieces[W_QN2.file][W_QN2.rank], Piece.Pawn);
        board.pieces[W_QB2.file][W_QB2.rank] = set_piece(board.pieces[W_QB2.file][W_QB2.rank], Piece.Pawn);
        board.pieces[W_Q2.file][W_Q2.rank] = set_piece(board.pieces[W_Q2.file][W_Q2.rank], Piece.Pawn);
        board.pieces[W_K2.file][W_K2.rank] = set_piece(board.pieces[W_K2.file][W_K2.rank], Piece.Pawn);
        board.pieces[W_KB2.file][W_KB2.rank] = set_piece(board.pieces[W_KB2.file][W_KB2.rank], Piece.Pawn);
        board.pieces[W_KN2.file][W_KN2.rank] = set_piece(board.pieces[W_KN2.file][W_KN2.rank], Piece.Pawn);
        board.pieces[W_KR2.file][W_KR2.rank] = set_piece(board.pieces[W_KR2.file][W_KR2.rank], Piece.Pawn);

        board.pieces[B_QR1.file][B_QR1.rank] = set_black(set_piece(board.pieces[B_QR1.file][B_QR1.rank], Piece.Rook));
        board.pieces[B_QN1.file][B_QN1.rank] = set_black(set_piece(board.pieces[B_QN1.file][B_QN1.rank], Piece.Knight));
        board.pieces[B_QB1.file][B_QB1.rank] = set_black(set_piece(board.pieces[B_QB1.file][B_QB1.rank], Piece.Bishop));
        board.pieces[B_Q1.file][B_Q1.rank] = set_black(set_piece(board.pieces[B_Q1.file][B_Q1.rank], Piece.Queen));
        board.pieces[B_K1.file][B_K1.rank] = set_black(set_piece(board.pieces[B_K1.file][B_K1.rank], Piece.King));
        board.pieces[B_KB1.file][B_KB1.rank] = set_black(set_piece(board.pieces[B_KB1.file][B_KB1.rank], Piece.Bishop));
        board.pieces[B_KN1.file][B_KN1.rank] = set_black(set_piece(board.pieces[B_KN1.file][B_KN1.rank], Piece.Knight));
        board.pieces[B_KR1.file][B_KR1.rank] = set_black(set_piece(board.pieces[B_KR1.file][B_KR1.rank], Piece.Rook));
        board.pieces[B_QR2.file][B_QR2.rank] = set_black(set_piece(board.pieces[B_QR2.file][B_QR2.rank], Piece.Pawn));
        board.pieces[B_QN2.file][B_QN2.rank] = set_black(set_piece(board.pieces[B_QN2.file][B_QN2.rank], Piece.Pawn));
        board.pieces[B_QB2.file][B_QB2.rank] = set_black(set_piece(board.pieces[B_QB2.file][B_QB2.rank], Piece.Pawn));
        board.pieces[B_Q2.file][B_Q2.rank] = set_black(set_piece(board.pieces[B_Q2.file][B_Q2.rank], Piece.Pawn));
        board.pieces[B_K2.file][B_K2.rank] = set_black(set_piece(board.pieces[B_K2.file][B_K2.rank], Piece.Pawn));
        board.pieces[B_KB2.file][B_KB2.rank] = set_black(set_piece(board.pieces[B_KB2.file][B_KB2.rank], Piece.Pawn));
        board.pieces[B_KN2.file][B_KN2.rank] = set_black(set_piece(board.pieces[B_KN2.file][B_KN2.rank], Piece.Pawn));
        board.pieces[B_KR2.file][B_KR2.rank] = set_black(set_piece(board.pieces[B_KR2.file][B_KR2.rank], Piece.Pawn));
    }
};

test "Board init" {
    // var allocator = testing.allocator;
    var board: Board = Board{};
    board.set_up();

    // defer allocator.free(board);

    // test empty squares

    var file: u8 = 0;
    while (file < 8) : (file += 1) {
        var rank: u8 = 2;
        while (rank < 6) : (rank += 1) {
            const state = board.pieces[file][rank];
            try testing.expect(is_empty(state));
        }
    }

    try testing.expect(get_piece(board.pieces[0][0]) == Piece.Rook);
    try testing.expect(get_color(board.pieces[0][0]) == Colors.White);
    try testing.expect(is_occupied(board.pieces[0][0]));
    try testing.expect(!is_moved(board.pieces[0][0]));

    try testing.expect(get_piece(board.pieces[1][0]) == Piece.Knight);
    try testing.expect(get_color(board.pieces[1][0]) == Colors.White);
    try testing.expect(is_occupied(board.pieces[1][0]));
    try testing.expect(!is_moved(board.pieces[1][0]));

    try testing.expect(get_piece(board.pieces[2][0]) == Piece.Bishop);
    try testing.expect(get_color(board.pieces[2][0]) == Colors.White);
    try testing.expect(is_occupied(board.pieces[2][0]));
    try testing.expect(!is_moved(board.pieces[2][0]));

    try testing.expect(get_piece(board.pieces[3][0]) == Piece.Queen);
    try testing.expect(get_color(board.pieces[3][0]) == Colors.White);
    try testing.expect(is_occupied(board.pieces[3][0]));
    try testing.expect(!is_moved(board.pieces[3][0]));

    try testing.expect(get_piece(board.pieces[4][0]) == Piece.King);
    try testing.expect(get_color(board.pieces[4][0]) == Colors.White);
    try testing.expect(is_occupied(board.pieces[4][0]));
    try testing.expect(!is_moved(board.pieces[4][0]));

    try testing.expect(get_piece(board.pieces[5][0]) == Piece.Bishop);
    try testing.expect(get_color(board.pieces[5][0]) == Colors.White);
    try testing.expect(is_occupied(board.pieces[5][0]));
    try testing.expect(!is_moved(board.pieces[5][0]));

    try testing.expect(get_piece(board.pieces[6][0]) == Piece.Knight);
    try testing.expect(get_color(board.pieces[6][0]) == Colors.White);
    try testing.expect(is_occupied(board.pieces[6][0]));
    try testing.expect(!is_moved(board.pieces[6][0]));

    try testing.expect(get_piece(board.pieces[7][0]) == Piece.Rook);
    try testing.expect(get_color(board.pieces[7][0]) == Colors.White);
    try testing.expect(is_occupied(board.pieces[7][0]));
    try testing.expect(!is_moved(board.pieces[7][0]));

    file = 0;
    while (file < 8) : (file += 1) {
        try testing.expect(get_piece(board.pieces[file][1]) == Piece.Pawn);
        try testing.expect(get_color(board.pieces[file][1]) == Colors.White);
        try testing.expect(is_occupied(board.pieces[file][1]));
        try testing.expect(!is_moved(board.pieces[file][1]));
    }

    try testing.expect(get_piece(board.pieces[0][7]) == Piece.Rook);
    try testing.expect(get_color(board.pieces[0][7]) == Colors.Black);
    try testing.expect(is_occupied(board.pieces[0][7]));
    try testing.expect(!is_moved(board.pieces[0][7]));

    try testing.expect(get_piece(board.pieces[1][7]) == Piece.Knight);
    try testing.expect(get_color(board.pieces[1][7]) == Colors.Black);
    try testing.expect(is_occupied(board.pieces[1][7]));
    try testing.expect(!is_moved(board.pieces[1][7]));

    try testing.expect(get_piece(board.pieces[2][7]) == Piece.Bishop);
    try testing.expect(get_color(board.pieces[2][7]) == Colors.Black);
    try testing.expect(is_occupied(board.pieces[2][7]));
    try testing.expect(!is_moved(board.pieces[2][7]));

    try testing.expect(get_piece(board.pieces[3][7]) == Piece.Queen);
    try testing.expect(get_color(board.pieces[3][7]) == Colors.Black);
    try testing.expect(is_occupied(board.pieces[3][7]));
    try testing.expect(!is_moved(board.pieces[3][7]));

    try testing.expect(get_piece(board.pieces[4][7]) == Piece.King);
    try testing.expect(get_color(board.pieces[4][7]) == Colors.Black);
    try testing.expect(is_occupied(board.pieces[4][7]));
    try testing.expect(!is_moved(board.pieces[4][7]));

    try testing.expect(get_piece(board.pieces[5][7]) == Piece.Bishop);
    try testing.expect(get_color(board.pieces[5][7]) == Colors.Black);
    try testing.expect(is_occupied(board.pieces[5][7]));
    try testing.expect(!is_moved(board.pieces[5][7]));

    try testing.expect(get_piece(board.pieces[6][7]) == Piece.Knight);
    try testing.expect(get_color(board.pieces[6][7]) == Colors.Black);
    try testing.expect(is_occupied(board.pieces[6][7]));
    try testing.expect(!is_moved(board.pieces[6][7]));

    try testing.expect(get_piece(board.pieces[7][7]) == Piece.Rook);
    try testing.expect(get_color(board.pieces[7][7]) == Colors.Black);
    try testing.expect(is_occupied(board.pieces[7][7]));
    try testing.expect(!is_moved(board.pieces[7][7]));

    file = 0;
    while (file < 8) : (file += 1) {
        try testing.expect(get_piece(board.pieces[file][6]) == Piece.Pawn);
        try testing.expect(get_color(board.pieces[file][6]) == Colors.Black);
        try testing.expect(is_occupied(board.pieces[file][6]));
        try testing.expect(!is_moved(board.pieces[file][6]));
    }
}

const Actions = enum {
    Start,
    Move,
    Capture,
    Castle,
    EnPassant,
    Promotion,
    Resign,
};

const CastleInfo = struct {
    color: Colors,
    king_side: bool,
};

const EnPassantInfo = struct {
    target: Position,
    move: Move,
};

const PromotionInfo = struct {
    piece: Piece,
    move: Move,
};

const Action = union(Actions) {
    Move: Move,
    Castle: CastleInfo,
    EnPassant: Move,
    Promotion: Move,
    Resign: void,
    Start: void,
};

fn legal_move_pawn(game: *Game, action: Move) bool {
    const from = action.from;
    const to = action.to;
    const from_state = game.board.pieces[from.file][from.rank];
    const from_piece = get_piece(from_state);
    if (from_piece != Piece.Pawn) {
        return false;
    }
    const from_color = get_color(from_state);

    const to_state = game.board.pieces[to.file][to.rank];
    if (is_occupied(to_state)) {
        const to_color = get_color(to_state);
        if (to_color == from_color) {
            return false;
        }
        const rank_diff = if (from_color == Colors.White) to.rank - from.rank else from.rank - to.rank;
        if (rank_diff != 1) {
            return false;
        }
        const file_diff = @abs(from.file - to.file);
        if (file_diff != 1) {
            return false;
        }
    } else {
        const rank_diff = if (from_color == Colors.White) to.rank - from.rank else from.rank - to.rank;
        const legal_rank_diff = if (from.rank == 1) 2 else 1;
        if (rank_diff > legal_rank_diff or rank_diff < 1) {
            return false;
        }
        const file_diff = to.file - from.file;
        if (file_diff != 0) {
            return false;
        }
    }
    return true;
}

fn legal_move_knight(game: *Game, action: Move) bool {
    _ = game;
    _ = action;

    //TODO
    unreachable;
}

fn legal_move_bishop(game: *Game, action: Move) bool {
    _ = game;
    _ = action;

    //TODO
    unreachable;
}

fn legal_move_rook(game: *Game, action: Move) bool {
    _ = game;
    _ = action;

    //TODO
    unreachable;
}

fn legal_move_queen(game: *Game, action: Move) bool {
    _ = game;
    _ = action;

    //TODO
    unreachable;
}

fn legal_move_king(game: *Game, action: Move) bool {
    _ = game;
    _ = action;

    //TODO
    unreachable;
}

fn legal_move(game: *Game, action: Move) bool {
    const from = action.from;
    if (from.rank < 0 or from.rank > 7 or from.file < 0 or from.file > 7) {
        return false;
    }
    const to = action.to;
    if (to.rank < 0 or to.rank > 7 or to.file < 0 or to.file > 7) {
        return false;
    }

    const from_state = game.board.pieces[from.file][from.rank];
    if (is_empty(from_state)) {
        return false;
    }

    const from_color = get_color(from_state);
    if (from_color != game.active_color) {
        return false;
    }
    const piece = game.board.pieces[from.file][from.rank];
    switch (piece) {
        Piece.Pawn => {
            return legal_move_pawn(game, action);
        },
        Piece.Knight => {
            return legal_move_knight(game, action);
        },
        Piece.Bishop => {
            return legal_move_bishop(game, action);
        },
        Piece.Rook => {
            return legal_move_rook(game, action);
        },
        Piece.Queen => {
            return legal_move_queen(game, action);
        },
        Piece.King => {
            return legal_move_king(game, action);
        },
    }
    return false;
}

fn legal_capture(game: *Game, action: Move) bool {
    _ = game;
    _ = action;

    //TODO
    unreachable;
}

fn legal_castle(game: *Game, action: CastleInfo) bool {
    _ = game;
    _ = action;
    //TODO
    unreachable;
}

fn legal_en_passant(game: *Game, action: EnPassantInfo) bool {
    _ = game;
    _ = action;

    //TODO
    unreachable;
}

fn legal_promotion(game: *Game, action: PromotionInfo) bool {
    _ = game;
    _ = action;

    //TODO
    unreachable;
}

fn legal_action(game: *Game, action: Action) bool {
    switch (action) {
        Action.Move => {
            return legal_move(game, action.Move);
        },

        Action.Castle => {
            return legal_castle(game, action.Castle);
        },
        Action.EnPassant => {
            return legal_en_passant(game, action.EnPassant);
        },
        Action.Promotion => {
            return legal_promotion(game, action.Promotion);
        },
        Action.Resign => {
            return true;
        },
        Action.Start => {
            return false;
        },
    }
}

const Game = struct {
    board: Board,
    active_color: Colors,
    last_action: Action,

    fn handle_action(game: *Game, action: Action) void {
        switch (action) {
            Action.Move => {
                const move = action.Move;
                const from = move.from;
                const to = move.to;
                const piece = game.board.pieces[from.file][from.rank];
                const moved_peice = set_moved(piece);
                game.board.pieces[from.file][from.rank] = 0;
                game.board.pieces[to.file][to.rank] = moved_peice;
            },
            Action.Castle => {
                const info = action.Castle;
                const color = info.color;
                const king_side = info.king_side;
                if (color == Colors.White) {
                    if (king_side) {
                        game.board.pieces[W_KN1.file][W_KN1.rank] = set_moved(game.board.pieces[W_K1.file][W_K1.rank]);
                        game.board.pieces[W_KB1.file][W_KB1.rank] = set_moved(game.board.pieces[W_KR1.file][W_KR1.rank]);
                        game.board.pieces[W_K1.file][W_K1.rank] = 0;
                        game.board.pieces[W_KR1.file][W_KR1.rank] = 0;
                    } else {
                        game.board.pieces[W_QN1.file][W_QN1.rank] = set_moved(game.board.pieces[W_K1.file][W_K1.rank]);
                        game.board.pieces[W_Q1.file][W_Q1.rank] = set_moved(game.board.pieces[W_QR1.file][W_QR1.rank]);
                        game.board.pieces[W_K1.file][W_K1.rank] = 0;
                        game.board.pieces[W_QR1.file][W_QR1.rank] = 0;
                    }
                } else {
                    if (king_side) {
                        game.board.pieces[B_KN1.file][B_KN1.rank] = set_moved(game.board.pieces[B_K1.file][B_K1.rank]);
                        game.board.pieces[B_KB1.file][B_KB1.rank] = set_moved(game.board.pieces[B_KR1.file][B_KR1.rank]);
                        game.board.pieces[B_K1.file][B_K1.rank] = 0;
                        game.board.pieces[B_KR1.file][B_KR1.rank] = 0;
                    } else {
                        game.board.pieces[B_QN1.file][B_QN1.rank] = set_moved(game.board.pieces[B_K1.file][B_K1.rank]);
                        game.board.pieces[B_Q1.file][B_Q1.rank] = set_moved(game.board.pieces[B_QR1.file][B_QR1.rank]);
                        game.board.pieces[B_K1.file][B_K1.rank] = 0;
                        game.board.pieces[B_QR1.file][B_QR1.rank] = 0;
                    }
                }
            },
            Action.EnPassant => {
                const enPassantInfo = action.EnPassant;
                const target = enPassantInfo.target;
                const move = enPassantInfo.move;
                const from = move.from;
                const to = move.to;
                const piece = game.board.pieces[from.file][from.rank];
                const moved_piece = set_moved(piece);
                game.board.pieces[from.file][from.rank] = 0;
                game.board.pieces[to.file][to.rank] = moved_piece;
                game.board.pieces[target.file][target.rank] = 0;
            },
            Action.Promotion => {
                const promotionInfo = action.Promotion;
                const piece = promotionInfo.piece;
                const move = promotionInfo.move;
                const from = move.from;
                const to = move.to;
                const old_piece = game.board.pieces[from.file][from.rank];
                const moved_piece = set_piece(set_moved(old_piece), piece);
                game.board.pieces[from.file][from.rank] = 0;
                game.board.pieces[to.file][to.rank] = moved_piece;
            },
            Action.Resign => {
                // TODO
            },
            Action.Start => {
                // TODO
            },
        }
    }
};
