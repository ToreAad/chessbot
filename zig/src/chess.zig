const std = @import("std");
const testing = std.testing;

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

const Position = struct {
    file: u8,
    rank: u8,
};

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

        board.pieces[0][0] = set_piece(board.pieces[0][0], Piece.Rook);
        board.pieces[1][0] = set_piece(board.pieces[1][0], Piece.Knight);
        board.pieces[2][0] = set_piece(board.pieces[2][0], Piece.Bishop);
        board.pieces[3][0] = set_piece(board.pieces[3][0], Piece.Queen);
        board.pieces[4][0] = set_piece(board.pieces[4][0], Piece.King);
        board.pieces[5][0] = set_piece(board.pieces[5][0], Piece.Bishop);
        board.pieces[6][0] = set_piece(board.pieces[6][0], Piece.Knight);
        board.pieces[7][0] = set_piece(board.pieces[7][0], Piece.Rook);
        board.pieces[0][1] = set_piece(board.pieces[0][1], Piece.Pawn);
        board.pieces[1][1] = set_piece(board.pieces[1][1], Piece.Pawn);
        board.pieces[2][1] = set_piece(board.pieces[2][1], Piece.Pawn);
        board.pieces[3][1] = set_piece(board.pieces[3][1], Piece.Pawn);
        board.pieces[4][1] = set_piece(board.pieces[4][1], Piece.Pawn);
        board.pieces[5][1] = set_piece(board.pieces[5][1], Piece.Pawn);
        board.pieces[6][1] = set_piece(board.pieces[6][1], Piece.Pawn);
        board.pieces[7][1] = set_piece(board.pieces[7][1], Piece.Pawn);

        board.pieces[0][7] = set_black(set_piece(board.pieces[0][7], Piece.Rook));
        board.pieces[1][7] = set_black(set_piece(board.pieces[1][7], Piece.Knight));
        board.pieces[2][7] = set_black(set_piece(board.pieces[2][7], Piece.Bishop));
        board.pieces[3][7] = set_black(set_piece(board.pieces[3][7], Piece.Queen));
        board.pieces[4][7] = set_black(set_piece(board.pieces[4][7], Piece.King));
        board.pieces[5][7] = set_black(set_piece(board.pieces[5][7], Piece.Bishop));
        board.pieces[6][7] = set_black(set_piece(board.pieces[6][7], Piece.Knight));
        board.pieces[7][7] = set_black(set_piece(board.pieces[7][7], Piece.Rook));
        board.pieces[0][6] = set_black(set_piece(board.pieces[0][6], Piece.Pawn));
        board.pieces[1][6] = set_black(set_piece(board.pieces[1][6], Piece.Pawn));
        board.pieces[2][6] = set_black(set_piece(board.pieces[2][6], Piece.Pawn));
        board.pieces[3][6] = set_black(set_piece(board.pieces[3][6], Piece.Pawn));
        board.pieces[4][6] = set_black(set_piece(board.pieces[4][6], Piece.Pawn));
        board.pieces[5][6] = set_black(set_piece(board.pieces[5][6], Piece.Pawn));
        board.pieces[6][6] = set_black(set_piece(board.pieces[6][6], Piece.Pawn));
        board.pieces[7][6] = set_black(set_piece(board.pieces[7][6], Piece.Pawn));
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
    Move,
    Capture,
    Castle,
    EnPassant,
    Promotion,
    Resign,
};

const Action = union(Actions) {
    Move: Move,
    Capture: Move,
    Castle: Move,
    EnPassant: Move,
    Promotion: Move,
    Resign: void,
};

const Game = struct {
    board: Board,
    active_color: Colors,

    fn handle_action(game: *Game, action: Action) void {
        _ = game; // autofix
        _ = action; // autofix

        // switch (action) {
        //     .Move => {
        //         const move = action.Move;
        //         const piece = game.board.pieces[move.from.file][move.from.rank];
        //         game.board.pieces[move.from.file][move.from.rank] = Square.Empty;
        //         game.board.pieces[move.to.file][move.to.rank] = Square.Occupied{ .Occupied = piece };
        //         game.active_color = if (game.active_color == Colors.White) Colors.Black else Colors.White;
        //     },
        //     .Capture => {
        //         const move = action.Capture;
        //         const piece = game.board.pieces[move.from.file][move.from.rank];
        //         game.board.pieces[move.from.file][move.from.rank] = Square.Empty;
        //         game.board.pieces[move.to.file][move.to.rank] = Square.Occupied{ .Occupied = piece };
        //         game.active_color = if (game.active_color == Colors.White) Colors.Black else Colors.White;
        //     },
        //     .Castle => {
        //         const move = action.Castle;
        //         const piece = game.board.pieces[move.from.file][move.from.rank];
        //         game.board.pieces[move.from.file][move.from.rank] = Square.Empty;
        //         game.board.pieces[move.to.file][move.to.rank] = Square.Occupied{ .Occupied = piece };
        //         game.active_color = if (game.active_color == Colors.White) Colors.Black else Colors.White;
        //     },
        //     .EnPassant => {
        //         const move = action.EnPassant;
        //         const piece = game.board.pieces[move.from.file][move.from.rank];
        //         game.board.pieces[move.from.file][move.from.rank] = Square.Empty;
        //         game.board.pieces[move.to.file][move.to.rank] = Square.Occupied{ .Occupied = piece };
        //         game.active_color = if (game.active_color == Colors.White) Colors.Black else Colors.White;
        //     },
        //     .Promotion => {
        //         const move = action.Promotion;
        //         const piece = game.board.pieces[move.from.file][move.from.rank];
        //         game.board.pieces[move.from.file][move.from.rank] = Square.Empty;
        //         game.board.pieces[move.to.file][move.to.rank] = Square.Occupied{ .Occupied = piece };
        //         game.active_color = if (game.active_color == Colors.White) Colors.Black else Colors.White;
        //     },
        //     .Resign => {
        //         game.active_color = if (game.active_color == Colors.White) Colors.Black else Colors.White;
        //     },
        // }
    }
};
