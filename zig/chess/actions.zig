const std = @import("std");
const testing = std.testing;

const Piece = @import("pieces.zig").Piece;
const Colors = @import("colors.zig").Colors;
const Position = @import("position.zig").Position;

const g = @import("game.zig");
const p = @import("position.zig");
const r = @import("rules.zig");

pub const ActionList = std.ArrayList(g.Action);

fn get_legal_actions_pawn(game: *g.Game, pos: p.Position, list: *ActionList) !void {
    const rank_diffs = if (game.active_color == Colors.White) [4]i16{ 1, 1, 1, 2 } else [4]i16{ -1, -1, -1, -2 };
    const file_diffs = [4]i16{ 0, -1, 1, 0 };

    for (rank_diffs, 0..) |rank_diff, i| {
        const file_diff = file_diffs[i];
        const pawn_file = pos.file + file_diff;
        const pawn_rank = pos.rank + rank_diff;
        if (pawn_file < 0 or pawn_file > 7 or pawn_rank < 0 or pawn_rank > 7) {
            continue;
        }

        const possible_move = p.Position{
            .file = @as(u8, @intCast(pawn_file)),
            .rank = @as(u8, @intCast(pawn_rank)),
        };
        const move_action = g.Action{
            .Move = g.MoveInfo{
                .from = pos,
                .to = possible_move,
            },
        };
        // Check if legal move:
        if (try r.legal_action(game, move_action)) {
            if (possible_move.rank == 0 or possible_move.rank == 7) {
                const knight_promotion = g.Action{
                    .Promotion = g.PromotionInfo{
                        .move = move_action.Move,
                        .piece = Piece.Knight,
                    },
                };
                try list.append(knight_promotion);
                const queen_promotion = g.Action{
                    .Promotion = g.PromotionInfo{
                        .move = move_action.Move,
                        .piece = Piece.Queen,
                    },
                };
                try list.append(queen_promotion);
            } else {
                try list.append(move_action);
            }
        }
    }

    const en_passant_rank_diffs = if (game.active_color == Colors.White) [2]i16{ 1, 1 } else [2]i16{ -1, -1 };
    const en_passant_file_diffs = [2]i16{ -1, 1 };
    for (en_passant_rank_diffs, 0..) |rank_diff, i| {
        const file_diff = en_passant_file_diffs[i];

        const pawn_file = pos.file + file_diff;
        const pawn_rank = pos.rank + rank_diff;

        if (pawn_file < 0 or pawn_file > 7 or pawn_rank < 0 or pawn_rank > 7) {
            continue;
        }

        const possible_move = p.Position{
            .file = @as(u8, @intCast(pawn_file)),
            .rank = @as(u8, @intCast(pawn_rank)),
        };

        const enPassantInfo = g.EnPassantInfo{
            .move = g.MoveInfo{
                .from = pos,
                .to = possible_move,
            },
            .target = p.Position{
                .file = @as(u8, @intCast(pawn_file)),
                .rank = @as(u8, @intCast(pos.rank)),
            },
        };

        const enpassant_action = g.Action{
            .EnPassant = enPassantInfo,
        };

        // Check if legal move:
        if (try r.legal_action(game, enpassant_action)) {
            try list.append(enpassant_action);
        }
    }
}

fn get_legal_actions_rook(game: *g.Game, pos: p.Position, list: *ActionList) !void {
    const rank_deltas = [4]i16{ 1, 0, -1, 0 };
    const file_deltas = [4]i16{ 0, 1, 0, -1 };

    for (rank_deltas, 0..) |rank_delta, i| {
        const file_diff = file_deltas[i];
        for (1..8) |multiplier| {
            const rook_file = pos.file + file_diff * @as(i16, @intCast(multiplier));
            const rook_rank = pos.rank + rank_delta * @as(i16, @intCast(multiplier));

            if (rook_file < 0 or rook_file > 7 or rook_rank < 0 or rook_rank > 7) {
                break;
            }

            const possible_move = p.Position{
                .file = @as(u8, @intCast(rook_file)),
                .rank = @as(u8, @intCast(rook_rank)),
            };
            const move_action = g.Action{
                .Move = g.MoveInfo{
                    .from = pos,
                    .to = possible_move,
                },
            };
            // Check if legal move:
            if (try r.legal_action(game, move_action)) {
                try list.append(move_action);
            }

            const square = try game.board.get_square_at(possible_move);
            if (!square.empty) {
                break;
            }
        }
    }
}

fn get_legal_actions_knight(game: *g.Game, pos: p.Position, list: *ActionList) !void {
    const rank_diffs = [8]i16{ 2, 1, -1, -2, -2, -1, 1, 2 };
    const file_diffs = [8]i16{ 1, 2, 2, 1, -1, -2, -2, -1 };

    for (rank_diffs, 0..) |rank_diff, i| {
        const file_diff = file_diffs[i];
        const knight_file = pos.file + file_diff;
        const knight_rank = pos.rank + rank_diff;
        if (knight_file < 0 or knight_file > 7 or knight_rank < 0 or knight_rank > 7) {
            continue;
        }

        const possible_move = p.Position{
            .file = @as(u8, @intCast(knight_file)),
            .rank = @as(u8, @intCast(knight_rank)),
        };

        const move_action = g.Action{
            .Move = g.MoveInfo{
                .from = pos,
                .to = possible_move,
            },
        };
        // Check if legal move:
        if (try r.legal_action(game, move_action)) {
            try list.append(move_action);
        }
    }
}

fn get_legal_actions_bishop(game: *g.Game, pos: p.Position, list: *ActionList) !void {
    const rank_deltas = [4]i16{ 1, 1, -1, -1 };
    const file_deltas = [4]i16{ 1, -1, 1, -1 };

    for (rank_deltas, 0..) |rank_delta, i| {
        const file_diff = file_deltas[i];
        for (1..8) |multiplier| {
            const bishop_file = pos.file + file_diff * @as(i16, @intCast(multiplier));
            const bishop_rank = pos.rank + rank_delta * @as(i16, @intCast(multiplier));

            if (bishop_file < 0 or bishop_file > 7 or bishop_rank < 0 or bishop_rank > 7) {
                break;
            }

            const possible_move = p.Position{
                .file = @as(u8, @intCast(bishop_file)),
                .rank = @as(u8, @intCast(bishop_rank)),
            };

            const move_action = g.Action{
                .Move = g.MoveInfo{
                    .from = pos,
                    .to = possible_move,
                },
            };
            // Check if legal move:
            if (try r.legal_action(game, move_action)) {
                try list.append(move_action);
            }

            const square = try game.board.get_square_at(possible_move);
            if (!square.empty) {
                break;
            }
        }
    }
}

fn get_legal_actions_queen(game: *g.Game, pos: p.Position, list: *ActionList) !void {
    const rank_deltas = [8]i16{ 1, 1, -1, -1, 1, 0, -1, 0 };
    const file_deltas = [8]i16{ 1, -1, 1, -1, 0, 1, 0, -1 };

    for (rank_deltas, 0..) |rank_delta, i| {
        const file_diff = file_deltas[i];
        for (1..8) |multiplier| {
            const queen_file = pos.file + file_diff * @as(i16, @intCast(multiplier));
            const queen_rank = pos.rank + rank_delta * @as(i16, @intCast(multiplier));

            if (queen_file < 0 or queen_file > 7 or queen_rank < 0 or queen_rank > 7) {
                break;
            }

            const possible_move = p.Position{
                .file = @as(u8, @intCast(queen_file)),
                .rank = @as(u8, @intCast(queen_rank)),
            };

            const move_action = g.Action{
                .Move = g.MoveInfo{
                    .from = pos,
                    .to = possible_move,
                },
            };
            // Check if legal move:
            if (try r.legal_action(game, move_action)) {
                try list.append(move_action);
            }

            const square = try game.board.get_square_at(possible_move);
            if (!square.empty) {
                break;
            }
        }
    }
}

fn get_legal_actions_king(game: *g.Game, pos: p.Position, list: *ActionList) !void {
    const rank_diffs = [8]i16{ 1, 1, 1, 0, 0, -1, -1, -1 };
    const file_diffs = [8]i16{ 1, 0, -1, 1, -1, 1, 0, -1 };

    for (rank_diffs, 0..) |rank_diff, i| {
        const file_diff = file_diffs[i];

        const king_file = pos.file + file_diff;
        const king_rank = pos.rank + rank_diff;

        if (king_file < 0 or king_file > 7 or king_rank < 0 or king_rank > 7) {
            continue;
        }

        const possible_move = p.Position{
            .file = @as(u8, @intCast(king_file)),
            .rank = @as(u8, @intCast(king_rank)),
        };

        const move_action = g.Action{
            .Move = g.MoveInfo{
                .from = pos,
                .to = possible_move,
            },
        };
        // Check if legal move:
        if (try r.legal_action(game, move_action)) {
            try list.append(move_action);
        }
    }

    // Castling
    const king_side_castle = g.Action{ .Castle = g.CastleInfo{
        .color = game.active_color,
        .king_side = true,
    } };
    if (try r.legal_action(game, king_side_castle)) {
        try list.append(king_side_castle);
    }

    const queen_side_castle = g.Action{ .Castle = g.CastleInfo{
        .color = game.active_color,
        .king_side = false,
    } };
    if (try r.legal_action(game, queen_side_castle)) {
        try list.append(queen_side_castle);
    }
}

pub fn get_legal_actions_position(game: *g.Game, pos: p.Position, list: *ActionList) !void {
    const square = try game.board.get_square_at(pos);
    if (square.empty) {
        return;
    }
    if (square.color != game.active_color) {
        return;
    }
    switch (square.piece) {
        .Pawn => try get_legal_actions_pawn(game, pos, list),
        .Rook => try get_legal_actions_rook(game, pos, list),
        .Knight => try get_legal_actions_knight(game, pos, list),
        .Bishop => try get_legal_actions_bishop(game, pos, list),
        .Queen => try get_legal_actions_queen(game, pos, list),
        .King => try get_legal_actions_king(game, pos, list),
        .None => unreachable,
    }
}

pub fn get_legal_actions(game: *g.Game, list: *ActionList) !void {
    const resign_action = g.Action.Resign;
    try list.append(resign_action);

    var file: u8 = 0;
    while (file < 8) : (file += 1) {
        var rank: u8 = 0;
        while (rank < 8) : (rank += 1) {
            const pos = p.Position{
                .file = file,
                .rank = rank,
            };
            try get_legal_actions_position(game, pos, list);
        }
    }
}

test "get legal actions pawn" {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    const board_setup =
        \\K.......
        \\P.......
        \\.p......
        \\........
        \\........
        \\........
        \\........
        \\k.......
    ;
    try game.board.set_up_from_string(board_setup);

    var list = ActionList.init(allocator);
    defer list.deinit();

    const pawn_pos = p.Position{ .file = 0, .rank = 1 };

    try get_legal_actions_position(&game, pawn_pos, &list);

    const owned_slice = try list.toOwnedSlice();
    defer allocator.free(owned_slice);

    try testing.expect(3 == owned_slice.len);
}

test "get legal actions rook" {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    const board_setup =
        \\K...N..R
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\k......p
    ;
    try game.board.set_up_from_string(board_setup);

    var list = ActionList.init(allocator);
    defer list.deinit();

    const pawn_pos = p.Position{ .file = 7, .rank = 0 };

    try get_legal_actions_position(&game, pawn_pos, &list);

    const owned_slice = try list.toOwnedSlice();
    defer allocator.free(owned_slice);

    try testing.expect(9 == owned_slice.len);
}

test "get legal actions bishop" {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    const board_setup =
        \\K.......
        \\.P...P..
        \\........
        \\...B....
        \\........
        \\.p...P..
        \\........
        \\k.......
    ;
    try game.board.set_up_from_string(board_setup);

    var list = ActionList.init(allocator);
    defer list.deinit();

    const pawn_pos = p.Position{ .file = 3, .rank = 3 };

    try get_legal_actions_position(&game, pawn_pos, &list);

    const owned_slice = try list.toOwnedSlice();
    defer allocator.free(owned_slice);

    try testing.expect(5 == owned_slice.len);
}

test "get legal actions queen" {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    const board_setup =
        \\K..P....
        \\.P...P..
        \\........
        \\p..Q....
        \\........
        \\.p...P..
        \\........
        \\k..p....
    ;
    try game.board.set_up_from_string(board_setup);

    var list = ActionList.init(allocator);
    defer list.deinit();

    const pawn_pos = p.Position{ .file = 3, .rank = 3 };

    try get_legal_actions_position(&game, pawn_pos, &list);

    const owned_slice = try list.toOwnedSlice();
    defer allocator.free(owned_slice);

    try testing.expect(18 == owned_slice.len);
}

test "get legal actions king" {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    const board_setup =
        \\R...K..R
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\....k...
    ;
    try game.board.set_up_from_string(board_setup);

    var list = ActionList.init(allocator);
    defer list.deinit();

    const king_pos = p.Position{ .file = 4, .rank = 0 };

    try get_legal_actions_position(&game, king_pos, &list);

    const owned_slice = try list.toOwnedSlice();
    defer allocator.free(owned_slice);

    try testing.expect(7 == owned_slice.len);
}

test "get legal actions board" {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    const board_setup =
        \\R...K..R
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\....k...
    ;
    try game.board.set_up_from_string(board_setup);

    var list = ActionList.init(allocator);
    defer list.deinit();

    try get_legal_actions(&game, &list);

    const owned_slice = try list.toOwnedSlice();
    defer allocator.free(owned_slice);

    const expected_actions = 1 + 5 + 7 + 7 + 7;
    try testing.expect(expected_actions == owned_slice.len);
}

test "get legal actions weird board" {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    const board_setup =
        \\........
        \\.K......
        \\........
        \\........
        \\.......p
        \\........
        \\........
        \\.......k
    ;
    try game.board.set_up_from_string(board_setup);

    var list = ActionList.init(allocator);
    defer list.deinit();
    game.active_color = Colors.Black;

    try get_legal_actions_position(&game, p.Position{ .file = 7, .rank = 4 }, &list);

    try testing.expect(list.items.len > 0);
}
