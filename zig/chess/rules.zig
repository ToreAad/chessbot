const std = @import("std");
const testing = std.testing;

const Piece = @import("pieces.zig").Piece;
const Colors = @import("colors.zig").Colors;
const Position = @import("position.zig").Position;

const g = @import("game.zig");
const p = @import("position.zig");

fn is_legal_move_pawn(game: *g.Game, action: g.MoveInfo) !bool {
    const from = action.from;
    const to = action.to;
    const from_square = try game.board.get_square_at(from);
    if (from_square.piece != Piece.Pawn) {
        return false;
    }

    const to_square = try game.board.get_square_at(to);
    if (!to_square.empty) {
        if (to_square.color == from_square.color) {
            return false;
        }
        const rank_diff = if (from_square.color == Colors.White) to.rank - from.rank else from.rank - to.rank;
        if (rank_diff != 1) {
            return false;
        }
        const file_diff = @abs(@as(i16, @intCast(from.file)) - @as(i16, @intCast(to.file)));
        if (file_diff != 1) {
            return false;
        }
    } else {
        const rank_diff = if (from_square.color == Colors.White) to.rank - from.rank else from.rank - to.rank;
        const legal_rank_diff: u32 = if (from.rank == 1) 2 else 1;
        if (rank_diff > legal_rank_diff or rank_diff < 1) {
            return false;
        }
        const file_diff = @abs(@as(i16, @intCast(to.file)) - @as(i16, @intCast(from.file)));
        if (file_diff != 0) {
            return false;
        }
    }
    return true;
}

fn is_legal_move_knight(game: *g.Game, action: g.MoveInfo) !bool {
    const from = action.from;
    const to = action.to;
    const from_square = try game.board.get_square_at(from);
    if (from_square.piece != Piece.Knight) {
        return false;
    }

    const rank_diff = @abs(@as(i16, @intCast(from.rank)) - @as(i16, @intCast(to.rank)));
    const file_diff = @abs(@as(i16, @intCast(from.file)) - @as(i16, @intCast(to.file)));
    if (rank_diff == 2 and file_diff == 1) {
        return true;
    }
    if (rank_diff == 1 and file_diff == 2) {
        return true;
    }
    return false;
}

fn legal_move_bishop(game: *g.Game, action: g.MoveInfo) !bool {
    const from = action.from;
    const to = action.to;
    const from_square = try game.board.get_square_at(from);
    if (from_square.piece != Piece.Bishop) {
        return false;
    }

    const rank_diff = @abs(@as(i16, @intCast(from.rank)) - @as(i16, @intCast(to.rank)));
    const file_diff = @abs(@as(i16, @intCast(from.file)) - @as(i16, @intCast(to.file)));
    if (rank_diff != file_diff) {
        return false;
    }

    const file_delta: i32 = if (from.file < to.file) 1 else -1;
    const rank_delta: i32 = if (from.rank < to.rank) 1 else -1;

    var i: u8 = 1;
    while (i != rank_diff) : (i += 1) {
        const x = from.file + i * file_delta;
        const y = from.rank + i * rank_delta;
        if (x < 0 or x > 7 or y < 0 or y > 7) {
            return false;
        }
        const square = try game.board.get_square_at(Position{
            .rank = @as(u8, @intCast(y)),
            .file = @as(u8, @intCast(x)),
        });
        if (!square.empty) {
            return false;
        }
    }
    return true;
}

fn legal_move_rook(game: *g.Game, action: g.MoveInfo) !bool {
    const from = action.from;
    const to = action.to;
    const from_square = try game.board.get_square_at(from);
    if (from_square.piece != Piece.Rook) {
        return false;
    }

    const rank_diff = @abs(@as(i16, @intCast(from.rank)) - @as(i16, @intCast(to.rank)));
    const file_diff = @abs(@as(i16, @intCast(from.file)) - @as(i16, @intCast(to.file)));
    if (rank_diff > 0 and file_diff > 0) {
        return false;
    }

    const file_delta: i32 = blk: {
        if (from.file < to.file) {
            break :blk 1;
        } else if (from.file > to.file) {
            break :blk -1;
        } else {
            break :blk 0;
        }
    };
    const rank_delta: i32 = blk: {
        if (from.rank < to.rank) {
            break :blk 1;
        } else if (from.rank > to.rank) {
            break :blk -1;
        } else {
            break :blk 0;
        }
    };

    var i: u8 = 1;
    while (i != @max(rank_diff, file_diff)) : (i += 1) {
        const x = from.file + i * file_delta;
        const y = from.rank + i * rank_delta;
        if (x < 0 or x > 7 or y < 0 or y > 7) {
            return false;
        }
        const square = try game.board.get_square_at(Position{
            .rank = @as(u8, @intCast(y)),
            .file = @as(u8, @intCast(x)),
        });
        if (!square.empty) {
            return false;
        }
    }
    return true;
}

fn legal_move_queen(game: *g.Game, action: g.MoveInfo) !bool {
    const from = action.from;
    const to = action.to;
    const from_square = try game.board.get_square_at(from);
    if (from_square.piece != Piece.Queen) {
        return false;
    }

    const rank_diff = @abs(@as(i16, @intCast(from.rank)) - @as(i16, @intCast(to.rank)));
    const file_diff = @abs(@as(i16, @intCast(from.file)) - @as(i16, @intCast(to.file)));
    const diagonal = rank_diff == file_diff;
    const straight = rank_diff == 0 and file_diff > 0 or rank_diff > 0 and file_diff == 0;
    if (!diagonal and !straight) {
        return false;
    }

    const file_delta: i32 = blk: {
        if (from.file < to.file) {
            break :blk 1;
        } else if (from.file > to.file) {
            break :blk -1;
        } else {
            break :blk 0;
        }
    };
    const rank_delta: i32 = blk: {
        if (from.rank < to.rank) {
            break :blk 1;
        } else if (from.rank > to.rank) {
            break :blk -1;
        } else {
            break :blk 0;
        }
    };

    var i: i32 = 1;
    while (i != @max(rank_diff, file_diff)) : (i += 1) {
        const x = from.file + i * file_delta;
        const y = from.rank + i * rank_delta;
        if (x < 0 or x > 7 or y < 0 or y > 7) {
            return false;
        }
        const square = try game.board.get_square_at(Position{
            .rank = @as(u8, @intCast(y)),
            .file = @as(u8, @intCast(x)),
        });
        if (!square.empty) {
            return false;
        }
    }
    return true;
}

fn legal_move_king(game: *g.Game, action: g.MoveInfo) !bool {
    const from = action.from;
    const to = action.to;
    const from_square = try game.board.get_square_at(from);

    if (from_square.piece != Piece.King) {
        return false;
    }

    const rank_diff = @abs(@as(i16, @intCast(from.rank)) - @as(i16, @intCast(to.rank)));
    const file_diff = @abs(@as(i16, @intCast(from.file)) - @as(i16, @intCast(to.file)));
    if (rank_diff > 1 or file_diff > 1 or (rank_diff == 0 and file_diff == 0)) {
        return false;
    }

    return true;
}

fn legal_move(game: *g.Game, action: g.MoveInfo) !bool {
    const from = action.from;
    if (from.rank < 0 or from.rank > 7 or from.file < 0 or from.file > 7) {
        return false;
    }
    const to = action.to;
    if (to.rank < 0 or to.rank > 7 or to.file < 0 or to.file > 7) {
        return false;
    }
    const from_square = try game.board.get_square_at(from);
    if (from_square.empty) {
        return false;
    }

    if (from_square.color != game.active_color) {
        return false;
    }

    const to_square = try game.board.get_square_at(to);
    if (!to_square.empty and to_square.color == from_square.color) {
        return false;
    }

    switch (from_square.piece) {
        Piece.Pawn => {
            return is_legal_move_pawn(game, action);
        },
        Piece.Knight => {
            return is_legal_move_knight(game, action);
        },
        Piece.Bishop => {
            return legal_move_bishop(game, action);
        },
        Piece.Rook => {
            return legal_move_rook(game, action);
        },
        Piece.Queen => {
            return legal_move_queen(game, action);
        },
        Piece.King => {
            return legal_move_king(game, action);
        },
        Piece.None => {
            return false;
        },
    }
    return false;
}

fn legal_castle(game: *g.Game, action: g.CastleInfo) !bool {
    if (try is_in_check(game, game.active_color)) {
        return false;
    }

    const king_square = if (game.active_color == Colors.White) p.W_K1 else p.B_K1;
    const king = try game.board.get_square_at(king_square);
    if (king.piece != Piece.King) {
        return false;
    }
    if (king.moved) {
        return false;
    }

    const rook_square = if (action.king_side) p.Position{ .rank = king_square.rank, .file = 7 } else p.Position{ .rank = king_square.rank, .file = 0 };
    const rook = try game.board.get_square_at(rook_square);
    if (rook.piece != Piece.Rook) {
        return false;
    }
    if (rook.moved) {
        return false;
    }

    var inbetween_file: i16 = if (action.king_side) king_square.file + 1 else king_square.file - 1;
    const direction: i16 = if (action.king_side) 1 else -1;
    while (inbetween_file != rook_square.file) : (inbetween_file += direction) {
        const square = try game.board.get_square_at(p.Position{
            .rank = king_square.rank,
            .file = @as(u8, @intCast(inbetween_file)),
        });
        if (!square.empty) {
            return false;
        }
    }
    return true;
}

fn legal_en_passant(game: *g.Game, action: g.EnPassantInfo) !bool {
    const from = action.move.from;
    const to = action.move.to;
    const from_square = try game.board.get_square_at(from);
    if (from_square.piece != Piece.Pawn) {
        return false;
    }

    const to_square = try game.board.get_square_at(to);
    if (!to_square.empty) {
        return false;
    }

    const en_passant_pos = action.target;

    // if (game.active_color == Colors.White) {
    //     p.Position{ .rank = to.rank - 1, .file = to.file };
    // } else {
    //     p.Position{ .rank = to.rank + 1, .file = to.file };
    // }

    const en_passant = try game.board.get_square_at(en_passant_pos);
    if (en_passant.piece != Piece.Pawn) {
        return false;
    }
    if (en_passant.color == game.active_color) {
        return false;
    }

    switch (game.last_action) {
        g.Action.Move => {
            const last_move = game.last_action.Move;
            const last_from = last_move.from;
            const last_to = last_move.to;
            const last_to_square = try game.board.get_square_at(last_to);
            if (last_to_square.piece != Piece.Pawn) {
                return false;
            }
            if (game.active_color == Colors.Black) {
                if (last_from.rank != 1 or last_to.rank != 3) {
                    return false;
                }
            } else {
                if (last_from.rank != 6 or last_to.rank != 4) {
                    return false;
                }
            }
            return true;
        },
        else => {
            return false;
        },
    }

    return true;
}

fn legal_promotion(game: *g.Game, action: g.PromotionInfo) !bool {
    // Make sure is pawn
    const from_square = try game.board.get_square_at(action.move.from);
    if (from_square.piece != Piece.Pawn) {
        return false;
    }

    if (!try legal_move(game, action.move)) {
        return false;
    }

    return true;
}

fn is_in_check(game: *g.Game, player: Colors) !bool {
    const king_square = try game.board.get_king_square(player);

    // check if king is in check from pawn:
    const pawn_rank = if (player == Colors.White) king_square.rank + 1 else king_square.rank - 1;
    const pawn_file_diff = [_]i16{ -1, 1 };
    for (pawn_file_diff) |file_diff| {
        const pawn_file = king_square.file + file_diff;
        if (pawn_file < 0 or pawn_file > 7 or pawn_rank < 0 or pawn_rank > 7) {
            continue;
        }
        const pawn_square = try game.board.get_square_at(Position{
            .rank = pawn_rank,
            .file = @as(u8, @intCast(pawn_file)),
        });
        if (pawn_square.piece == Piece.Pawn and pawn_square.color != player) {
            return true;
        }
    }

    // check if king is in check from knight:
    const knight_rank_diff = [_]i16{ -2, -2, 2, 2, 1, 1, -1, -1 };
    const knight_file_diff = [_]i16{ -1, 1, -1, 1, -2, 2, -2, 2 };
    for (knight_rank_diff, 0..) |rank_diff, i| {
        const knight_rank = king_square.rank + rank_diff;
        const knight_file = king_square.file + knight_file_diff[i];
        if (knight_rank < 0 or knight_rank > 7 or knight_file < 0 or knight_file > 7) {
            continue;
        }
        const knight_square = try game.board.get_square_at(Position{
            .rank = @as(u8, @intCast(knight_rank)),
            .file = @as(u8, @intCast(knight_file)),
        });
        if (knight_square.piece == Piece.Knight and knight_square.color != player) {
            return true;
        }
    }

    // check if king is in check from bishop or queen:
    const bishop_rank_diff = [_]i16{ -1, -1, 1, 1 };
    const bishop_file_diff = [_]i16{ -1, 1, -1, 1 };
    for (bishop_rank_diff, 0..) |rank_diff, i| {
        const file_diff = bishop_file_diff[i];
        var j: i16 = 1;
        while (true) {
            const bishop_rank = king_square.rank + j * rank_diff;
            const bishop_file = king_square.file + j * file_diff;
            if (bishop_rank > 7 or bishop_file > 7 or bishop_rank < 0 or bishop_file < 0) {
                break;
            }
            const bishop_square = try game.board.get_square_at(Position{
                .rank = @as(u8, @intCast(bishop_rank)),
                .file = @as(u8, @intCast(bishop_file)),
            });
            if (bishop_square.empty) {
                j += 1;
                continue;
            }
            if (bishop_square.color == player) {
                break;
            }
            if (bishop_square.piece == Piece.Bishop or bishop_square.piece == Piece.Queen) {
                return true;
            }
            if (!bishop_square.empty) {
                break;
            }
            j += 1;
        }
    }

    // check if king is in check from rook or queen:
    const rook_rank_diff = [_]i16{ -1, 1, 0, 0 };
    const rook_file_diff = [_]i16{ 0, 0, -1, 1 };
    for (rook_rank_diff, 0..) |rank_diff, i| {
        const file_diff = rook_file_diff[i];
        var j: i16 = 1;
        while (true) {
            const rook_rank = king_square.rank + j * rank_diff;
            const rook_file = king_square.file + j * file_diff;
            if (rook_rank > 7 or rook_file > 7 or rook_rank < 0 or rook_file < 0) {
                break;
            }
            const rook_square = try game.board.get_square_at(Position{
                .rank = @as(u8, @intCast(rook_rank)),
                .file = @as(u8, @intCast(rook_file)),
            });
            if (rook_square.empty) {
                j += 1;
                continue;
            }
            if (rook_square.color == player) {
                break;
            }
            if (rook_square.piece == Piece.Rook or rook_square.piece == Piece.Queen) {
                return true;
            }
            if (!rook_square.empty) {
                break;
            }
            j += 1;
        }
    }

    // check if king is in check from king:
    const king_rank_diff = [_]i16{ -1, -1, -1, 0, 0, 1, 1, 1 };
    const king_file_diff = [_]i16{ -1, 0, 1, -1, 1, -1, 0, 1 };
    for (king_rank_diff, 0..) |rank_diff, i| {
        const file_diff = king_file_diff[i];
        const king_rank = king_square.rank + rank_diff;
        const king_file = king_square.file + file_diff;
        if (king_rank > 7 or king_file > 7 or king_rank < 0 or king_file < 0) {
            continue;
        }
        const maybe_king_square = try game.board.get_square_at(Position{
            .rank = @as(u8, @intCast(king_rank)),
            .file = @as(u8, @intCast(king_file)),
        });
        if (maybe_king_square.piece == Piece.King and maybe_king_square.color != player) {
            return true;
        }
    }

    return false;
}

fn _legal_action(game: *g.Game, action: g.Action) !bool {
    return switch (action) {
        g.Action.Move => try legal_move(game, action.Move),
        g.Action.Castle => try legal_castle(game, action.Castle),
        g.Action.EnPassant => try legal_en_passant(game, action.EnPassant),
        g.Action.Promotion => try legal_promotion(game, action.Promotion),
        g.Action.Resign => true,
        g.Action.Start => false,
    };
}

pub fn legal_action(game: *g.Game, action: g.Action) !bool {
    const legal = try _legal_action(game, action);

    if (!legal) {
        return false;
    }
    const revert_action = game.apply_action(action);
    defer game.undo_action(revert_action);

    const color = game.active_color.flip();

    return !try is_in_check(game, color);
}

fn test_legal_action(board_setup: *const [71:0]u8, board_target: *const [71:0]u8, action: g.Action) !void {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();

    try game.board.set_up_from_string(board_setup);
    try testing.expect(try _legal_action(&game, action));
    _ = game.apply_action(action);

    var actual_board_final = [_]u8{0} ** 78;
    _ = try std.fmt.bufPrint(&actual_board_final, "{s}", .{game.board});

    // std.debug.print("\n{s}\n", .{actual_board_final});

    for (board_target, 0..) |expected, i| {
        try testing.expect(expected == actual_board_final[i]);
    }
}

fn test_legal_action_black(board_setup: *const [71:0]u8, board_target: *const [71:0]u8, action: g.Action) !void {
    const allocator = std.testing.allocator;

    var game = g.Game{ .allocator = allocator, .active_color = Colors.Black };
    game.set_up();

    try game.board.set_up_from_string(board_setup);
    try testing.expect(try _legal_action(&game, action));
    _ = game.apply_action(action);

    var actual_board_final = [_]u8{0} ** 78;
    _ = try std.fmt.bufPrint(&actual_board_final, "{s}", .{game.board});

    // std.debug.print("\n{s}\n", .{actual_board_final});

    for (board_target, 0..) |expected, i| {
        try testing.expect(expected == actual_board_final[i]);
    }
}

fn test_not_legal_move(board_setup: *const [71:0]u8, action: g.Action) !void {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();

    try game.board.set_up_from_string(board_setup);

    const legal = try _legal_action(&game, action);
    try testing.expect(!legal);
}

test "legal move pawn" {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();

    const board_setup =
        \\.......K
        \\.....P..
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;
    const board_target =
        \\.......K
        \\........
        \\.....P..
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;
    const move = g.MoveInfo{
        .from = Position{
            .file = 5,
            .rank = 1,
        },
        .to = Position{
            .file = 5,
            .rank = 2,
        },
    };

    const action = g.Action{ .Move = move };
    try test_legal_action(board_setup, board_target, action);
}

test "legal move pawn capture" {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();

    const board_setup =
        \\.......K
        \\........
        \\........
        \\...P....
        \\..p.....
        \\........
        \\........
        \\.......k
    ;
    const board_target =
        \\.......K
        \\........
        \\........
        \\........
        \\..P.....
        \\........
        \\........
        \\.......k
    ;
    const move = g.MoveInfo{
        .from = Position{
            .file = 3,
            .rank = 3,
        },
        .to = Position{
            .file = 2,
            .rank = 4,
        },
    };

    const action = g.Action{ .Move = move };
    try test_legal_action(board_setup, board_target, action);
}

test "not legal move pawn" {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();

    const board_setup =
        \\P......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;
    const move = g.MoveInfo{
        .from = Position{
            .file = 0,
            .rank = 0,
        },
        .to = Position{
            .file = 3,
            .rank = 3,
        },
    };
    const action = g.Action{ .Move = move };
    try test_not_legal_move(board_setup, action);
}

test "legal move knight" {
    const board_setup =
        \\N......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;
    const board_target =
        \\.......K
        \\..N.....
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;

    const move = g.MoveInfo{
        .from = Position{
            .file = 0,
            .rank = 0,
        },
        .to = Position{
            .file = 2,
            .rank = 1,
        },
    };

    const action = g.Action{ .Move = move };
    try test_legal_action(board_setup, board_target, action);
}

test "legal move knight capture" {
    const board_setup =
        \\N......K
        \\..p.....
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;
    const board_target =
        \\.......K
        \\..N.....
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;

    const move = g.MoveInfo{
        .from = Position{
            .file = 0,
            .rank = 0,
        },
        .to = Position{
            .file = 2,
            .rank = 1,
        },
    };

    const action = g.Action{ .Move = move };
    try test_legal_action(board_setup, board_target, action);
}

test "not legal move knight" {
    const board_setup =
        \\N......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;

    const move = g.MoveInfo{
        .from = Position{
            .file = 0,
            .rank = 0,
        },
        .to = Position{
            .file = 2,
            .rank = 2,
        },
    };

    const action = g.Action{ .Move = move };
    try test_not_legal_move(board_setup, action);
}

test "legal move bishop" {
    const board_setup =
        \\B......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\k.......
    ;
    const board_target =
        \\.......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\k......B
    ;

    const move = g.MoveInfo{
        .from = Position{
            .file = 0,
            .rank = 0,
        },
        .to = Position{
            .file = 7,
            .rank = 7,
        },
    };

    const action = g.Action{ .Move = move };
    try test_legal_action(board_setup, board_target, action);
}

test "not legal move bishop" {
    const board_setup =
        \\B......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\k.......
    ;

    const move = g.MoveInfo{
        .from = Position{
            .file = 0,
            .rank = 0,
        },
        .to = Position{
            .file = 7,
            .rank = 6,
        },
    };

    const action = g.Action{ .Move = move };
    try test_not_legal_move(board_setup, action);
}

test "legal move rook down" {
    const board_setup =
        \\R......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;
    const board_target =
        \\.......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\R......k
    ;

    const move = g.MoveInfo{
        .from = Position{
            .file = 0,
            .rank = 0,
        },
        .to = Position{
            .file = 0,
            .rank = 7,
        },
    };

    const action = g.Action{ .Move = move };
    try test_legal_action(board_setup, board_target, action);
}

test "legal move rook up" {
    const board_setup =
        \\.......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
        \\R.......
    ;
    const board_target =
        \\R......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
        \\........
    ;

    const move = g.MoveInfo{
        .from = Position{
            .file = 0,
            .rank = 7,
        },
        .to = Position{
            .file = 0,
            .rank = 0,
        },
    };

    const action = g.Action{ .Move = move };
    try test_legal_action(board_setup, board_target, action);
}

test "not legal move rook" {
    const board_setup =
        \\R......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;

    const move = g.MoveInfo{
        .from = Position{
            .file = 0,
            .rank = 0,
        },
        .to = Position{
            .file = 1,
            .rank = 7,
        },
    };

    const action = g.Action{ .Move = move };
    try test_not_legal_move(board_setup, action);
}

test "legal move queen diagonal" {
    const board_setup =
        \\Q......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.k......
    ;
    const board_target =
        \\.......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.k.....Q
    ;

    const move = g.MoveInfo{
        .from = Position{
            .file = 0,
            .rank = 0,
        },
        .to = Position{
            .file = 7,
            .rank = 7,
        },
    };

    const action = g.Action{ .Move = move };
    try test_legal_action(board_setup, board_target, action);
}

test "legal move queen vertical" {
    const board_setup =
        \\Q......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.k......
    ;
    const board_target =
        \\.......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\Qk......
    ;

    const move = g.MoveInfo{
        .from = Position{
            .file = 0,
            .rank = 0,
        },
        .to = Position{
            .file = 0,
            .rank = 7,
        },
    };

    const action = g.Action{ .Move = move };
    try test_legal_action(board_setup, board_target, action);
}

test "not legal move queen" {
    const board_setup =
        \\R......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.k......
    ;

    const move = g.MoveInfo{
        .from = Position{
            .file = 0,
            .rank = 0,
        },
        .to = Position{
            .file = 1,
            .rank = 2,
        },
    };

    const action = g.Action{ .Move = move };
    try test_not_legal_move(board_setup, action);
}

test "legal move king" {
    const board_setup =
        \\.......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\k.......
    ;
    const board_target =
        \\........
        \\......K.
        \\........
        \\........
        \\........
        \\........
        \\........
        \\k.......
    ;

    const move = g.MoveInfo{
        .from = Position{
            .file = 7,
            .rank = 0,
        },
        .to = Position{
            .file = 6,
            .rank = 1,
        },
    };

    const action = g.Action{ .Move = move };
    try test_legal_action(board_setup, board_target, action);
}

test "not legal move king" {
    const board_setup =
        \\K.......
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\k.......
    ;

    const move = g.MoveInfo{
        .from = Position{
            .file = 0,
            .rank = 0,
        },
        .to = Position{
            .file = 1,
            .rank = 2,
        },
    };

    const action = g.Action{ .Move = move };
    try test_not_legal_move(board_setup, action);
}

test "legal castle queen side white" {
    const board_setup =
        \\R...K...
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;
    const board_target =
        \\.K.R....
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;

    const castle = g.CastleInfo{
        .king_side = false,
        .color = Colors.White,
    };

    const action = g.Action{ .Castle = castle };
    try test_legal_action(board_setup, board_target, action);
}

test "legal castle king side white" {
    const board_setup =
        \\....K..R
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\....k...
    ;
    const board_target =
        \\.....RK.
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\....k...
    ;

    const castle = g.CastleInfo{
        .king_side = true,
        .color = Colors.White,
    };

    const action = g.Action{ .Castle = castle };
    try test_legal_action(board_setup, board_target, action);
}

test "legal castle queen side black" {
    const board_setup =
        \\.......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\r...k...
    ;
    const board_target =
        \\.......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.k.r....
    ;

    const castle = g.CastleInfo{
        .king_side = false,
        .color = Colors.Black,
    };

    const action = g.Action{ .Castle = castle };
    try test_legal_action_black(board_setup, board_target, action);
}

test "legal castle king side black" {
    const board_setup =
        \\....K...
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\....k..r
    ;
    const board_target =
        \\....K...
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.....rk.
    ;

    const castle = g.CastleInfo{
        .king_side = true,
        .color = Colors.Black,
    };

    const action = g.Action{ .Castle = castle };
    try test_legal_action_black(board_setup, board_target, action);
}

test "not legal castle king side white bishop in the way" {
    const board_setup =
        \\R.B.K...
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;

    const castle = g.CastleInfo{
        .king_side = false,
        .color = Colors.White,
    };

    const action = g.Action{ .Castle = castle };
    try test_not_legal_move(board_setup, action);
}

test "not legal castle king moved" {
    const board_setup =
        \\R...K...
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;

    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();

    try game.board.set_up_from_string(board_setup);

    // move white king
    const move_white_king = g.MoveInfo{
        .from = Position{
            .file = 4,
            .rank = 0,
        },
        .to = Position{
            .file = 4,
            .rank = 1,
        },
    };
    const move_action = g.Action{ .Move = move_white_king };
    _ = game.apply_action(move_action);

    // move black king
    const move_black_king = g.MoveInfo{
        .from = Position{
            .file = 4,
            .rank = 7,
        },
        .to = Position{
            .file = 4,
            .rank = 6,
        },
    };
    const move_action_black = g.Action{ .Move = move_black_king };
    _ = game.apply_action(move_action_black);

    // move white king back
    const move_white_king_back = g.MoveInfo{
        .from = Position{
            .file = 4,
            .rank = 1,
        },
        .to = Position{
            .file = 4,
            .rank = 0,
        },
    };
    const move_action_white_back = g.Action{ .Move = move_white_king_back };
    _ = game.apply_action(move_action_white_back);

    // move black king back
    const move_black_king_back = g.MoveInfo{
        .from = Position{
            .file = 4,
            .rank = 6,
        },
        .to = Position{
            .file = 4,
            .rank = 7,
        },
    };

    const move_action_black_back = g.Action{ .Move = move_black_king_back };
    _ = game.apply_action(move_action_black_back);

    // try castle

    const castle = g.CastleInfo{
        .king_side = false,
        .color = Colors.White,
    };

    const action = g.Action{ .Castle = castle };

    const legal = try _legal_action(&game, action);
    try testing.expect(!legal);
}

test "legal en passant" {
    const board_setup =
        \\....K...
        \\.P......
        \\........
        \\..p.....
        \\........
        \\........
        \\........
        \\.......k
    ;

    const board_target =
        \\....K...
        \\........
        \\.p......
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;

    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();

    try game.board.set_up_from_string(board_setup);

    // move white pawn
    const move_white_pawn = g.MoveInfo{
        .from = Position{
            .file = 1,
            .rank = 1,
        },
        .to = Position{
            .file = 1,
            .rank = 3,
        },
    };
    const move_white_pawn_action = g.Action{ .Move = move_white_pawn };
    _ = game.apply_action(move_white_pawn_action);

    // black pawn en passant
    const en_passant = g.EnPassantInfo{
        .move = g.MoveInfo{
            .from = Position{
                .file = 2,
                .rank = 3,
            },
            .to = Position{
                .file = 1,
                .rank = 2,
            },
        },
        .target = Position{
            .file = 1,
            .rank = 3,
        },
    };

    const en_passant_action = g.Action{ .EnPassant = en_passant };

    try testing.expect(try _legal_action(&game, en_passant_action));

    _ = game.apply_action(en_passant_action);

    var actual_board_final = [_]u8{0} ** 78;
    _ = try std.fmt.bufPrint(&actual_board_final, "{s}", .{game.board});

    for (board_target, 0..) |expected, i| {
        try testing.expect(expected == actual_board_final[i]);
    }
}

test "not legal en passant" {
    const board_setup =
        \\....K...
        \\.P.....P
        \\........
        \\..p.....
        \\........
        \\........
        \\........
        \\.......k
    ;

    const board_target =
        \\....K...
        \\........
        \\.p......
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;
    _ = board_target;

    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();

    try game.board.set_up_from_string(board_setup);

    // move white pawn
    const move_white_pawn = g.MoveInfo{
        .from = Position{
            .file = 1,
            .rank = 1,
        },
        .to = Position{
            .file = 1,
            .rank = 3,
        },
    };
    const move_white_pawn_action = g.Action{ .Move = move_white_pawn };
    _ = game.apply_action(move_white_pawn_action);

    // move black king
    const move_black_king = g.MoveInfo{
        .from = Position{
            .file = 4,
            .rank = 7,
        },
        .to = Position{
            .file = 4,
            .rank = 6,
        },
    };
    const move_action_black_king = g.Action{ .Move = move_black_king };
    _ = game.apply_action(move_action_black_king);

    // move other white pawn
    const move_white_pawn_other = g.MoveInfo{
        .from = Position{
            .file = 6,
            .rank = 1,
        },
        .to = Position{
            .file = 6,
            .rank = 3,
        },
    };
    const move_white_pawn_action_other = g.Action{ .Move = move_white_pawn_other };
    _ = game.apply_action(move_white_pawn_action_other);

    // black pawn en passant
    const en_passant = g.EnPassantInfo{
        .move = g.MoveInfo{
            .from = Position{
                .file = 2,
                .rank = 3,
            },
            .to = Position{
                .file = 1,
                .rank = 2,
            },
        },
        .target = Position{
            .file = 1,
            .rank = 3,
        },
    };

    const en_passant_action = g.Action{ .EnPassant = en_passant };

    try testing.expect(!try _legal_action(&game, en_passant_action));
}

test "legal promotion" {
    const board_setup =
        \\.......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\P.......
        \\.......k
    ;
    const board_target =
        \\.......K
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\Q......k
    ;

    const promotion = g.PromotionInfo{
        .move = g.MoveInfo{
            .from = Position{
                .file = 0,
                .rank = 6,
            },
            .to = Position{
                .file = 0,
                .rank = 7,
            },
        },
        .piece = Piece.Queen,
    };

    const action = g.Action{ .Promotion = promotion };
    try test_legal_action(board_setup, board_target, action);
}

fn check_test_helper(board_setup: *const [71:0]u8, color: Colors, is_checked: bool) !void {
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();

    try game.board.set_up_from_string(board_setup);
    try testing.expect(is_checked == try is_in_check(&game, color));
}

test "is not in check" {
    try check_test_helper(
        \\K.......
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ,
        Colors.White,
        false,
    );

    try check_test_helper(
        \\K.......
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ,
        Colors.Black,
        false,
    );
}

test "is in pawn check" {
    try check_test_helper(
        \\K.......
        \\.p......
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ,
        Colors.White,
        true,
    );

    try check_test_helper(
        \\K.......
        \\........
        \\........
        \\........
        \\........
        \\........
        \\......P.
        \\.......k
    ,
        Colors.Black,
        true,
    );
}

test "is in knight check" {
    try check_test_helper(
        \\K.......
        \\........
        \\.n......
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ,
        Colors.White,
        true,
    );

    try check_test_helper(
        \\K.......
        \\........
        \\........
        \\........
        \\........
        \\......N.
        \\........
        \\.......k
    ,
        Colors.Black,
        true,
    );
}

test "is in bishop check" {
    try check_test_helper(
        \\K.......
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\k......b
    ,
        Colors.White,
        true,
    );

    try check_test_helper(
        \\K......B
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\k.......
    ,
        Colors.Black,
        true,
    );
}

test "is in rook check" {
    try check_test_helper(
        \\K......r
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ,
        Colors.White,
        true,
    );

    try check_test_helper(
        \\K......R
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ,
        Colors.Black,
        true,
    );
}
test "is in queen check" {
    try check_test_helper(
        \\K......q
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ,
        Colors.White,
        true,
    );

    try check_test_helper(
        \\K......Q
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ,
        Colors.Black,
        true,
    );
}

test "king move self mate illegal" {
    const board_setup =
        \\....K...
        \\........
        \\...p....
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;

    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();

    try game.board.set_up_from_string(board_setup);

    const move = g.MoveInfo{
        .from = Position{
            .file = 4,
            .rank = 0,
        },
        .to = Position{
            .file = 4,
            .rank = 1,
        },
    };

    const action = g.Action{ .Move = move };

    try testing.expect(!try legal_action(&game, action));
}

test "pawn move self mate illegal" {
    const board_setup =
        \\....KP.r
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.......k
    ;

    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();

    try game.board.set_up_from_string(board_setup);

    const move = g.MoveInfo{
        .from = Position{
            .file = 5,
            .rank = 0,
        },
        .to = Position{
            .file = 5,
            .rank = 1,
        },
    };

    const action = g.Action{ .Move = move };

    try testing.expect(!try legal_action(&game, action));
}

test "castle self mate illegal" {
    const board_setup =
        \\R...K...
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.r.....k
    ;
    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();

    try game.board.set_up_from_string(board_setup);

    const castle = g.CastleInfo{
        .king_side = false,
        .color = Colors.White,
    };

    const action = g.Action{ .Castle = castle };

    try testing.expect(!try legal_action(&game, action));
}

test "cant move pawn if in check" {
    const board_setup =
        \\....KP..
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\....r..k
    ;

    const allocator = std.heap.page_allocator;
    var game = g.Game{ .allocator = allocator };
    game.set_up();

    try game.board.set_up_from_string(board_setup);

    const move = g.MoveInfo{
        .from = Position{
            .file = 5,
            .rank = 0,
        },
        .to = Position{
            .file = 5,
            .rank = 1,
        },
    };

    const action = g.Action{ .Move = move };

    try testing.expect(!try legal_action(&game, action));
}
