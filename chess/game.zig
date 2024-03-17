const std = @import("std");
const testing = std.testing;

const po = @import("position.zig");
const Board = @import("board.zig").Board;
const Piece = @import("pieces.zig").Piece;
const Colors = @import("colors.zig").Colors;
const SquareData = @import("square.zig").SquareData;
const Position = @import("position.zig").Position;
const ActionList = @import("actions.zig").ActionList;

const a = @import("actions.zig");
const r = @import("rules.zig");

pub const MoveInfo = struct {
    from: Position,
    to: Position,
};

pub const Actions = enum {
    Start,
    Move,
    Castle,
    EnPassant,
    Promotion,
    Resign,
};

pub const CastleInfo = struct {
    color: Colors,
    king_side: bool,
};

pub const EnPassantInfo = struct {
    target: Position,
    move: MoveInfo,
};

pub const PromotionInfo = struct {
    piece: Piece,
    move: MoveInfo,
};

pub const Action = union(Actions) {
    Start: void,
    Move: MoveInfo,
    Castle: CastleInfo,
    EnPassant: EnPassantInfo,
    Promotion: PromotionInfo,
    Resign: void,
};

pub const RevertMoveInfo = struct {
    to_state: SquareData,
    from_state: SquareData,
    action: MoveInfo,
};

pub const RevertCastleInfo = struct {
    action: CastleInfo,
};

pub const RevertEnPassantInfo = struct {
    target_state: SquareData,
    from_state: SquareData,
    action: EnPassantInfo,
};

pub const RevertPromotionInfo = struct {
    to_state: SquareData,
    from_state: SquareData,
    action: PromotionInfo,
};

pub const RevertAction = union(Actions) {
    Start: void,
    Move: RevertMoveInfo,
    Castle: RevertCastleInfo,
    EnPassant: RevertEnPassantInfo,
    Promotion: RevertPromotionInfo,
    Resign: void,
};

const Pieces = struct {
    Pawn: u32 = 0,
    Knight: u32 = 0,
    Bishop: u32 = 0,
    Rook: u32 = 0,
    Queen: u32 = 0,
    King: u32 = 0,
};

const GameStates = enum {
    Start,
    InProgress,
    Remis,
    Checkmate,
    Resign,
};

pub const GameState = union(GameStates) {
    Start: void,
    InProgress: RevertAction,
    Remis: RevertAction,
    Checkmate: RevertAction,
    Resign: RevertAction,

    pub fn revert_action(self: GameState) RevertAction {
        return switch (self) {
            GameState.Start => RevertAction{ .Start = {} },
            GameState.InProgress => self.InProgress,
            GameState.Remis => self.Remis,
            GameState.Checkmate => self.Checkmate,
            GameState.Resign => self.Resign,
        };
    }
};

pub const Game = struct {
    board: Board = Board{},
    active_color: Colors = Colors.White,
    last_action: Action = Action.Start,
    allocator: std.mem.Allocator,

    pub fn set_up(game: *Game) void {
        game.board.set_up();
    }

    pub fn flip_player(game: *Game) void {
        game.active_color = if (game.active_color == Colors.White) Colors.Black else Colors.White;
    }

    pub fn is_remis(game: *Game) !bool {
        var black_pieces = Pieces{};
        var white_pieces = Pieces{};

        var file: u8 = 0;
        while (file < 8) : (file += 1) {
            var rank: u8 = 0;
            while (rank < 8) : (rank += 1) {
                const pos = Position{
                    .file = file,
                    .rank = rank,
                };
                const square = try game.board.get_square_at(pos);
                if (square.empty) {
                    continue;
                }
                if (square.color == Colors.Black) {
                    switch (square.piece) {
                        Piece.Pawn => black_pieces.Pawn += 1,
                        Piece.Knight => black_pieces.Knight += 1,
                        Piece.Bishop => black_pieces.Bishop += 1,
                        Piece.Rook => black_pieces.Rook += 1,
                        Piece.Queen => black_pieces.Queen += 1,
                        Piece.King => black_pieces.King += 1,
                        else => {},
                    }
                } else if (square.color == Colors.White) {
                    switch (square.piece) {
                        Piece.Pawn => white_pieces.Pawn += 1,
                        Piece.Knight => white_pieces.Knight += 1,
                        Piece.Bishop => white_pieces.Bishop += 1,
                        Piece.Rook => white_pieces.Rook += 1,
                        Piece.Queen => white_pieces.Queen += 1,
                        Piece.King => white_pieces.King += 1,
                        else => {},
                    }
                }
            }
        }

        if (black_pieces.Queen > 0 or white_pieces.Queen > 0) {
            return false;
        }
        if (black_pieces.Rook > 0 or white_pieces.Rook > 0) {
            return false;
        }
        if (black_pieces.Pawn > 0 or white_pieces.Pawn > 0) {
            return false;
        }
        if (black_pieces.Knight == 2 or white_pieces.Knight == 2) {
            return false;
        }
        if (black_pieces.Bishop == 2 or white_pieces.Bishop == 2) {
            return false;
        }
        if (black_pieces.Knight == 1 and black_pieces.Bishop == 1) {
            return false;
        }
        if (white_pieces.Knight == 1 and white_pieces.Bishop == 1) {
            return false;
        }
        return true;
    }

    fn apply_move(game: *Game, move: MoveInfo) !RevertAction {
        const from = move.from;
        const to = move.to;
        const old_to = game.board.get_state_at(to);
        const old_from = game.board.get_state_at(from);

        game.board.move_piece(from, to);
        if (try old_from.get_piece() == Piece.UnmovedKing) {
            game.board.set_piece_at(to, Piece.King);
        }
        if (try old_from.get_piece() == Piece.UnmovedRook) {
            game.board.set_piece_at(to, Piece.Rook);
        }
        const revert_action = RevertMoveInfo{ .to_state = old_to, .from_state = old_from, .action = move };
        return RevertAction{ .Move = revert_action };
    }

    fn apply_castle(game: *Game, info: CastleInfo) RevertAction {
        const color = info.color;
        const king_side = info.king_side;

        if (color == Colors.White) {
            if (king_side) {
                game.board.move_piece(po.W_K1, po.W_KN1);
                game.board.move_piece(po.W_KR1, po.W_KB1);
                game.board.set_piece_at(po.W_KN1, Piece.King);
                game.board.set_piece_at(po.W_KB1, Piece.Rook);
            } else {
                game.board.move_piece(po.W_K1, po.W_QN1);
                game.board.move_piece(po.W_QR1, po.W_Q1);
                game.board.set_piece_at(po.W_QN1, Piece.King);
                game.board.set_piece_at(po.W_Q1, Piece.Rook);
            }
        } else {
            if (king_side) {
                game.board.move_piece(po.B_K1, po.B_KN1);
                game.board.move_piece(po.B_KR1, po.B_KB1);
                game.board.set_piece_at(po.B_KN1, Piece.King);
                game.board.set_piece_at(po.B_KB1, Piece.Rook);
            } else {
                game.board.move_piece(po.B_K1, po.B_QN1);
                game.board.move_piece(po.B_QR1, po.B_Q1);
                game.board.set_piece_at(po.B_QN1, Piece.King);
                game.board.set_piece_at(po.B_Q1, Piece.Rook);
            }
        }
        const revert_action = RevertCastleInfo{ .action = info };
        return RevertAction{ .Castle = revert_action };
    }

    fn apply_enpassant(game: *Game, enPassantInfo: EnPassantInfo) RevertAction {
        const target = enPassantInfo.target;
        const move = enPassantInfo.move;
        const from = move.from;
        const to = move.to;

        const old_target = game.board.get_state_at(target);
        const old_from = game.board.get_state_at(from);

        game.board.move_piece(from, to);
        game.board.clear_state_at(target);

        return RevertAction{
            .EnPassant = RevertEnPassantInfo{
                .target_state = old_target,
                .from_state = old_from,
                .action = enPassantInfo,
            },
        };
    }

    fn apply_promotion(game: *Game, info: PromotionInfo) RevertAction {
        const piece = info.piece;
        const move = info.move;
        const from = move.from;
        const to = move.to;
        const old_to = game.board.get_state_at(to);
        const old_from = game.board.get_state_at(from);

        game.board.move_piece(from, to);
        game.board.set_piece_at(to, piece);

        return RevertAction{
            .Promotion = RevertPromotionInfo{
                .to_state = old_to,
                .from_state = old_from,
                .action = info,
            },
        };
    }

    fn switch_active_color(game: *Game) void {
        game.active_color = if (game.active_color == Colors.White) Colors.Black else Colors.White;
    }

    fn has_legal_moves(game: *Game, color: Colors) bool {
        var action_list = ActionList.init(game.allocator);
        defer action_list.deinit();
        if (color != game.active_color) {
            game.flip_player();
            defer game.flip_player();
        }
        a.get_legal_actions(game, &action_list) catch return false;
        return action_list.items.len > 1;
    }

    pub fn apply_action(game: *Game, action: Action) !GameState {
        defer game.switch_active_color();
        game.last_action = action;
        const revert_action = switch (action) {
            Action.Move => blk: {
                const move = action.Move;
                break :blk try game.apply_move(move);
            },
            Action.Castle => blk: {
                const info = action.Castle;
                break :blk game.apply_castle(info);
            },
            Action.EnPassant => blk: {
                const enPassantInfo = action.EnPassant;
                break :blk game.apply_enpassant(enPassantInfo);
            },
            Action.Promotion => blk: {
                const promotionInfo = action.Promotion;
                break :blk game.apply_promotion(promotionInfo);
            },
            Action.Resign => {
                const is_checked = try r.is_in_check(game, game.active_color);
                const can_act = has_legal_moves(game, game.active_color);
                if (is_checked and !can_act) {
                    return GameState{ .Checkmate = RevertAction{ .Resign = {} } };
                } else if (is_checked or can_act) {
                    return GameState{ .Resign = RevertAction{ .Resign = {} } };
                } else if (!is_checked and !can_act) {
                    return GameState{ .Remis = RevertAction{ .Resign = {} } };
                } else {
                    unreachable;
                }
            },
            Action.Start => RevertAction{ .Start = {} },
        };

        if (try game.is_remis()) {
            return GameState{ .Remis = revert_action };
        }

        return GameState{ .InProgress = revert_action };
    }

    fn undo_move(game: *Game, revert_action: RevertMoveInfo) void {
        const from = revert_action.action.from;
        const to = revert_action.action.to;
        game.board.set_state_at(from, revert_action.from_state);
        game.board.set_state_at(to, revert_action.to_state);
    }

    fn undo_castle(game: *Game, revert_action: RevertCastleInfo) void {
        const color = revert_action.action.color;
        const king_side = revert_action.action.king_side;

        if (color == Colors.White) {
            if (king_side) {
                game.board.move_piece(po.W_KN1, po.W_K1);
                game.board.move_piece(po.W_KB1, po.W_KR1);
                game.board.set_piece_at(po.W_K1, Piece.UnmovedKing);
                game.board.set_piece_at(po.W_KR1, Piece.UnmovedRook);
            } else {
                game.board.move_piece(po.W_QN1, po.W_K1);
                game.board.move_piece(po.W_Q1, po.W_QR1);
                game.board.set_piece_at(po.W_K1, Piece.UnmovedKing);
                game.board.set_piece_at(po.W_QR1, Piece.UnmovedRook);
            }
        } else {
            if (king_side) {
                game.board.move_piece(po.B_KN1, po.B_K1);
                game.board.move_piece(po.B_KB1, po.B_KR1);
                game.board.set_piece_at(po.B_K1, Piece.UnmovedKing);
                game.board.set_piece_at(po.B_KR1, Piece.UnmovedRook);
            } else {
                game.board.move_piece(po.B_QN1, po.B_K1);
                game.board.move_piece(po.B_Q1, po.B_QR1);
                game.board.set_piece_at(po.B_K1, Piece.UnmovedKing);
                game.board.set_piece_at(po.B_QR1, Piece.UnmovedRook);
            }
        }
    }

    fn undo_enpassant(game: *Game, revert_action: RevertEnPassantInfo) void {
        const target = revert_action.action.target;
        const move = revert_action.action.move;
        const from = move.from;
        const to = move.to;

        game.board.set_state_at(from, revert_action.from_state);
        game.board.clear_state_at(to);
        game.board.set_state_at(target, revert_action.target_state);
    }

    fn undo_promotion(game: *Game, revert_action: RevertPromotionInfo) void {
        const move = revert_action.action.move;
        const from = move.from;
        const to = move.to;

        game.board.set_state_at(from, revert_action.from_state);
        game.board.set_state_at(to, revert_action.to_state);
    }

    pub fn undo_action(game: *Game, revert_action: RevertAction) void {
        defer game.switch_active_color();
        switch (revert_action) {
            Action.Move => {
                const move = revert_action.Move;
                game.undo_move(move);
            },
            Action.Castle => {
                const info = revert_action.Castle;
                game.undo_castle(info);
            },
            Action.EnPassant => {
                const enPassantInfo = revert_action.EnPassant;
                game.undo_enpassant(enPassantInfo);
            },
            Action.Promotion => {
                const promotionInfo = revert_action.Promotion;
                game.undo_promotion(promotionInfo);
            },
            Action.Resign => {},
            Action.Start => {},
        }
    }
};

test "game init" {
    const allocator = std.testing.allocator;
    var game = Game{ .allocator = allocator };
    try testing.expect(game.active_color == Colors.White);
    try testing.expect(game.last_action == Action.Start);
    game.set_up();
    const square = try game.board.get_square_at(po.B_KR1);
    try testing.expect(square.piece == Piece.UnmovedRook);
}

test "game apply move" {
    const allocator = std.testing.allocator;
    var game = Game{ .allocator = allocator };
    game.set_up();
    const from = Position{ .file = 4, .rank = 1 };
    const from_square_initial = try game.board.get_square_at(from);
    const to = Position{ .file = 4, .rank = 1 + 2 };
    const to_square_initial = try game.board.get_square_at(to);
    const move = MoveInfo{ .from = from, .to = to };
    const revert_action = try game.apply_move(move);
    const from_square_final = try game.board.get_square_at(from);
    const to_square_final = try game.board.get_square_at(to);
    game.undo_action(revert_action);
    const from_square_undo = try game.board.get_square_at(from);
    const to_square_undo = try game.board.get_square_at(to);

    try testing.expect(from_square_initial.piece == Piece.Pawn);
    try testing.expect(from_square_final.piece == Piece.None);
    try testing.expect(to_square_initial.piece == Piece.None);
    try testing.expect(to_square_final.piece == Piece.Pawn);
    try testing.expect(from_square_undo.piece == Piece.Pawn);
    try testing.expect(to_square_undo.piece == Piece.None);
}

fn test_apply_move_capture(board_setup: *const [71:0]u8, expected_board_final: *const [71:0]u8, action: Action) !void {
    const allocator = std.testing.allocator;
    var game = Game{ .allocator = allocator };

    try game.board.set_up_from_string(board_setup);

    const revert_action = try game.apply_action(action);

    var actual_board_final = [_]u8{0} ** 78;
    _ = try std.fmt.bufPrint(&actual_board_final, "{s}", .{game.board});

    // std.debug.print("\n{s}\n", .{actual_board_final});

    for (expected_board_final, 0..) |expected, i| {
        try testing.expect(expected == actual_board_final[i]);
    }

    game.undo_action(revert_action.revert_action());

    var actual_board_undo = [_]u8{0} ** 78;
    _ = try std.fmt.bufPrint(&actual_board_undo, "{s}", .{game.board});

    // std.debug.print("\n{s}\n", .{actual_board_undo});

    for (board_setup, 0..) |expected, i| {
        try testing.expect(expected == actual_board_undo[i]);
    }
}

test "game apply castle white queen side" {
    const board_setup =
        \\R...K...
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
    ;
    const expected_board_final =
        \\.K.R....
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
    ;
    const action = Action{ .Castle = CastleInfo{ .color = Colors.White, .king_side = false } };
    try test_apply_move_capture(board_setup, expected_board_final, action);
}

test "game apply castle white king side" {
    const board_setup =
        \\....K..R
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
    ;
    const expected_board_final =
        \\.....RK.
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
    ;
    const action = Action{ .Castle = CastleInfo{ .color = Colors.White, .king_side = true } };
    try test_apply_move_capture(board_setup, expected_board_final, action);
}

test "game apply castle black queen side" {
    const board_setup =
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\r...k...
    ;
    const expected_board_final =
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.k.r....
    ;
    const action = Action{ .Castle = CastleInfo{ .color = Colors.Black, .king_side = false } };
    try test_apply_move_capture(board_setup, expected_board_final, action);
}

test "game apply castle black king side" {
    const board_setup =
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\....k..r
    ;
    const expected_board_final =
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\.....rk.
    ;
    const action = Action{ .Castle = CastleInfo{ .color = Colors.Black, .king_side = true } };
    try test_apply_move_capture(board_setup, expected_board_final, action);
}

test "game apply en passant" {
    const board_setup =
        \\........
        \\........
        \\........
        \\........
        \\pP......
        \\........
        \\........
        \\........
    ;
    const expected_board_final =
        \\........
        \\........
        \\........
        \\........
        \\........
        \\P.......
        \\........
        \\........
    ;
    const from = Position{ .file = 1, .rank = 4 };
    const to = Position{ .file = 0, .rank = 5 };
    const target = Position{ .file = 0, .rank = 4 };
    const action = Action{ .EnPassant = EnPassantInfo{
        .move = MoveInfo{ .from = from, .to = to },
        .target = target,
    } };
    try test_apply_move_capture(board_setup, expected_board_final, action);
}

test "game apply promotion" {
    const board_setup =
        \\........
        \\p.......
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
    ;
    const expected_board_final =
        \\q.......
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
    ;
    const from = Position{ .file = 0, .rank = 1 };
    const to = Position{ .file = 0, .rank = 0 };
    const action = Action{ .Promotion = PromotionInfo{
        .move = MoveInfo{ .from = from, .to = to },
        .piece = Piece.Queen,
    } };
    try test_apply_move_capture(board_setup, expected_board_final, action);
}

test "game apply promotion capture" {
    const board_setup =
        \\.P......
        \\p.......
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
    ;
    const expected_board_final =
        \\.q......
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
    ;
    const from = Position{ .file = 0, .rank = 1 };
    const to = Position{ .file = 1, .rank = 0 };
    const action = Action{ .Promotion = PromotionInfo{
        .move = MoveInfo{ .from = from, .to = to },
        .piece = Piece.Queen,
    } };
    try test_apply_move_capture(board_setup, expected_board_final, action);
}
