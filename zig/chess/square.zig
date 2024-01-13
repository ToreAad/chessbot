pub const Colors = enum(u32) {
    White = 0,
    Black = @intFromEnum(SquareFlags.Black),
};

pub const SquareFlags = enum(u32) {
    Black = 1 << 2,
    Pawn = 1 << 3,
    Knight = 1 << 4,
    Bishop = 1 << 5,
    Rook = 1 << 6,
    Queen = 1 << 7,
    King = 1 << 8,
    Moved = 1 << 9,
};

pub const Piece = enum(u32) {
    Pawn = @intFromEnum(SquareFlags.Pawn),
    Knight = @intFromEnum(SquareFlags.Knight),
    Bishop = @intFromEnum(SquareFlags.Bishop),
    Rook = @intFromEnum(SquareFlags.Rook),
    Queen = @intFromEnum(SquareFlags.Queen),
    King = @intFromEnum(SquareFlags.King),
};

pub const Square = struct {
    empty: bool,
    color: Colors,
    piece: Piece,
    moved: bool,
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
    return if (is_black(state)) Colors.Black else Colors.White;
}

fn set_moved(state: u32) u32 {
    return state | @intFromEnum(SquareFlags.Moved);
}

fn set_unmoved(state: u32) u32 {
    return state ^ @intFromEnum(SquareFlags.Moved);
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
