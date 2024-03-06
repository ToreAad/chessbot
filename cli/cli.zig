const std = @import("std");
const testing = std.testing;
const chess = @import("chess");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var game = chess.Game{ .allocator = gpa.allocator() };
    game.set_up();

    const board_setup =
        \\ RNBQKBNR
        \\ PPPPPPPP
        \\ ........
        \\ ........
        \\ ........
        \\ ........
        \\ pppppppp
        \\ rnbqkbnr
    ;
    try game.board.set_up_from_string(board_setup);

    var white_player = chess.agent.RandomAgent.init();
    var black_player = chess.agent.RandomAgent.init();

    std.debug.print("Game started\n", .{});
    std.debug.print("\x1b[2J{s}\n", .{&game.board});
    for (0..5000) |i| {
        const action = switch (i % 2) {
            0 => try white_player.get_action(&game),
            1 => try black_player.get_action(&game),
            else => unreachable,
        };
        const game_state = try game.apply_action(action);
        switch (game_state) {
            .Checkmate => {
                std.debug.print("\x1b[2J{} Checkmated - {} wins\n{}\n", .{ &game.active_color, &game.active_color.flip(), &game.board });
                return;
            },
            .Remis => {
                std.debug.print("\x1b[2JRemis, game over!\n{}\n", .{&game.board});
                return;
            },
            .Resign => {
                std.debug.print("\x1b[2J{} resigns - {} wins\n{}\n", .{ &game.active_color, &game.active_color.flip(), &game.board });
                return;
            },
            else => {
                std.debug.print("\x1b[2J{s}\n", .{&game.board});
            },
        }
        std.time.sleep(1_000_000);
    }
}
