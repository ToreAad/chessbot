const std = @import("std");
const testing = std.testing;

pub const Position = struct {
    file: u8,
    rank: u8,

    pub fn equals(self: *const Position, other: *const Position) bool {
        return self.file == other.file and self.rank == other.rank;
    }
};

pub const A = 0;
pub const B = 1;
pub const C = 2;
pub const D = 3;
pub const E = 4;
pub const F = 5;
pub const G = 6;
pub const H = 7;

pub const W_QR1 = Position{ .file = 0, .rank = 0 };
pub const W_QN1 = Position{ .file = 1, .rank = 0 };
pub const W_QB1 = Position{ .file = 2, .rank = 0 };
pub const W_Q1 = Position{ .file = 3, .rank = 0 };
pub const W_K1 = Position{ .file = 4, .rank = 0 };
pub const W_KB1 = Position{ .file = 5, .rank = 0 };
pub const W_KN1 = Position{ .file = 6, .rank = 0 };
pub const W_KR1 = Position{ .file = 7, .rank = 0 };
pub const W_QR2 = Position{ .file = 0, .rank = 1 };
pub const W_QN2 = Position{ .file = 1, .rank = 1 };
pub const W_QB2 = Position{ .file = 2, .rank = 1 };
pub const W_Q2 = Position{ .file = 3, .rank = 1 };
pub const W_K2 = Position{ .file = 4, .rank = 1 };
pub const W_KB2 = Position{ .file = 5, .rank = 1 };
pub const W_KN2 = Position{ .file = 6, .rank = 1 };
pub const W_KR2 = Position{ .file = 7, .rank = 1 };
pub const B_QR1 = Position{ .file = 0, .rank = 7 };
pub const B_QN1 = Position{ .file = 1, .rank = 7 };
pub const B_QB1 = Position{ .file = 2, .rank = 7 };
pub const B_Q1 = Position{ .file = 3, .rank = 7 };
pub const B_K1 = Position{ .file = 4, .rank = 7 };
pub const B_KB1 = Position{ .file = 5, .rank = 7 };
pub const B_KN1 = Position{ .file = 6, .rank = 7 };
pub const B_KR1 = Position{ .file = 7, .rank = 7 };
pub const B_QR2 = Position{ .file = 0, .rank = 6 };
pub const B_QN2 = Position{ .file = 1, .rank = 6 };
pub const B_QB2 = Position{ .file = 2, .rank = 6 };
pub const B_Q2 = Position{ .file = 3, .rank = 6 };
pub const B_K2 = Position{ .file = 4, .rank = 6 };
pub const B_KB2 = Position{ .file = 5, .rank = 6 };
pub const B_KN2 = Position{ .file = 6, .rank = 6 };
pub const B_KR2 = Position{ .file = 7, .rank = 6 };

fn add(a: Position, b: Position) Position {
    return Position{
        .file = a.file + b.file,
        .rank = a.rank + b.rank,
    };
}

test "add" {
    try testing.expectEqual(add(W_QR1, W_QR2).file, 0);
    try testing.expectEqual(add(W_QR1, W_QR2).rank, 1);
}
