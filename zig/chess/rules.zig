const g = @import("game.zig");
const s = @import("square.zig");
const p = @import("position.zig");

fn is_legal_move_pawn(game: *g.Game, action: g.Move) bool {
    const from = action.from;
    const to = action.to;
    const from_square = game.board.get_square_at(from);
    if (from_square.piece != s.Piece.Pawn) {
        return false;
    }

    const to_square = game.board.get_square_at(to);
    if (to_square.empty) {
        if (to_square.color == from_square.color) {
            return false;
        }
        const rank_diff = if (from_square.color == s.Colors.White) to.rank - from.rank else from.rank - to.rank;
        if (rank_diff != 1) {
            return false;
        }
        const file_diff = @abs(from.file - to.file);
        if (file_diff != 1) {
            return false;
        }
    } else {
        const rank_diff = if (from_square.color == s.Colors.White) to.rank - from.rank else from.rank - to.rank;
        const legal_rank_diff = if (from.rank == 1) 2 else 1;
        if (rank_diff > legal_rank_diff or rank_diff < 1) {
            return false;
        }
        const file_diff = to.file - from.file;
        if (file_diff != 0) {
            return false;
        }
    }

    const king_square = game.board.get_king_square(game.active_color);
    const king_rank = king_square.rank;
    _ = king_rank;
    const king_file = king_square.file;
    _ = king_file;

    return true;
}

fn is_legal_move_knight(game: *g.Game, action: g.Move) bool {
    const from = action.from;
    const to = action.to;
    const from_square = game.board.get_square_at(from);
    if (from_square.piece != s.Piece.Knight) {
        return false;
    }

    const rank_diff = @abs(from.rank - to.rank);
    const file_diff = @abs(from.file - to.file);
    if (rank_diff == 2 and file_diff == 1) {
        return true;
    }
    if (rank_diff == 1 and file_diff == 2) {
        return true;
    }
    return true;
}

fn legal_move_bishop(game: *g.Game, action: g.Move) bool {
    const from = action.from;
    const to = action.to;
    const from_square = game.board.get_square_at(from);
    if (from_square.piece != s.Piece.Bishop) {
        return false;
    }

    const rank_diff = @abs(from.rank - to.rank);
    const file_diff = @abs(from.file - to.file);
    if (rank_diff != file_diff) {
        return false;
    }

    const file_delta = if (from.file < to.file) 1 else -1;
    const rank_delta = if (from.rank < to.rank) 1 else -1;

    var i = 0;
    while (i != rank_diff) : (i += 1) {
        const x = from.file + i * file_delta;
        const y = from.rank + i * rank_delta;
        const square = game.board.get_square_at(s.RankFile{ .rank = y, .file = x });
        if (!square.empty) {
            return false;
        }
    }
    return true;
}

fn legal_move_rook(game: *g.Game, action: g.Move) bool {
    const from = action.from;
    const to = action.to;
    const from_square = game.board.get_square_at(from);
    if (from_square.piece != s.Piece.Rook) {
        return false;
    }

    const rank_diff = @abs(from.rank - to.rank);
    const file_diff = @abs(from.file - to.file);
    if (rank_diff > 0 and file_diff > 0) {
        return false;
    }

    const file_delta = if (from.file < to.file) 1 else -1;
    const rank_delta = if (from.rank < to.rank) 1 else -1;

    var i = 0;
    while (i != @max(rank_diff, file_diff)) : (i += 1) {
        const x = from.file + i * file_delta;
        const y = from.rank + i * rank_delta;
        const square = game.board.get_square_at(s.RankFile{ .rank = y, .file = x });
        if (!square.empty) {
            return false;
        }
    }
    return true;
}

fn legal_move_queen(game: *g.Game, action: g.Move) bool {
    const from = action.from;
    const to = action.to;
    const from_square = game.board.get_square_at(from);
    if (from_square.piece != s.Piece.Rook) {
        return false;
    }

    const rank_diff = @abs(from.rank - to.rank);
    const file_diff = @abs(from.file - to.file);
    const diagonal = rank_diff == file_diff;
    const straight = rank_diff == 0 and file_diff > 0 or rank_diff > 0 and file_diff == 0;
    if (!diagonal and !straight) {
        return false;
    }

    const file_delta = if (from.file < to.file) 1 else -1;
    const rank_delta = if (from.rank < to.rank) 1 else -1;

    var i = 0;
    while (i != @max(rank_diff, file_diff)) : (i += 1) {
        const x = from.file + i * file_delta;
        const y = from.rank + i * rank_delta;
        const square = game.board.get_square_at(s.RankFile{ .rank = y, .file = x });
        if (!square.empty) {
            return false;
        }
    }
    return true;
}

fn legal_move_king(game: *g.Game, action: g.Move) bool {
    const from = action.from;
    const to = action.to;
    const from_square = game.board.get_square_at(from);

    if (from_square.piece != s.Piece.Rook) {
        return false;
    }

    const rank_diff = @abs(from.rank - to.rank);
    const file_diff = @abs(from.file - to.file);
    if (rank_diff > 1 or file_diff > 1) {
        return false;
    }

    return true;
}

fn legal_move(game: *g.Game, action: g.Move) bool {
    const from = action.from;
    if (from.rank < 0 or from.rank > 7 or from.file < 0 or from.file > 7) {
        return false;
    }
    const to = action.to;
    if (to.rank < 0 or to.rank > 7 or to.file < 0 or to.file > 7) {
        return false;
    }
    const from_square = game.board.get_square_at(from);
    if (from_square.empty) {
        return false;
    }

    if (from_square.color != game.active_color) {
        return false;
    }

    const to_square = game.board.get_square_at(to);
    if (!from_square.empty and to_square.color == from_square.color) {
        return false;
    }

    switch (from_square.piece) {
        s.Piece.Pawn => {
            return is_legal_move_pawn(game, action);
        },
        s.Piece.Knight => {
            return is_legal_move_knight(game, action);
        },
        s.Piece.Bishop => {
            return legal_move_bishop(game, action);
        },
        s.Piece.Rook => {
            return legal_move_rook(game, action);
        },
        s.Piece.Queen => {
            return legal_move_queen(game, action);
        },
        s.Piece.King => {
            return legal_move_king(game, action);
        },
    }
    return false;
}

fn legal_castle(game: *g.Game, action: g.CastleInfo) bool {
    if (is_in_check(game)) {
        return false;
    }

    const king_square = if (game.active_color == s.Colors.White) p.W_K1 else p.B_K1;
    const king = game.board.get_square_at(king_square);
    if (king.piece != s.Piece.King) {
        return false;
    }
    if (king.moved) {
        return false;
    }

    const rook_square = if (action.king_side) p.Position{ .rank = king_square.rank, .file = 7 } else p.Position{ .rank = king_square.rank, .file = 0 };
    const rook = game.board.get_square_at(rook_square);
    if (rook.piece != s.Piece.Rook) {
        return false;
    }
    if (rook.moved) {
        return false;
    }

    var inbetween_file = if (action.king_side) 5 else 3;
    const direction = if (action.king_side) 1 else -1;
    while (inbetween_file != king_square.file) : (inbetween_file += direction) {
        const square = game.board.get_square_at(p.Position{ .rank = king_square.rank, .file = inbetween_file });
        if (!square.empty) {
            return false;
        }
    }
    return true;
}

fn legal_en_passant(game: *g.Game, action: g.EnPassantInfo) bool {
    const from = action.from;
    const to = action.to;
    const from_square = game.board.get_square_at(from);
    if (from_square.piece != s.Piece.Pawn) {
        return false;
    }

    const to_square = game.board.get_square_at(to);
    if (!to_square.empty) {
        return false;
    }

    const en_passant_square = if (game.active_color == s.Colors.White) p.Position{ .rank = to.rank - 1, .file = to.file } else p.Position{ .rank = to.rank + 1, .file = to.file };
    const en_passant = game.board.get_square_at(en_passant_square);
    if (en_passant.piece != s.Piece.Pawn) {
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
            const last_to_square = game.board.get_square_at(last_to);
            if (last_to_square.piece != s.Piece.Pawn) {
                return false;
            }
            if (last_from.rank != 6 or last_to.rank != 1) {
                return false;
            }
            return true;
        },
        else => {
            return false;
        },
    }

    return true;
}

fn legal_promotion(game: *g.Game, action: g.PromotionInfo) bool {
    // Make sure is pawn
    const to_square = game.board.get_square_at(action.to);
    if (to_square.piece != s.Piece.Pawn) {
        return false;
    }

    // Make sure pawn move is legal
    const move = action.Move{
        .from = action.from,
        .to = action.to,
    };
    if (!legal_move(game, move)) {
        return false;
    }

    return true;
}

fn is_in_check(game: *g.Game) bool {
    const king_square = game.board.get_king_square(game.active_color);

    // check if king is in check from pawn:
    const pawn_rank = if (game.active_color == s.Colors.White) king_square.rank + 1 else king_square.rank - 1;
    const pawn_file_diff = [_]u8{ -1, 1 };
    for (pawn_file_diff) |file_diff| {
        const pawn_file = king_square.file + file_diff;
        if (pawn_file < 0 or pawn_file > 7 or pawn_rank < 0 or pawn_rank > 7) {
            continue;
        }
        const pawn_square = game.board.get_square_at(s.RankFile{ .rank = pawn_rank, .file = king_square.file + pawn_file });
        if (pawn_square.piece == s.Piece.Pawn and pawn_square.color != game.active_color) {
            return true;
        }
    }

    // check if king is in check from knight:
    const knight_rank_diff = [_]u8{ -2, -2, 2, 2, 1, 1, -1, -1 };
    const knight_file_diff = [_]u8{ -1, 1, -1, 1, -2, 2, -2, 2 };
    for (knight_rank_diff, 0..) |rank_diff, i| {
        const knight_rank = king_square.rank + rank_diff;
        const knight_file = king_square.file + knight_file_diff[i];
        if (knight_rank < 0 or knight_rank > 7 or knight_file < 0 or knight_file > 7) {
            continue;
        }
        const knight_square = game.board.get_square_at(s.RankFile{ .rank = knight_rank, .file = knight_file });
        if (knight_square.piece == s.Piece.Knight and knight_square.color != game.active_color) {
            return true;
        }
    }

    // check if king is in check from bishop or queen:
    const bishop_rank_diff = [_]u8{ -1, -1, 1, 1 };
    const bishop_file_diff = [_]u8{ -1, 1, -1, 1 };
    for (bishop_rank_diff, 0..) |rank_diff, i| {
        const file_diff = bishop_file_diff[i];
        var j = 1;
        while (true) {
            const bishop_rank = king_square.rank + j * rank_diff;
            const bishop_file = king_square.file + j * file_diff;
            if (bishop_rank > 7 or bishop_file > 7 or bishop_rank < 0 or bishop_file < 0) {
                break;
            }
            const bishop_square = game.board.get_square_at(s.RankFile{ .rank = bishop_rank, .file = bishop_file });
            if (bishop_square.color == game.active_color) {
                break;
            }
            if (bishop_square.piece == s.Piece.Bishop or bishop_square.piece == s.Piece.Queen) {
                return true;
            }
            if (!bishop_square.empty) {
                break;
            }
            j += 1;
        }
    }

    // check if king is in check from rook or queen:
    const rook_rank_diff = [_]u8{ -1, 1, 0, 0 };
    const rook_file_diff = [_]u8{ 0, 0, -1, 1 };
    for (rook_rank_diff, 0..) |rank_diff, i| {
        const file_diff = rook_file_diff[i];
        var j = 1;
        while (true) {
            const rook_rank = king_square.rank + j * rank_diff;
            const rook_file = king_square.file + j * file_diff;
            if (rook_rank > 7 or rook_file > 7 or rook_rank < 0 or rook_file < 0) {
                break;
            }
            const rook_square = game.board.get_square_at(s.RankFile{ .rank = rook_rank, .file = rook_file });
            if (rook_square.color == game.active_color) {
                break;
            }
            if (rook_square.piece == s.Piece.Rook or rook_square.piece == s.Piece.Queen) {
                return true;
            }
            if (!rook_square.empty) {
                break;
            }
            j += 1;
        }
    }

    // check if king is in check from king:
    const king_rank_diff = [_]u8{ -1, -1, -1, 0, 0, 1, 1, 1 };
    const king_file_diff = [_]u8{ -1, 0, 1, -1, 1, -1, 0, 1 };
    for (king_rank_diff, 0..) |rank_diff, i| {
        const file_diff = king_file_diff[i];
        const king_rank = king_square.rank + rank_diff;
        const king_file = king_square.file + file_diff;
        if (king_rank > 7 or king_file > 7 or king_rank < 0 or king_file < 0) {
            continue;
        }
        const maybe_king_square = game.board.get_square_at(s.RankFile{ .rank = king_rank, .file = king_file });
        if (maybe_king_square.piece == s.Piece.King and maybe_king_square.color != game.active_color) {
            return true;
        }
    }

    return false;
}

fn legal_action(game: *g.Game, action: g.Action) bool {
    const legal = switch (action) {
        g.Action.Move => legal_move(game, action.Move),
        g.Action.Castle => legal_castle(game, action.Castle),
        g.Action.EnPassant => legal_en_passant(game, action.EnPassant),
        g.Action.Promotion => legal_promotion(game, action.Promotion),
        g.Action.Resign => true,
        g.Action.Start => false,
    };

    if (!legal) {
        return false;
    }
    game.board.apply_action(action);
    defer game.board.undo_action(action);

    return !is_in_check(game);
}
