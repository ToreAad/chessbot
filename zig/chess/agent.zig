const std = @import("std");
const testing = std.testing;

const g = @import("game.zig");
const a = @import("actions.zig");
const Piece = @import("pieces.zig").Piece;

const ActionList = @import("actions.zig").ActionList;

const RndGen = std.rand.DefaultPrng;

const RandomAgent = struct {
    pub fn get_action(self: *RandomAgent, game: *g.Game) !g.Action {
        _ = self;
        var action_list = ActionList.init(game.allocator);
        defer action_list.deinit();
        try a.get_legal_actions(game, &action_list);
        var rnd = RndGen.init(0);
        const index = rnd.random().int(u32) % action_list.items.len;
        return action_list.items[index];
    }
};

test "random agent" {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();
    var agent = RandomAgent{};
    const action = try agent.get_action(&game);
    const r1 = game.apply_action(action);
    const second_action = try agent.get_action(&game);
    const r2 = game.apply_action(second_action);
    game.undo_action(r2);
    game.undo_action(r1);
}
