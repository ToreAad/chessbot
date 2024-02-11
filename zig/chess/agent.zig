const std = @import("std");
const testing = std.testing;

const g = @import("game.zig");
const a = @import("actions.zig");
const Piece = @import("pieces.zig").Piece;

const ActionList = @import("actions.zig").ActionList;

const RndGen = std.rand.DefaultPrng;
const Xoshiro256 = std.rand.Xoshiro256;

pub const RandomAgent = struct {
    rnd: Xoshiro256,

    pub fn get_action(self: *RandomAgent, game: *g.Game) !g.Action {
        var action_list = ActionList.init(game.allocator);
        defer action_list.deinit();
        try a.get_legal_actions(game, &action_list);
        if (action_list.items.len == 1) {
            return action_list.items[0];
        }
        const index = self.rnd.random().int(u32) % (action_list.items.len - 1);
        return action_list.items[index + 1];
    }
};

test "random agent" {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();
    var agent = RandomAgent{ .rnd = RndGen.init(0) };
    const action = try agent.get_action(&game);
    const r1 = game.apply_action(action);
    const second_action = try agent.get_action(&game);
    const r2 = game.apply_action(second_action);
    game.undo_action(r2);
    game.undo_action(r1);
}
