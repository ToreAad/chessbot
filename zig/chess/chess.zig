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

fn has_legal_moves(game: *g.Game, color: Colors) !bool {
    var action_list = ActionList.init(game.allocator);
    defer action_list.deinit();
    if (color != game.active_color) {
        game.flip_player();
        defer game.flip_player();
    }
    try a.get_legal_actions(game, &action_list);
    return action_list.items.len > 1;
}

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
        \\ ........
        \\ rnbqkbnr
    ;
    try game.board.set_up_from_string(board_setup);

    var white_player = agent.RandomAgent{ .rnd = RndGen.init(0) };
    var black_player = agent.RandomAgent{ .rnd = RndGen.init(0) };
    std.debug.print("Game started\n", .{});
    std.debug.print("\x1b[2J{s}\n", .{&game.board});
    for (0..5000) |i| {
        const action = switch (i % 2) {
            0 => try white_player.get_action(&game),
            1 => try black_player.get_action(&game),
            else => unreachable,
        };
        switch (action) {
            .Resign => {
                const is_checked = try r.is_in_check(&game, game.active_color);
                const can_act = try has_legal_moves(&game, game.active_color);
                if (is_checked or can_act) {
                    std.debug.print("\x1b[2J{s} wins\n{}\n", .{ &game.active_color.flip(), &game.board });
                } else {
                    std.debug.print("\x1b[2JRemis, game over\n{}\n", .{&game.board});
                }
                return;
            },
            .Move => {
                _ = game.apply_action(action);
            },
            .Castle => {
                _ = game.apply_action(action);
            },
            .Promotion => {
                _ = game.apply_action(action);
            },
            .EnPassant => {
                _ = game.apply_action(action);
            },

            else => {
                _ = game.apply_action(action);
            },
        }
        std.debug.print("\x1b[2J{s}\n", .{&game.board});
        std.time.sleep(1_000_000);
        // std.time.sleep(10_000);
        if (try game.is_remis()) {
            std.debug.print("Remis, game over\n", .{});
            break;
        }
    }
}

test "winnable" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var game = g.Game{ .allocator = gpa.allocator() };
    game.set_up();

    var white_player = agent.RandomAgent{ .rnd = RndGen.init(0) };
    var black_player = agent.RandomAgent{ .rnd = RndGen.init(0) };
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
                _ = game.apply_action(action);
            },
            .Castle => {
                _ = game.apply_action(action);
            },
            .Promotion => {
                _ = game.apply_action(action);
            },
            .EnPassant => {
                _ = game.apply_action(action);
            },

            else => {
                _ = game.apply_action(action);
            },
        }
        if (try game.is_remis()) {
            break;
        }
    }
}
