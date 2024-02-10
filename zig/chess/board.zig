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

    pub fn format(
        self: *const Square,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        if (self.empty) {
            try writer.print(" . ");
            return;
        }

        if (self.color == Colors.White) {
            switch (self.piece) {
                Piece.Rook => try writer.print("R"),
                Piece.Knight => try writer.print("N"),
                Piece.Bishop => try writer.print("B"),
                Piece.Queen => try writer.print("Q"),
                Piece.King => try writer.print("K"),
                Piece.Pawn => try writer.print("P"),
                else => unreachable,
            }
        } else {
            switch (self.piece) {
                Piece.Rook => try writer.print("r"),
                Piece.Knight => try writer.print("n"),
                Piece.Bishop => try writer.print("b"),
                Piece.Queen => try writer.print("q"),
                Piece.King => try writer.print("k"),
                Piece.Pawn => try writer.print("p"),
                else => unreachable,
            }
        }
    }
};

fn state_to_square(state: SquareData) !Square {
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

fn square_to_state(square: Square) SquareData {
    var square_data = SquareData{};
    square_data.set_color(square.color);
    square_data.set_piece(square.piece);
    if (square.moved) {
        square_data.set_moved();
    }
    return square_data;
}

const BoardError = error{
    NotFound,
    Corrupted,
    ParseError,
};

pub const BASIC_BOARD =
    \\ RNBQKBNR
    \\ PPPPPPPP
    \\ ........
    \\ ........
    \\ ........
    \\ ........
    \\ pppppppp
    \\ rnbqkbnr
;

fn char_to_square(maybe_square: u8) BoardError!Square {
    const state = switch (maybe_square) {
        'R' => return Square{ .empty = false, .moved = false, .piece = Piece.Rook, .color = Colors.White },
        'N' => return Square{ .empty = false, .moved = false, .piece = Piece.Knight, .color = Colors.White },
        'B' => return Square{ .empty = false, .moved = false, .piece = Piece.Bishop, .color = Colors.White },
        'Q' => return Square{ .empty = false, .moved = false, .piece = Piece.Queen, .color = Colors.White },
        'K' => return Square{ .empty = false, .moved = false, .piece = Piece.King, .color = Colors.White },
        'P' => return Square{ .empty = false, .moved = false, .piece = Piece.Pawn, .color = Colors.White },
        'r' => return Square{ .empty = false, .moved = false, .piece = Piece.Rook, .color = Colors.Black },
        'n' => return Square{ .empty = false, .moved = false, .piece = Piece.Knight, .color = Colors.Black },
        'b' => return Square{ .empty = false, .moved = false, .piece = Piece.Bishop, .color = Colors.Black },
        'q' => return Square{ .empty = false, .moved = false, .piece = Piece.Queen, .color = Colors.Black },
        'k' => return Square{ .empty = false, .moved = false, .piece = Piece.King, .color = Colors.Black },
        'p' => return Square{ .empty = false, .moved = false, .piece = Piece.Pawn, .color = Colors.Black },
        '.' => return Square{ .empty = true, .moved = false, .piece = Piece.None, .color = Colors.White },
        else => return error.Corrupted,
    };
    _ = state;
}

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

    pub fn get_square_at(self: *const Board, pos: Position) BoardError!Square {
        const state = self.pieces[pos.file][pos.rank];
        return state_to_square(state);
    }

    pub fn get_state_at(self: *const Board, pos: Position) SquareData {
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

    pub fn set_unmoved(self: *Board, pos: Position) void {
        var state = self.pieces[pos.file][pos.rank];
        state.set_unmoved();
        self.pieces[pos.file][pos.rank] = state;
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

    pub fn get_king_square(self: *const Board, color: Colors) BoardError!Position {
        var file: u8 = 0;
        while (file < 8) : (file += 1) {
            var rank: u8 = 0;
            while (rank < 8) : (rank += 1) {
                const state = self.pieces[file][rank];
                const piece = state.get_piece() catch return error.Corrupted;
                const piece_color = state.get_color();
                if (piece == Piece.King and piece_color == color) {
                    return Position{ .file = file, .rank = rank };
                }
            }
        }
        return error.NotFound;
    }

    pub fn set_up_from_string(board: *Board, board_string: []const u8) BoardError!void {
        // Board string looks like this:
        // RNBQKBNR
        // PPPPPPPP
        // ........
        // ........
        // ........
        // ........
        // pppppppp
        // rnbqkbnr

        var file: u8 = 0;
        var rank: u8 = 0;
        for (board_string) |maybe_square| {
            if (maybe_square == ' ' or maybe_square == '\n' or maybe_square == '\r' or maybe_square == '\t') {
                continue;
            }
            if (rank == 8) {
                return error.ParseError;
            }
            const square = try char_to_square(maybe_square);
            const state = square_to_state(square);

            board.set_state_at(Position{ .file = file, .rank = rank }, state);

            file += 1;
            if (file == 8) {
                file = 0;
                rank += 1;
            }
        }
    }

    pub fn format(
        self: *const Board,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        for (0..7) |i| {
            try writer.print("{s}{s}{s}{s}{s}{s}{s}{s}\n", .{
                self.pieces[0][i],
                self.pieces[1][i],
                self.pieces[2][i],
                self.pieces[3][i],
                self.pieces[4][i],
                self.pieces[5][i],
                self.pieces[6][i],
                self.pieces[7][i],
            });
        }

        try writer.print("{s}{s}{s}{s}{s}{s}{s}{s}", .{
            self.pieces[0][7],
            self.pieces[1][7],
            self.pieces[2][7],
            self.pieces[3][7],
            self.pieces[4][7],
            self.pieces[5][7],
            self.pieces[6][7],
            self.pieces[7][7],
        });
    }

    pub fn set_up(board: *Board) void {
        board.set_up_from_string(BASIC_BOARD) catch unreachable;
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
        try testing.expect(pos.equals(&test_case.pos));
    }
}
