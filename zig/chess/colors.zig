const std = @import("std");

pub const Colors = enum {
    White,
    Black,

    pub fn flip(self: Colors) Colors {
        return switch (self) {
            Colors.White => Colors.Black,
            Colors.Black => Colors.White,
        };
    }

    pub fn format(
        self: Colors,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        switch (self) {
            Colors.White => try writer.print("White", .{}),
            Colors.Black => try writer.print("Black", .{}),
        }
    }
};
