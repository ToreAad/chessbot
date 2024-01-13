const std = @import("std");
const g = @import("game.zig");
const s = @import("square.zig");
const p = @import("position.zig");
const a = @import("actions.zig");

const Tactics = enum {
    Support,
    Threaten,
    Fork,
    Pin,
    Skewer,
    Check,
};

const TacticInfo = struct {
    pos: p.Position,
    value: u32,
};

const Tactic = union(Tactics) {
    Support: TacticInfo,
    Threaten: TacticInfo,
    Fork: TacticInfo,
    Pin: TacticInfo,
    Skewer: TacticInfo,
    Check: TacticInfo,
};
const ArrayList = std.ArrayList;
const TacticList = ArrayList(Tactic);

fn piece_value(piece: s.Piece) i32 {
    switch (piece) {
        .Pawn => 1,
        .Rook => 5,
        .Knight => 3,
        .Bishop => 3,
        .Queen => 9,
        .King => 8 + 10 + 6 + 6 + 9 + 1,
    }
}

fn classify_forks(game: *g.Game, pos: p.Position, action_list: a.ActionList, classification_list: *TacticList) void {
    var number_attacks = 0;
    var attack_value = 0;
    var iter = action_list.iterator();
    while (iter.next()) |fork_action| {
        const square = game.board.get_square_at(fork_action.to);
        if (!square.is_empty()) {
            if (square.piece.color != game.active_color) {
                number_attacks += 1;
                attack_value += piece_value(square.piece);
            }
        }
    }

    if (number_attacks > 1) {
        const forkInfo = TacticInfo{
            .pos = pos,
            .value = attack_value,
        };

        const classification = Tactic{
            .Fork = forkInfo,
        };
        try classification_list.append(classification);
    }
}

fn get_skewer_pin_direction(from: p.Position, to: p.Position) p.Position {
    const file_diff = to.file - from.file;
    const rank_diff = to.rank - from.rank;
    if (file_diff == 0 and rank_diff > 0) {
        return p.Position{
            .file = 0,
            .rank = 1,
        };
    } else if (file_diff == 0 and rank_diff < 0) {
        return p.Position{
            .file = 0,
            .rank = -1,
        };
    } else if (file_diff > 0 and rank_diff == 0) {
        return p.Position{
            .file = 1,
            .rank = 0,
        };
    } else if (file_diff < 0 and rank_diff == 0) {
        return p.Position{
            .file = -1,
            .rank = 0,
        };
    } else if (file_diff > 0 and rank_diff > 0) {
        return p.Position{
            .file = 1,
            .rank = 1,
        };
    } else if (file_diff > 0 and rank_diff < 0) {
        return p.Position{
            .file = 1,
            .rank = -1,
        };
    } else if (file_diff < 0 and rank_diff > 0) {
        return p.Position{
            .file = -1,
            .rank = 1,
        };
    } else if (file_diff < 0 and rank_diff < 0) {
        return p.Position{
            .file = -1,
            .rank = -1,
        };
    } else {
        return p.Position{
            .file = 0,
            .rank = 0,
        };
    }
}

fn find_attackable(game: *g.Game, pos: p.Position, direction: p.Position) ?p.Position {
    var current_pos = pos;
    while (true) {
        current_pos = p.add(current_pos, direction);
        if (current_pos.file < 0 or current_pos.file > 7 or current_pos.rank < 0 or current_pos.rank > 7) {
            return p.Position{
                .file = -1,
                .rank = -1,
            };
        }
        const square = game.board.get_square_at(current_pos);
        if (!square.is_empty()) {
            if (square.piece.color != game.active_color) {
                return current_pos;
            } else {
                return null;
            }
        }
    }
}

fn classify_skewers_and_pins(game: *g.Game, pos: p.Position, action_list: a.ActionList, classification_list: *TacticList) void {
    const acting_piece = game.board.get_square_at(pos).piece;
    if (acting_piece == s.Piece.King or acting_piece == s.Piece.Pawn or acting_piece == s.Piece.Knight) {
        return;
    }

    var iter = action_list.iterator();
    while (iter.next()) |action| {
        if (action.type == g.ActionType.Move) {
            const frontline_square = game.board.get_square_at(action.to);
            if (frontline_square.is_empty()) {
                continue;
            }
            if (frontline_square.piece.color == game.active_color) {
                continue;
            }

            const direction = get_skewer_pin_direction(pos, action.to);
            const back_line_pos = find_attackable(game, action.to, direction);
            if (back_line_pos == null) {
                continue;
            }
            const backline_square = game.board.get_square_at(back_line_pos);
            const bakline_value = piece_value(backline_square.piece);
            const frontline_value = piece_value(frontline_square.piece);
            if (frontline_value > bakline_value) {
                const skewerInfo = TacticInfo{
                    .pos = pos,
                    .value = frontline_value - bakline_value,
                };
                const classification = Tactic{
                    .Skewer = skewerInfo,
                };
                try classification_list.append(classification);
            } else if (frontline_value < bakline_value) {
                const pinInfo = TacticInfo{
                    .pos = pos,
                    .value = bakline_value - frontline_value,
                };
                const classification = Tactic{
                    .Pin = pinInfo,
                };
                try classification_list.append(classification);
            }
        }
    }
}

fn classify_threaten_and_support(game: *g.Game, pos: p.Position, list: *a.ActionList, classification_list: *TacticList) void {
    var iter = list.iterator();
    var support_value = 0;
    var threaten_value = 0;
    while (iter.next()) |action| {
        if (action.type == g.ActionType.Move) {
            const square = game.board.get_square_at(action.to);
            if (!square.is_empty()) {
                if (square.piece.color != game.active_color) {
                    threaten_value += piece_value(square.piece);
                    if (square.piece == s.Piece.King) {
                        const classification = Tactic{
                            .Check = TacticInfo{
                                .pos = pos,
                                .value = 0,
                            },
                        };
                        try classification_list.append(classification);
                    }
                } else {
                    support_value += 1;
                }
            }
        }
    }
    if (threaten_value > 0) {
        const classification = Tactic{
            .Threaten = TacticInfo{
                .pos = pos,
                .value = threaten_value,
            },
        };
        try classification_list.append(classification);
    }
    if (support_value > 0) {
        const classification = Tactic{
            .Support = TacticInfo{
                .pos = pos,
                .value = support_value,
            },
        };
        try classification_list.append(classification);
    }
}

fn get_tactics(game: *g.Game, list: *TacticList) void {
    var legal_action_list = a.ActionList.init(game.allocator);
    defer legal_action_list.deinit();
    var unvisited_pieces = 16;
    var file = 0;
    while (file < 8 and unvisited_pieces > 0) : (file += 1) {
        var rank = 0;
        while (rank < 8 and unvisited_pieces > 0) : (rank += 1) {
            const pos = p.Position{
                .file = file,
                .rank = rank,
            };
            a.get_legal_actions_position(game, pos, &legal_action_list);
            defer legal_action_list.clear();

            classify_threaten_and_support(game, pos, legal_action_list, list);
            classify_forks(game, pos, legal_action_list, list);

            unvisited_pieces -= 1;
        }
    }
}
