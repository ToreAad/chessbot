const std = @import("std");
const testing = std.testing;

const g = @import("game.zig");
const b = @import("board.zig");
const s = @import("square.zig");
const r = @import("rules.zig");
const agent = @import("agent.zig");
const Colors = @import("colors.zig").Colors;
const a = @import("actions.zig");
const p = @import("position.zig");
const ActionList = @import("actions.zig").ActionList;

const RndGen = std.rand.DefaultPrng;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var game = g.Game{ .allocator = gpa.allocator() };
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

    var white_player: agent.RandomAgent = undefined;
    var black_player: agent.RandomAgent = undefined;
    white_player.init();
    black_player.init();

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

test "winnable" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var game = g.Game{ .allocator = gpa.allocator() };
    game.set_up();

    var white_player: agent.RandomAgent = undefined;
    var black_player: agent.RandomAgent = undefined;
    white_player.init();
    black_player.init();
    for (0..5000) |i| {
        const action = switch (i % 2) {
            0 => try white_player.get_action(&game),
            1 => try black_player.get_action(&game),
            else => unreachable,
        };
        switch (action) {
            .Resign => {
                break;
            },
            .Move => {
                _ = try game.apply_action(action);
            },
            .Castle => {
                _ = try game.apply_action(action);
            },
            .Promotion => {
                _ = try game.apply_action(action);
            },
            .EnPassant => {
                _ = try game.apply_action(action);
            },

            else => {
                _ = try game.apply_action(action);
            },
        }
        if (try game.is_remis()) {
            break;
        }
    }
}
