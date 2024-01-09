const std = @import("std");
const testing = std.testing;

const p = @import("position.zig");
const s = @import("square.zig");
const b = @import("board.zig");

const Move = struct {
    from: p.Position,
    to: p.Position,
};

const Actions = enum {
    Start,
    Move,
    Capture,
    Castle,
    EnPassant,
    Promotion,
    Resign,
};

const CastleInfo = struct {
    color: s.Colors,
    king_side: bool,
};

const EnPassantInfo = struct {
    target: p.Position,
    move: Move,
};

const PromotionInfo = struct {
    piece: s.Piece,
    move: Move,
};

const Action = union(Actions) {
    Move: Move,
    Castle: CastleInfo,
    EnPassant: Move,
    Promotion: Move,
    Resign: void,
    Start: void,
};

const RevertAction = struct {
    to_state: u32,
    from_state: u32,
};

const Game = struct {
    board: b.Board,
    active_color: s.Colors,
    last_action: Action,
    allocator: *std.mem.Allocator,

    fn init(allocator: *std.mem.Allocator) Game {
        return Game{
            .board = b.Board.init(allocator),
            .active_color = s.Colors.White,
            .last_action = Action.Start,
            .allocator = allocator,
        };
    }

    fn apply_action(game: *Game, action: Action) RevertAction {
        switch (action) {
            Action.Move => {
                const move = action.Move;
                const from = move.from;
                const to = move.to;
                const piece = game.board.pieces[from.file][from.rank];
                const moved_peice = s.set_moved(piece);
                game.board.pieces[from.file][from.rank] = 0;
                game.board.pieces[to.file][to.rank] = moved_peice;
            },
            Action.Castle => {
                const info = action.Castle;
                const color = info.color;
                const king_side = info.king_side;
                if (color == s.Colors.White) {
                    if (king_side) {
                        game.board.pieces[s.W_KN1.file][s.W_KN1.rank] = s.set_moved(game.board.pieces[s.W_K1.file][s.W_K1.rank]);
                        game.board.pieces[s.W_KB1.file][s.W_KB1.rank] = s.set_moved(game.board.pieces[s.W_KR1.file][s.W_KR1.rank]);
                        game.board.pieces[s.W_K1.file][s.W_K1.rank] = 0;
                        game.board.pieces[s.W_KR1.file][s.W_KR1.rank] = 0;
                    } else {
                        game.board.pieces[s.W_QN1.file][s.W_QN1.rank] = s.set_moved(game.board.pieces[s.W_K1.file][s.W_K1.rank]);
                        game.board.pieces[s.W_Q1.file][s.W_Q1.rank] = s.set_moved(game.board.pieces[s.W_QR1.file][s.W_QR1.rank]);
                        game.board.pieces[s.W_K1.file][s.W_K1.rank] = 0;
                        game.board.pieces[s.W_QR1.file][s.W_QR1.rank] = 0;
                    }
                } else {
                    if (king_side) {
                        game.board.pieces[s.B_KN1.file][s.B_KN1.rank] = s.set_moved(game.board.pieces[s.B_K1.file][s.B_K1.rank]);
                        game.board.pieces[s.B_KB1.file][s.B_KB1.rank] = s.set_moved(game.board.pieces[s.B_KR1.file][s.B_KR1.rank]);
                        game.board.pieces[s.B_K1.file][s.B_K1.rank] = 0;
                        game.board.pieces[s.B_KR1.file][s.B_KR1.rank] = 0;
                    } else {
                        game.board.pieces[s.B_QN1.file][s.B_QN1.rank] = s.set_moved(game.board.pieces[s.B_K1.file][s.B_K1.rank]);
                        game.board.pieces[s.B_Q1.file][s.B_Q1.rank] = s.set_moved(game.board.pieces[s.B_QR1.file][s.B_QR1.rank]);
                        game.board.pieces[s.B_K1.file][s.B_K1.rank] = 0;
                        game.board.pieces[s.B_QR1.file][s.B_QR1.rank] = 0;
                    }
                }
            },
            Action.EnPassant => {
                const enPassantInfo = action.EnPassant;
                const target = enPassantInfo.target;
                const move = enPassantInfo.move;
                const from = move.from;
                const to = move.to;
                const piece = game.board.pieces[from.file][from.rank];
                const moved_piece = s.set_moved(piece);
                game.board.pieces[from.file][from.rank] = 0;
                game.board.pieces[to.file][to.rank] = moved_piece;
                game.board.pieces[target.file][target.rank] = 0;
            },
            Action.Promotion => {
                const promotionInfo = action.Promotion;
                const piece = promotionInfo.piece;
                const move = promotionInfo.move;
                const from = move.from;
                const to = move.to;
                const old_piece = game.board.pieces[from.file][from.rank];
                const moved_piece = s.set_piece(s.set_moved(old_piece), piece);
                game.board.pieces[from.file][from.rank] = 0;
                game.board.pieces[to.file][to.rank] = moved_piece;
            },
            Action.Resign => {
                // TODO
            },
            Action.Start => {
                // TODO
            },
        }
    }

    fn undo_action(game: *Game, action: Action, old_state: RevertAction) void {
        switch (action) {
            Action.Move => {
                const move = action.Move;
                const from = move.from;
                const to = move.to;
                game.board.pieces[from.file][from.rank] = old_state.from_state;
                game.board.pieces[to.file][to.rank] = old_state.to_state;
            },
            Action.Castle => {
                const info = action.Castle;
                const color = info.color;
                const king_side = info.king_side;
                if (color == s.Colors.White) {
                    if (king_side) {
                        game.board.pieces[s.W_K1.file][s.W_K1.rank] = s.set_unmoved(game.board.pieces[s.W_KN1.file][s.W_KN1.rank]);
                        game.board.pieces[s.W_KR1.file][s.W_KR1.rank] = s.set_unmoved(game.board.pieces[s.W_KB1.file][s.W_KB1.rank]);
                        game.board.pieces[s.W_KN1.file][s.W_KN1.rank] = 0;
                        game.board.pieces[s.W_KB1.file][s.W_KB1.rank] = 0;
                    } else {
                        game.board.pieces[s.W_K1.file][s.W_K1.rank] = s.set_unmoved(game.board.pieces[s.W_QN1.file][s.W_QN1.rank]);
                        game.board.pieces[s.W_QR1.file][s.W_QR1.rank] = s.set_unmoved(game.board.pieces[s.W_Q1.file][s.W_Q1.rank]);
                        game.board.pieces[s.W_QN1.file][s.W_QN1.rank] = 0;
                        game.board.pieces[s.W_Q1.file][s.W_Q1.rank] = 0;
                    }
                } else {
                    if (king_side) {
                        game.board.pieces[s.B_K1.file][s.B_K1.rank] = s.set_unmoved(game.board.pieces[s.B_KN1.file][s.B_KN1.rank]);
                        game.board.pieces[s.B_KR1.file][s.B_KR1.rank] = s.set_unmoved(game.board.pieces[s.B_KB1.file][s.B_KB1.rank]);
                        game.board.pieces[s.B_KN1.file][s.B_KN1.rank] = 0;
                        game.board.pieces[s.B_KB1.file][s.B_KB1.rank] = 0;
                    } else {
                        game.board.pieces[s.B_K1.file][s.B_K1.rank] = s.set_unmoved(game.board.pieces[s.B_QN1.file][s.B_QN1.rank]);
                        game.board.pieces[s.B_QR1.file][s.B_QR1.rank] = s.set_unmoved(game.board.pieces[s.B_Q1.file][s.B_Q1.rank]);
                        game.board.pieces[s.B_QN1.file][s.B_QN1.rank] = 0;
                        game.board.pieces[s.B_Q1.file][s.B_Q1.rank] = 0;
                    }
                }
            },
            Action.EnPassant => {
                const enPassantInfo = action.EnPassant;
                const target = enPassantInfo.target;
                const move = enPassantInfo.move;
                const from = move.from;
                const to = move.to;
                game.board.pieces[from.file][from.rank] = old_state.from_state;
                game.board.pieces[to.file][to.rank] = old_state.to_state;
                game.board.pieces[target.file][target.rank] = 0;
            },
            Action.Promotion => {
                const promotionInfo = action.Promotion;
                const move = promotionInfo.move;
                const from = move.from;
                const to = move.to;
                game.board.pieces[from.file][from.rank] = old_state.from_state;
                game.board.pieces[to.file][to.rank] = old_state.to_state;
            },
            Action.Resign => {
                unreachable;
            },
            Action.Start => {
                unreachable;
            },
        }
    }
};
