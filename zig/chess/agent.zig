const std = @import("std");
const g = @import("game.zig");
const a = @import("actions.zig");

const RandomAgent = struct {
    pub fn get_action(self: *RandomAgent, game: *g.Game) !a.Action {
        _ = self;
        const actions = try a.get_actions(game);
        const index = std.rand.Intn(u32, actions.len);
        return actions[index];
    }
};
