const std = @import("std");
const testing = std.testing;

const Piece = @import("pieces.zig").Piece;
const Colors = @import("colors.zig").Colors;

const SquareFlags = enum(u32) {
    Black = 1 << 2,
    Pawn = 1 << 3,
    Knight = 1 << 4,
    Bishop = 1 << 5,
    Rook = 1 << 6,
    UnmovedRook = 1 << 7,
    Queen = 1 << 8,
    King = 1 << 9,
    UnmovedKing = 1 << 10,
};

const SquareError = error{
    InvalidState,
};

fn pieceFromInt(val: u32) SquareError!Piece {
    switch (val) {
        0 => {
            return Piece.None;
        },
        @intFromEnum(SquareFlags.Pawn) => {
            return Piece.Pawn;
        },
        @intFromEnum(SquareFlags.Knight) => {
            return Piece.Knight;
        },
        @intFromEnum(SquareFlags.Bishop) => {
            return Piece.Bishop;
        },
        @intFromEnum(SquareFlags.Rook) => {
            return Piece.Rook;
        },
        @intFromEnum(SquareFlags.UnmovedRook) => {
            return Piece.UnmovedRook;
        },
        @intFromEnum(SquareFlags.Queen) => {
            return Piece.Queen;
        },
        @intFromEnum(SquareFlags.King) => {
            return Piece.King;
        },
        @intFromEnum(SquareFlags.UnmovedKing) => {
            return Piece.UnmovedKing;
        },
        else => {
            return error.InvalidState;
        },
    }
}

fn intFromPiece(piece: Piece) u32 {
    switch (piece) {
        Piece.Pawn => {
            return @intFromEnum(SquareFlags.Pawn);
        },
        Piece.Knight => {
            return @intFromEnum(SquareFlags.Knight);
        },
        Piece.Bishop => {
            return @intFromEnum(SquareFlags.Bishop);
        },
        Piece.Rook => {
            return @intFromEnum(SquareFlags.Rook);
        },
        Piece.UnmovedRook => {
            return @intFromEnum(SquareFlags.UnmovedRook);
        },
        Piece.Queen => {
            return @intFromEnum(SquareFlags.Queen);
        },
        Piece.King => {
            return @intFromEnum(SquareFlags.King);
        },
        Piece.UnmovedKing => {
            return @intFromEnum(SquareFlags.UnmovedKing);
        },
        Piece.None => {
            return 0;
        },
    }
}

const PieceBand = @intFromEnum(SquareFlags.Pawn) |
    @intFromEnum(SquareFlags.Knight) |
    @intFromEnum(SquareFlags.Bishop) |
    @intFromEnum(SquareFlags.Rook) |
    @intFromEnum(SquareFlags.UnmovedRook) |
    @intFromEnum(SquareFlags.Queen) |
    @intFromEnum(SquareFlags.UnmovedKing) |
    @intFromEnum(SquareFlags.King);

test "pieceBand" {
    try testing.expect(PieceBand & @intFromEnum(SquareFlags.Pawn) == @intFromEnum(SquareFlags.Pawn));
    try testing.expect(PieceBand & @intFromEnum(SquareFlags.Knight) == @intFromEnum(SquareFlags.Knight));
    try testing.expect(PieceBand & @intFromEnum(SquareFlags.Bishop) == @intFromEnum(SquareFlags.Bishop));
    try testing.expect(PieceBand & @intFromEnum(SquareFlags.Rook) == @intFromEnum(SquareFlags.Rook));
    try testing.expect(PieceBand & @intFromEnum(SquareFlags.Queen) == @intFromEnum(SquareFlags.Queen));
    try testing.expect(PieceBand & @intFromEnum(SquareFlags.King) == @intFromEnum(SquareFlags.King));

    var band = PieceBand ^ @intFromEnum(SquareFlags.Pawn);
    band = band ^ @intFromEnum(SquareFlags.Knight);
    band = band ^ @intFromEnum(SquareFlags.Bishop);
    band = band ^ @intFromEnum(SquareFlags.Rook);
    band = band ^ @intFromEnum(SquareFlags.Queen);
    band = band ^ @intFromEnum(SquareFlags.King);
    band = band ^ @intFromEnum(SquareFlags.UnmovedRook);
    band = band ^ @intFromEnum(SquareFlags.UnmovedKing);
    try testing.expect(band == 0);
}

pub const SquareData = struct {
    state: u32 = 0,

    pub fn set_color(self: *SquareData, color: Colors) void {
        switch (color) {
            Colors.Black => {
                self.set_black();
            },
            Colors.White => {
                self.set_white();
            },
        }
    }

    pub fn set_white(self: *SquareData) void {
        self.state = self.state & ~@intFromEnum(SquareFlags.Black);
    }

    pub fn set_black(self: *SquareData) void {
        self.state = self.state | @intFromEnum(SquareFlags.Black);
    }

    pub fn is_black(self: *const SquareData) bool {
        return (self.state & @intFromEnum(SquareFlags.Black)) > 0;
    }

    pub fn is_white(self: *const SquareData) bool {
        return (self.state & @intFromEnum(SquareFlags.Black)) == 0;
    }

    pub fn get_color(self: *const SquareData) Colors {
        return if (self.is_black()) Colors.Black else Colors.White;
    }

    pub fn get_piece(self: *const SquareData) error{InvalidState}!Piece {
        const val = self.state & PieceBand;
        return pieceFromInt(val);
    }

    pub fn set_piece(self: *SquareData, piece: Piece) void {
        self.state = self.state & ~(PieceBand);
        self.state = self.state | intFromPiece(piece);
    }

    pub fn is_occupied(self: *const SquareData) bool {
        return self.state > 0;
    }

    pub fn is_empty(self: *const SquareData) bool {
        return self.state == 0;
    }

    pub fn clear(self: *SquareData) void {
        self.state = 0;
    }

    pub fn set_state(self: *SquareData, state: u32) void {
        self.state = state;
    }

    pub fn copy_from(self: *SquareData, other: *const SquareData) void {
        self.state = other.state;
    }

    pub fn format(
        self: *const SquareData,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        if (self.is_empty()) {
            try writer.writeAll(".");
            return;
        }

        const piece = self.get_piece() catch return;

        if (self.get_color() == Colors.White) {
            switch (piece) {
                Piece.Rook => try writer.writeAll("R"),
                Piece.UnmovedRook => try writer.writeAll("R"),
                Piece.Knight => try writer.writeAll("N"),
                Piece.Bishop => try writer.writeAll("B"),
                Piece.Queen => try writer.writeAll("Q"),
                Piece.King => try writer.writeAll("K"),
                Piece.UnmovedKing => try writer.writeAll("K"),
                Piece.Pawn => try writer.writeAll("P"),
                else => unreachable,
            }
        } else {
            switch (piece) {
                Piece.Rook => try writer.writeAll("r"),
                Piece.UnmovedRook => try writer.writeAll("r"),
                Piece.Knight => try writer.writeAll("n"),
                Piece.Bishop => try writer.writeAll("b"),
                Piece.Queen => try writer.writeAll("q"),
                Piece.King => try writer.writeAll("k"),
                Piece.UnmovedKing => try writer.writeAll("k"),
                Piece.Pawn => try writer.writeAll("p"),
                else => unreachable,
            }
        }
    }
};

test "color" {
    var state = SquareData{ .state = 0 };
    try testing.expect(state.is_white());
    try testing.expect(!state.is_black());

    state.set_white();
    try testing.expect(state.is_white());
    try testing.expect(!state.is_black());
    try testing.expect(state.get_color() == Colors.White);

    state.set_black();
    try testing.expect(!state.is_white());
    try testing.expect(state.is_black());
    try testing.expect(state.get_color() == Colors.Black);

    state.set_white();
    try testing.expect(state.is_white());
    try testing.expect(!state.is_black());
    try testing.expect(state.get_color() == Colors.White);

    state.set_black();
    try testing.expect(!state.is_white());
    try testing.expect(state.is_black());
    try testing.expect(state.get_color() == Colors.Black);
}

test "piece" {
    var state = SquareData{ .state = 0 };
    const p = try state.get_piece();
    try testing.expect(p == Piece.None);
    state.set_piece(Piece.Knight);
    const knight_state = state.get_piece() catch Piece.Pawn;
    try testing.expect(knight_state == Piece.Knight);

    state.set_piece(Piece.Rook);
    const rook_state = state.get_piece() catch Piece.Pawn;
    try testing.expect(rook_state == Piece.Rook);

    state.set_piece(Piece.Knight);
    const knight_state2 = state.get_piece() catch Piece.Pawn;
    try testing.expect(knight_state2 == Piece.Knight);

    state.set_piece(Piece.Rook);
    const rook_state2 = state.get_piece() catch Piece.Pawn;
    try testing.expect(rook_state2 == Piece.Rook);
}

test "empty" {
    var state = SquareData{ .state = 0 };
    try testing.expect(state.is_empty());
    try testing.expect(!state.is_occupied());

    state.set_black();
    try testing.expect(!state.is_empty());
    try testing.expect(state.is_occupied());
}

test "color and piece" {
    var state = SquareData{ .state = 0 };

    state.set_piece(Piece.Knight);
    state.set_white();
    try testing.expect(state.is_white());
    try testing.expect(!state.is_black());
    try testing.expect(state.get_color() == Colors.White);
    const p = try state.get_piece();
    try testing.expect(p == Piece.Knight);
}
