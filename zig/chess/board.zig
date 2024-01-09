const std = @import("std");
const testing = std.testing;

const po = @import("position.zig");
const sq = @import("square.zig");

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

    fn get_square_at(self: *Board, pos: po.Position) sq.Square {
        const state = self.pieces[pos.file][pos.rank];
        const color = sq.get_color(state);
        const piece = sq.get_piece(state);
        const moved = sq.is_moved(state);
        const empty = sq.is_empty(state);
        return sq.Square{
            .color = color,
            .piece = piece,
            .moved = moved,
            .empty = empty,
        };
    }

    fn get_state_at(self: *Board, pos: po.Position) u32 {
        return self.pieces[pos.file][pos.rank];
    }

    fn get_king_square(self: *Board, color: sq.Colors) po.Position {
        var file: u8 = 0;
        while (file < 8) : (file += 1) {
            var rank: u8 = 0;
            while (rank < 8) : (rank += 1) {
                const state = self.pieces[file][rank];
                if (sq.get_piece(state) == sq.Piece.King and sq.get_color(state) == color) {
                    return po.Position{ .file = file, .rank = rank };
                }
            }
        }
        return po.Position{ .file = 0, .rank = 0 };
    }

    fn set_up(board: *Board) void {
        var file: u8 = 0;
        while (file < 8) : (file += 1) {
            var rank: u8 = 0;
            while (rank < 8) : (rank += 1) {
                board.pieces[file][rank] = 0;
            }
        }

        board.pieces[po.W_QR1.file][po.W_QR1.rank] = sq.set_piece(
            board.pieces[po.W_QR1.file][po.W_QR1.rank],
            sq.Piece.Rook,
        );
        board.pieces[po.W_QN1.file][po.W_QN1.rank] = sq.set_piece(board.pieces[po.W_QN1.file][po.W_QN1.rank], sq.Piece.Knight);
        board.pieces[po.W_QB1.file][po.W_QB1.rank] = sq.set_piece(board.pieces[po.W_QB1.file][po.W_QB1.rank], sq.Piece.Bishop);
        board.pieces[po.W_Q1.file][po.W_Q1.rank] = sq.set_piece(board.pieces[po.W_Q1.file][po.W_Q1.rank], sq.Piece.Queen);
        board.pieces[po.W_K1.file][po.W_K1.rank] = sq.set_piece(board.pieces[po.W_K1.file][po.W_K1.rank], sq.Piece.King);
        board.pieces[po.W_KB1.file][po.W_KB1.rank] = sq.set_piece(board.pieces[po.W_KB1.file][po.W_KB1.rank], sq.Piece.Bishop);
        board.pieces[po.W_KN1.file][po.W_KN1.rank] = sq.set_piece(board.pieces[po.W_KN1.file][po.W_KN1.rank], sq.Piece.Knight);
        board.pieces[po.W_KR1.file][po.W_KR1.rank] = sq.set_piece(board.pieces[po.W_KR1.file][po.W_KR1.rank], sq.Piece.Rook);
        board.pieces[po.W_QR2.file][po.W_QR2.rank] = sq.set_piece(board.pieces[po.W_QR2.file][po.W_QR2.rank], sq.Piece.Pawn);
        board.pieces[po.W_QN2.file][po.W_QN2.rank] = sq.set_piece(board.pieces[po.W_QN2.file][po.W_QN2.rank], sq.Piece.Pawn);
        board.pieces[po.W_QB2.file][po.W_QB2.rank] = sq.set_piece(board.pieces[po.W_QB2.file][po.W_QB2.rank], sq.Piece.Pawn);
        board.pieces[po.W_Q2.file][po.W_Q2.rank] = sq.set_piece(board.pieces[po.W_Q2.file][po.W_Q2.rank], sq.Piece.Pawn);
        board.pieces[po.W_K2.file][po.W_K2.rank] = sq.set_piece(board.pieces[po.W_K2.file][po.W_K2.rank], sq.Piece.Pawn);
        board.pieces[po.W_KB2.file][po.W_KB2.rank] = sq.set_piece(board.pieces[po.W_KB2.file][po.W_KB2.rank], sq.Piece.Pawn);
        board.pieces[po.W_KN2.file][po.W_KN2.rank] = sq.set_piece(board.pieces[po.W_KN2.file][po.W_KN2.rank], sq.Piece.Pawn);
        board.pieces[po.W_KR2.file][po.W_KR2.rank] = sq.set_piece(board.pieces[po.W_KR2.file][po.W_KR2.rank], sq.Piece.Pawn);
        board.pieces[po.B_QR1.file][po.B_QR1.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_QR1.file][po.B_QR1.rank], sq.Piece.Rook));
        board.pieces[po.B_QN1.file][po.B_QN1.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_QN1.file][po.B_QN1.rank], sq.Piece.Knight));
        board.pieces[po.B_QB1.file][po.B_QB1.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_QB1.file][po.B_QB1.rank], sq.Piece.Bishop));
        board.pieces[po.B_Q1.file][po.B_Q1.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_Q1.file][po.B_Q1.rank], sq.Piece.Queen));
        board.pieces[po.B_K1.file][po.B_K1.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_K1.file][po.B_K1.rank], sq.Piece.King));
        board.pieces[po.B_KB1.file][po.B_KB1.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_KB1.file][po.B_KB1.rank], sq.Piece.Bishop));
        board.pieces[po.B_KN1.file][po.B_KN1.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_KN1.file][po.B_KN1.rank], sq.Piece.Knight));
        board.pieces[po.B_KR1.file][po.B_KR1.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_KR1.file][po.B_KR1.rank], sq.Piece.Rook));
        board.pieces[po.B_QR2.file][po.B_QR2.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_QR2.file][po.B_QR2.rank], sq.Piece.Pawn));
        board.pieces[po.B_QN2.file][po.B_QN2.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_QN2.file][po.B_QN2.rank], sq.Piece.Pawn));
        board.pieces[po.B_QB2.file][po.B_QB2.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_QB2.file][po.B_QB2.rank], sq.Piece.Pawn));
        board.pieces[po.B_Q2.file][po.B_Q2.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_Q2.file][po.B_Q2.rank], sq.Piece.Pawn));
        board.pieces[po.B_K2.file][po.B_K2.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_K2.file][po.B_K2.rank], sq.Piece.Pawn));
        board.pieces[po.B_KB2.file][po.B_KB2.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_KB2.file][po.B_KB2.rank], sq.Piece.Pawn));
        board.pieces[po.B_KN2.file][po.B_KN2.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_KN2.file][po.B_KN2.rank], sq.Piece.Pawn));
        board.pieces[po.B_KR2.file][po.B_KR2.rank] = sq.set_black(sq.set_piece(board.pieces[po.B_KR2.file][po.B_KR2.rank], sq.Piece.Pawn));
    }
};

test "Board init" {
    // var allocator = testing.allocator;
    var board: Board = Board{};
    board.set_up();

    // defer allocator.free(board);
    const TestCase = struct {
        pos: po.Position,
        piece: sq.Piece,
        color: sq.Colors,
        moved: bool,
        empty: bool,
    };

    const test_cases = [_]TestCase{
        TestCase{ .pos = po.Position{ .file = 0, .rank = 0 }, .piece = sq.Piece.Rook, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 1, .rank = 0 }, .piece = sq.Piece.Knight, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 2, .rank = 0 }, .piece = sq.Piece.Bishop, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 3, .rank = 0 }, .piece = sq.Piece.Queen, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 4, .rank = 0 }, .piece = sq.Piece.King, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 5, .rank = 0 }, .piece = sq.Piece.Bishop, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 6, .rank = 0 }, .piece = sq.Piece.Knight, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 7, .rank = 0 }, .piece = sq.Piece.Rook, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 0, .rank = 1 }, .piece = sq.Piece.Pawn, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 1, .rank = 1 }, .piece = sq.Piece.Pawn, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 2, .rank = 1 }, .piece = sq.Piece.Pawn, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 3, .rank = 1 }, .piece = sq.Piece.Pawn, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 4, .rank = 1 }, .piece = sq.Piece.Pawn, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 5, .rank = 1 }, .piece = sq.Piece.Pawn, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 6, .rank = 1 }, .piece = sq.Piece.Pawn, .color = sq.Colors.White, .moved = false, .empty = false },
        TestCase{ .pos = po.Position{ .file = 7, .rank = 1 }, .piece = sq.Piece.Pawn, .color = sq.Colors.White, .moved = false, .empty = false },
    };
    for (test_cases) |test_case| {
        const state = board.get_square_at(test_case.pos);
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
            const state = board.get_square_at(po.Position{ .file = file, .rank = rank });
            try testing.expect(state.empty);
        }
    }

    file = 0;
    while (file < 8) : (file += 1) {
        const pos = po.Position{ .file = file, .rank = 1 };
        const state = board.get_square_at(pos);
        try testing.expect(state.piece == sq.Piece.Pawn);
        try testing.expect(state.color == sq.Colors.White);
        try testing.expect(!state.empty);
        try testing.expect(!state.moved);
    }

    file = 0;
    while (file < 8) : (file += 1) {
        const pos = po.Position{ .file = file, .rank = 8 };
        const state = board.get_square_at(pos);
        try testing.expect(state.piece == sq.Piece.Pawn);
        try testing.expect(state.color == sq.Colors.Black);
        try testing.expect(!state.empty);
        try testing.expect(!state.moved);
    }
}
