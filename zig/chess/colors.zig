pub const Colors = enum {
    White,
    Black,

    pub fn flip(self: Colors) Colors {
        return switch (self) {
            Colors.White => Colors.Black,
            Colors.Black => Colors.White,
        };
    }
};
