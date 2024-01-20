const std = @import("std");
const testing = std.testing;
const po = @import("position.zig");
const Piece = @import("pieces.zig").Piece;
const Colors = @import("colors.zig").Colors;
const SquareData = @import("square.zig").SquareData;
const Position = @import("position.zig").Position;

pub const Square = struct {
    empty: bool,
    color: Colors,
    piece: Piece,
    moved: bool,
};

const BoardError = error{
    NotFound,
    Corrupted,
};

pub const Board = struct {
    pieces: [8][8]SquareData = [8][8]SquareData{
        [8]SquareData{ SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{} },
        [8]SquareData{ SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{} },
        [8]SquareData{ SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{} },
        [8]SquareData{ SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{} },
        [8]SquareData{ SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{} },
        [8]SquareData{ SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{} },
        [8]SquareData{ SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{} },
        [8]SquareData{ SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{}, SquareData{} },
    },

    fn get_square_at(self: *Board, pos: Position) BoardError!Square {
        var state = self.pieces[pos.file][pos.rank];
        const color = state.get_color();
        const piece = state.get_piece() catch return error.Corrupted;
        const moved = state.is_moved();
        const empty = state.is_empty();
        return Square{
            .color = color,
            .piece = piece,
            .moved = moved,
            .empty = empty,
        };
    }

    pub fn get_state_at(self: *Board, pos: Position) SquareData {
        return self.pieces[pos.file][pos.rank];
    }

    pub fn set_state_at(self: *Board, pos: Position, state: SquareData) void {
        self.pieces[pos.file][pos.rank] = state;
    }

    pub fn clear_state_at(self: *Board, pos: Position) void {
        self.pieces[pos.file][pos.rank] = SquareData{};
    }

    pub fn move_piece(self: *Board, from: Position, to: Position) void {
        var state = self.pieces[from.file][from.rank];
        state.set_moved();
        self.pieces[to.file][to.rank] = state;
        self.pieces[from.file][from.rank] = SquareData{};
    }

    pub fn set_piece_at(self: *Board, pos: Position, piece: Piece) void {
        var state = self.pieces[pos.file][pos.rank];
        state.set_piece(piece);
        self.pieces[pos.file][pos.rank] = state;
    }

    pub fn set_color_at(self: *Board, pos: Position, color: Colors) void {
        var state = self.pieces[pos.file][pos.rank];
        state.set_color(color);
        self.pieces[pos.file][pos.rank] = state;
    }

    fn get_king_square(self: *Board, color: Colors) BoardError!Position {
        var file: u8 = 0;
        while (file < 8) : (file += 1) {
            var rank: u8 = 0;
            while (rank < 8) : (rank += 1) {
                const state = self.pieces[file][rank];
                if (state.get_piece() == Piece.King and state.get_color() == color) {
                    return Position{ .file = file, .rank = rank };
                }
            }
        }
        return error.NotFound;
    }

    fn set_up(board: *Board) void {
        var file: u8 = 0;
        while (file < 8) : (file += 1) {
            var rank: u8 = 0;
            while (rank < 8) : (rank += 1) {
                board.pieces[file][rank] = SquareData{};
            }
        }

        board.set_piece_at(po.W_QR1, Piece.Rook);
        board.set_piece_at(po.W_QN1, Piece.Knight);
        board.set_piece_at(po.W_QB1, Piece.Bishop);
        board.set_piece_at(po.W_Q1, Piece.Queen);
        board.set_piece_at(po.W_K1, Piece.King);
        board.set_piece_at(po.W_KB1, Piece.Bishop);
        board.set_piece_at(po.W_KN1, Piece.Knight);
        board.set_piece_at(po.W_KR1, Piece.Rook);
        board.set_piece_at(po.W_QR2, Piece.Pawn);
        board.set_piece_at(po.W_QN2, Piece.Pawn);
        board.set_piece_at(po.W_QB2, Piece.Pawn);
        board.set_piece_at(po.W_Q2, Piece.Pawn);
        board.set_piece_at(po.W_KB2, Piece.Pawn);
        board.set_piece_at(po.W_KN2, Piece.Pawn);
        board.set_piece_at(po.W_KR2, Piece.Pawn);
        board.set_piece_at(po.W_K2, Piece.Pawn);
        board.set_color_at(po.W_QR1, Colors.White);
        board.set_color_at(po.W_QN1, Colors.White);
        board.set_color_at(po.W_QB1, Colors.White);
        board.set_color_at(po.W_Q1, Colors.White);
        board.set_color_at(po.W_K1, Colors.White);
        board.set_color_at(po.W_KB1, Colors.White);
        board.set_color_at(po.W_KN1, Colors.White);
        board.set_color_at(po.W_KR1, Colors.White);
        board.set_color_at(po.W_QR2, Colors.White);
        board.set_color_at(po.W_QN2, Colors.White);
        board.set_color_at(po.W_QB2, Colors.White);
        board.set_color_at(po.W_Q2, Colors.White);
        board.set_color_at(po.W_KB2, Colors.White);
        board.set_color_at(po.W_KN2, Colors.White);
        board.set_color_at(po.W_KR2, Colors.White);
        board.set_color_at(po.W_K2, Colors.White);
        board.set_piece_at(po.B_QR1, Piece.Rook);
        board.set_piece_at(po.B_QN1, Piece.Knight);
        board.set_piece_at(po.B_QB1, Piece.Bishop);
        board.set_piece_at(po.B_Q1, Piece.Queen);
        board.set_piece_at(po.B_K1, Piece.King);
        board.set_piece_at(po.B_KB1, Piece.Bishop);
        board.set_piece_at(po.B_KN1, Piece.Knight);
        board.set_piece_at(po.B_KR1, Piece.Rook);
        board.set_piece_at(po.B_QR2, Piece.Pawn);
        board.set_piece_at(po.B_QN2, Piece.Pawn);
        board.set_piece_at(po.B_QB2, Piece.Pawn);
        board.set_piece_at(po.B_Q2, Piece.Pawn);
        board.set_piece_at(po.B_KB2, Piece.Pawn);
        board.set_piece_at(po.B_KN2, Piece.Pawn);
        board.set_piece_at(po.B_KR2, Piece.Pawn);
        board.set_piece_at(po.B_K2, Piece.Pawn);
        board.set_color_at(po.B_QR1, Colors.Black);
        board.set_color_at(po.B_QN1, Colors.Black);
        board.set_color_at(po.B_QB1, Colors.Black);
        board.set_color_at(po.B_Q1, Colors.Black);
        board.set_color_at(po.B_K1, Colors.Black);
        board.set_color_at(po.B_KB1, Colors.Black);
        board.set_color_at(po.B_KN1, Colors.Black);
        board.set_color_at(po.B_KR1, Colors.Black);
        board.set_color_at(po.B_QR2, Colors.Black);
        board.set_color_at(po.B_QN2, Colors.Black);
        board.set_color_at(po.B_QB2, Colors.Black);
        board.set_color_at(po.B_Q2, Colors.Black);
        board.set_color_at(po.B_KB2, Colors.Black);
        board.set_color_at(po.B_KN2, Colors.Black);
        board.set_color_at(po.B_KR2, Colors.Black);
        board.set_color_at(po.B_K2, Colors.Black);
    }
};

test "Board init" {
    // var allocator = testing.allocator;
    var board: Board = Board{};
    board.set_up();

    // defer allocator.free(board);
    const TestCase = struct {
        pos: Position,
        piece: Piece,
        color: Colors,
        moved: bool,
        empty: bool,
    };

    const test_cases = [_]TestCase{
        TestCase{ .pos = po.W_QR1, .piece = Piece.Rook, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_QN1, .piece = Piece.Knight, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_QB1, .piece = Piece.Bishop, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_Q1, .piece = Piece.Queen, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_K1, .piece = Piece.King, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_KB1, .piece = Piece.Bishop, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_KN1, .piece = Piece.Knight, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_KR1, .piece = Piece.Rook, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_QR2, .piece = Piece.Pawn, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_QN2, .piece = Piece.Pawn, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_QB2, .piece = Piece.Pawn, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_Q2, .piece = Piece.Pawn, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_KB2, .piece = Piece.Pawn, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_KN2, .piece = Piece.Pawn, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_KR2, .piece = Piece.Pawn, .color = Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.W_K2, .piece = Piece.Pawn, .color = Colors.White, .moved = false, .empty = false },

        TestCase{ .pos = po.B_QR1, .piece = Piece.Rook, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_QN1, .piece = Piece.Knight, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_QB1, .piece = Piece.Bishop, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_Q1, .piece = Piece.Queen, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_K1, .piece = Piece.King, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_KB1, .piece = Piece.Bishop, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_KN1, .piece = Piece.Knight, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_KR1, .piece = Piece.Rook, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_QR2, .piece = Piece.Pawn, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_QN2, .piece = Piece.Pawn, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_QB2, .piece = Piece.Pawn, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_Q2, .piece = Piece.Pawn, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_KB2, .piece = Piece.Pawn, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_KN2, .piece = Piece.Pawn, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_KR2, .piece = Piece.Pawn, .color = Colors.Black, .moved = false, .empty = false },
        TestCase{ .pos = po.B_K2, .piece = Piece.Pawn, .color = Colors.Black, .moved = false, .empty = false },
    };
    for (test_cases) |test_case| {
        const state = try board.get_square_at(test_case.pos);
        try testing.expect(state.piece == test_case.piece);
        try testing.expect(state.color == test_case.color);
        try testing.expect(state.moved == test_case.moved);
        try testing.expect(state.empty == test_case.empty);
    }

    // test empty squares

    var file: u8 = 0;
    while (file < 8) : (file += 1) {
        var rank: u8 = 2;
        while (rank < 6) : (rank += 1) {
            const state = try board.get_square_at(po.Position{ .file = file, .rank = rank });
            try testing.expect(state.empty);
        }
    }

    file = 0;
    while (file < 8) : (file += 1) {
        const pos = po.Position{ .file = file, .rank = 1 };
        const state = try board.get_square_at(pos);
        try testing.expect(state.piece == Piece.Pawn);
        try testing.expect(state.color == Colors.White);
        try testing.expect(!state.empty);
        try testing.expect(!state.moved);
    }

    file = 0;
    while (file < 8) : (file += 1) {
        const pos = po.Position{ .file = file, .rank = 6 };
        const state = try board.get_square_at(pos);
        try testing.expect(state.piece == Piece.Pawn);
        try testing.expect(state.color == Colors.Black);
        try testing.expect(!state.empty);
        try testing.expect(!state.moved);
    }
}

test "Move pawn" {
    var board: Board = Board{};
    board.set_up();

    const from = po.Position{ .file = 0, .rank = 1 };
    const to = po.Position{ .file = 0, .rank = 2 };
    board.move_piece(from, to);

    const to_state = try board.get_square_at(to);
    try testing.expect(to_state.piece == Piece.Pawn);
    try testing.expect(to_state.color == Colors.White);
    try testing.expect(!to_state.empty);
    try testing.expect(to_state.moved);

    const from_state = try board.get_square_at(from);
    try testing.expect(from_state.empty);
}

test "Get king square" {
    // var allocator = testing.allocator;
    var board: Board = Board{};
    board.set_up();

    // defer allocator.free(board);
    const TestCase = struct {
        color: Colors,
        pos: Position,
    };

    const test_cases = [_]TestCase{
        TestCase{ .color = Colors.White, .pos = po.W_K1 },
        TestCase{ .color = Colors.Black, .pos = po.B_K1 },
    };
    for (test_cases) |test_case| {
        const pos = try board.get_king_square(test_case.color);
        try testing.expect(pos == test_case.pos);
    }
}
