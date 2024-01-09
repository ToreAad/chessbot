const std = @import("std");
const g = @import("game.zig");
const s = @import("square.zig");

const ArrayList = std.ArrayList;

const ActionList = ArrayList(g.Action);

fn get_legal_actions(game: g.Game) ActionList {
    const list = ActionList.init(game.allocator);
    _ = list;
    const active_player = game.active_player;
    _ = active_player;
    unreachable;
}
