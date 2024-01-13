const std = @import("std");
const g = @import("game.zig");
const b = @import("board.zig");
const s = @import("square.zig");
const agent = @import("agent.zig");

fn piece_to_string(piece: s.Piece) []const u8 {
    switch (piece) {
        .WhitePawn => return "P",
        .WhiteKnight => return "N",
        .WhiteBishop => return "B",
        .WhiteRook => return "R",
        .WhiteQueen => return "Q",
        .WhiteKing => return "K",
        .BlackPawn => return "p",
        .BlackKnight => return "n",
        .BlackBishop => return "b",
        .BlackRook => return "r",
        .BlackQueen => return "q",
        .BlackKing => return "k",
    }
}

fn print_board(board: *b.Board) void {
    var i = 0;
    std.debug.print("  a b c d e f g h\n");
    while (i < 8) : (i += 1) {
        std.debug.print("{d} {s} {s} {s} {s} {s} {s} {s} {s}\n", .{
            8 - i,
            piece_to_string(board.squares[i * 8 + 0].piece),
            piece_to_string(board.squares[i * 8 + 1].piece),
            piece_to_string(board.squares[i * 8 + 2].piece),
            piece_to_string(board.squares[i * 8 + 3].piece),
            piece_to_string(board.squares[i * 8 + 4].piece),
            piece_to_string(board.squares[i * 8 + 5].piece),
            piece_to_string(board.squares[i * 8 + 6].piece),
            piece_to_string(board.squares[i * 8 + 7].piece),
        });
    }
}

pub fn main() !void {
    var game = g.Game{};
    game.init();

    const white_player = agent.RandomAgent{};
    const black_player = agent.RandomAgent{};
    print_board(&game.board);
    for (0..100) |i| {
        switch (i % 2) {
            0 => {
                const action = white_player.get_action(&game);
                if (action.type == g.Action.Resign) {
                    std.debug.print("White resigns\n");
                    return;
                }
                game.apply_action(action);
            },
            1 => {
                const action = black_player.get_action(&game);
                game.apply_action(action);
                if (action.type == g.Action.Resign) {
                    std.debug.print("Black resigns\n");
                    return;
                }
            },
        }
        print_board(&game.board);
    }
}
