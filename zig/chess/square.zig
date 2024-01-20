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
    Queen = 1 << 7,
    King = 1 << 8,
    Moved = 1 << 9,
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
        @intFromEnum(SquareFlags.Queen) => {
            return Piece.Queen;
        },
        @intFromEnum(SquareFlags.King) => {
            return Piece.King;
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
        Piece.Queen => {
            return @intFromEnum(SquareFlags.Queen);
        },
        Piece.King => {
            return @intFromEnum(SquareFlags.King);
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
    @intFromEnum(SquareFlags.Queen) |
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

    pub fn is_black(self: *SquareData) bool {
        return (self.state & @intFromEnum(SquareFlags.Black)) > 0;
    }

    pub fn is_white(self: *SquareData) bool {
        return (self.state & @intFromEnum(SquareFlags.Black)) == 0;
    }

    pub fn get_color(self: *SquareData) Colors {
        return if (self.is_black()) Colors.Black else Colors.White;
    }

    pub fn set_moved(self: *SquareData) void {
        self.state = self.state | @intFromEnum(SquareFlags.Moved);
    }

    pub fn set_unmoved(self: *SquareData) void {
        self.state = self.state ^ @intFromEnum(SquareFlags.Moved);
    }

    pub fn is_moved(self: *SquareData) bool {
        return (self.state & @intFromEnum(SquareFlags.Moved)) > 0;
    }

    pub fn get_piece(self: *SquareData) error{InvalidState}!Piece {
        const val = self.state & PieceBand;
        return pieceFromInt(val);
    }

    pub fn set_piece(self: *SquareData, piece: Piece) void {
        self.state = self.state & ~(PieceBand);
        self.state = self.state | intFromPiece(piece);
    }

    pub fn is_occupied(self: *SquareData) bool {
        return self.state > 0;
    }

    pub fn is_empty(self: *SquareData) bool {
        return self.state == 0;
    }

    pub fn clear(self: *SquareData) void {
        self.state = 0;
    }

    pub fn set_state(self: *SquareData, state: u32) void {
        self.state = state;
    }

    pub fn copy_from(self: *SquareData, other: *SquareData) void {
        self.state = other.state;
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

test "moved" {
    var state = SquareData{ .state = 0 };
    try testing.expect(!state.is_moved());

    state.set_moved();
    try testing.expect(state.is_moved());

    state.set_unmoved();
    try testing.expect(!state.is_moved());

    state.set_moved();
    try testing.expect(state.is_moved());

    state.set_unmoved();
    try testing.expect(!state.is_moved());
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
