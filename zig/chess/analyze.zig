const std = @import("std");
const g = @import("game.zig");
const s = @import("square.zig");
const p = @import("position.zig");
const r = @import("rules.zig");

const ActionClassifications = enum {
    Capture,
    Support,
    Threat,
    Vulnerable,
    Fork,
    Pin,
    Skewer,
    Check,
    Checkmate,
    Remis,
};

const ActionClassification = union(ActionClassifications) {
    Capture: g.Action,
    Support: g.Action,
    Threat: g.Action,
    Vulnerable: g.Action,
    Fork: g.Action,
    Pin: g.Action,
    Skewer: g.Action,
    Check: g.Action,
    Checkmate: g.Action,
    Remis: g.Action,
};

const ArrayList = std.ArrayList;
const ActionList = ArrayList(g.Action);
const ActionClassificationList = ArrayList(ActionClassification);

fn get_legal_actions_pawn(game: *g.Game, pos: p.Position, list: *ActionList) void {
    const rank_diffs = if (game.active_color == s.Colors.White) []i8{ 1, 1, 1, 2 } else []i8{ -1, -1, -1, -2 };
    const file_diffs = []i8{ 0, -1, 1, 0 };

    for (rank_diffs, 0..) |rank_diff, i| {
        const file_diff = file_diffs[i];
        const possible_move = p.Position{ .file = pos.file + file_diff, .rank = pos.rank + rank_diff };
        if (possible_move.file < 0 or possible_move.file > 7 or possible_move.rank < 0 or possible_move.rank > 7) {
            continue;
        }
        const move_action = g.Action{
            .type = g.ActionType.Move,
            .from = pos,
            .to = possible_move,
        };
        // Check if legal move:
        if (r.is_legal_move(game, move_action)) {
            try list.append(move_action);
        }
    }

    const en_passant_rank_diffs = if (game.active_color == s.Colors.White) []i8{ 1, 1 } else []i8{ -1, -1 };
    const en_passant_file_diffs = []i8{ -1, 1 };
    for (en_passant_rank_diffs, 0..) |rank_diff, i| {
        const file_diff = en_passant_file_diffs[i];
        const possible_move = p.Position{ .file = pos.file + file_diff, .rank = pos.rank + rank_diff };
        if (possible_move.file < 0 or possible_move.file > 7 or possible_move.rank < 0 or possible_move.rank > 7) {
            continue;
        }
        const move_action = g.Action{
            .type = g.ActionType.EnPassant,
            .from = pos,
            .to = possible_move,
        };
        // Check if legal move:
        if (r.is_legal_move(game, move_action)) {
            try list.append(move_action);
        }
    }
}

fn get_legal_actions_rook(game: *g.Game, pos: p.Position, list: *ActionList) void {
    const rank_deltas = []i8{ 1, 0, -1, 0 };
    const file_deltas = []i8{ 0, 1, 0, -1 };

    for (rank_deltas, 0..) |rank_delta, i| {
        const file_diff = file_deltas[i];
        for (1..8) |multiplier| {
            const possible_move = p.Position{ .file = pos.file + file_diff * multiplier, .rank = pos.rank + rank_delta * multiplier };
            if (possible_move.file < 0 or possible_move.file > 7 or possible_move.rank < 0 or possible_move.rank > 7) {
                break;
            }
            const move_action = g.Action{
                .type = g.ActionType.Move,
                .from = pos,
                .to = possible_move,
            };
            // Check if legal move:
            if (r.is_legal_move(game, move_action)) {
                try list.append(move_action);
            }

            const square = game.board.get_square_at(possible_move);
            if (!square.is_empty()) {
                break;
            }
        }
    }
}

fn get_legal_actions_knight(game: *g.Game, pos: p.Position, list: *ActionList) void {
    const rank_diffs = []i8{ 2, 1, -1, -2, -2, -1, 1, 2 };
    const file_diffs = []i8{ 1, 2, 2, 1, -1, -2, -2, -1 };

    for (rank_diffs, 0..) |rank_diff, i| {
        const file_diff = file_diffs[i];
        const possible_move = p.Position{ .file = pos.file + file_diff, .rank = pos.rank + rank_diff };
        if (possible_move.file < 0 or possible_move.file > 7 or possible_move.rank < 0 or possible_move.rank > 7) {
            continue;
        }
        const move_action = g.Action{
            .type = g.ActionType.Move,
            .from = pos,
            .to = possible_move,
        };
        // Check if legal move:
        if (r.is_legal_move(game, move_action)) {
            try list.append(move_action);
        }
    }
}

fn get_legal_actions_bishop(game: *g.Game, pos: p.Position, list: *ActionList) void {
    const rank_deltas = []i8{ 1, 1, -1, -1 };
    const file_deltas = []i8{ 1, -1, 1, -1 };

    for (rank_deltas, 0..) |rank_delta, i| {
        const file_diff = file_deltas[i];
        for (1..8) |multiplier| {
            const possible_move = p.Position{ .file = pos.file + file_diff * multiplier, .rank = pos.rank + rank_delta * multiplier };
            if (possible_move.file < 0 or possible_move.file > 7 or possible_move.rank < 0 or possible_move.rank > 7) {
                break;
            }
            const move_action = g.Action{
                .type = g.ActionType.Move,
                .from = pos,
                .to = possible_move,
            };
            // Check if legal move:
            if (r.is_legal_move(game, move_action)) {
                try list.append(move_action);
            }

            const square = game.board.get_square_at(possible_move);
            if (!square.is_empty()) {
                break;
            }
        }
    }
}

fn get_legal_actions_queen(game: *g.Game, pos: p.Position, list: *ActionList) void {
    const rank_deltas = []i8{ 1, 1, -1, -1, 1, 0, -1, 0 };
    const file_deltas = []i8{ 1, -1, 1, -1, 0, 1, 0, -1 };

    for (rank_deltas, 0..) |rank_delta, i| {
        const file_diff = file_deltas[i];
        for (1..8) |multiplier| {
            const possible_move = p.Position{ .file = pos.file + file_diff * multiplier, .rank = pos.rank + rank_delta * multiplier };
            if (possible_move.file < 0 or possible_move.file > 7 or possible_move.rank < 0 or possible_move.rank > 7) {
                break;
            }
            const move_action = g.Action{
                .type = g.ActionType.Move,
                .from = pos,
                .to = possible_move,
            };
            // Check if legal move:
            if (r.is_legal_move(game, move_action)) {
                try list.append(move_action);
            }

            const square = game.board.get_square_at(possible_move);
            if (!square.is_empty()) {
                break;
            }
        }
    }
}

fn get_legal_actions_king(game: *g.Game, pos: p.Position, list: *ActionList) void {
    const rank_diffs = []i8{ 1, 1, 1, 0, 0, -1, -1, -1 };
    const file_diffs = []i8{ 1, 0, -1, 1, -1, 1, 0, -1 };

    for (rank_diffs, 0..) |rank_diff, i| {
        const file_diff = file_diffs[i];
        const possible_move = p.Position{ .file = pos.file + file_diff, .rank = pos.rank + rank_diff };
        if (possible_move.file < 0 or possible_move.file > 7 or possible_move.rank < 0 or possible_move.rank > 7) {
            continue;
        }
        const move_action = g.Action{
            .type = g.ActionType.Move,
            .from = pos,
            .to = possible_move,
        };
        // Check if legal move:
        if (r.is_legal_move(game, move_action)) {
            try list.append(move_action);
        }
    }
}

fn get_legal_actions(game: *g.Game, list: *ActionList) void {
    const active_player = game.active_player;
    const resign_action = g.Action{
        .type = g.ActionType.Resign,
    };
    try list.append(resign_action);

    var unvisited_pieces = 16;
    var file = 0;
    while (file < 8 and unvisited_pieces > 0) : (file += 1) {
        var rank = 0;
        while (rank < 8 and unvisited_pieces > 0) : (rank += 1) {
            const pos = s.Square{
                .file = file,
                .rank = rank,
            };
            const square = game.board.get_square_at(pos);
            if (square.is_empty()) {
                continue;
            }
            if (square.piece.color != active_player) {
                continue;
            }
            unvisited_pieces -= 1;
            switch (square.piece) {
                .Pawn => get_legal_actions_pawn(game, pos, list),
                .Rook => get_legal_actions_rook(game, pos, list),
                .Knight => get_legal_actions_knight(game, pos, list),
                .Bishop => get_legal_actions_bishop(game, pos, list),
                .Queen => get_legal_actions_queen(game, pos, list),
                .King => get_legal_actions_king(game, pos, list),
            }
        }
    }
}

fn classify_capture(game: *g.Game, action: g.Action, classification_list: *ActionClassificationList) void {
    const square = game.board.get_square_at(action.to);
    if (square.is_empty()) {
        return;
    }
    if (square.piece.color == game.active_color) {
        return;
    }
    const classification = ActionClassification{
        .Capture = action,
    };
    try classification_list.append(classification);
}

fn classify_actions(game: *g.Game, list: *ActionList, classification_list: *ActionClassificationList) void {
    var iter = list.iterator();
    while (iter.next()) |action| {
        if (action.type == g.ActionType.Move) {
            classify_capture(game, action, classification_list);
        }
    }
}
