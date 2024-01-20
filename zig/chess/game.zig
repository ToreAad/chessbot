const std = @import("std");
const testing = std.testing;

const po = @import("position.zig");
const Board = @import("board.zig").Board;
const Piece = @import("pieces.zig").Piece;
const Colors = @import("colors.zig").Colors;
const SquareData = @import("square.zig").SquareData;
const Position = @import("position.zig").Position;

const MoveInfo = struct {
    from: Position,
    to: Position,
};

const Actions = enum {
    Start,
    Move,
    Castle,
    EnPassant,
    Promotion,
    Resign,
};

const CastleInfo = struct {
    color: Colors,
    king_side: bool,
};

const EnPassantInfo = struct {
    target: Position,
    move: MoveInfo,
};

const PromotionInfo = struct {
    piece: Piece,
    move: MoveInfo,
};

const Action = union(Actions) {
    Start: void,
    Move: MoveInfo,
    Castle: CastleInfo,
    EnPassant: EnPassantInfo,
    Promotion: PromotionInfo,
    Resign: void,
};

const RevertMoveInfo = struct {
    to_state: SquareData,
    from_state: SquareData,
    action: MoveInfo,
};

const RevertCastleInfo = struct {
    action: CastleInfo,
};

const RevertEnPassantInfo = struct {
    target_state: SquareData,
    from_state: SquareData,
    action: EnPassantInfo,
};

const RevertPromotionInfo = struct {
    to_state: SquareData,
    from_state: SquareData,
    action: PromotionInfo,
};

const RevertAction = union(Actions) {
    Move: RevertMoveInfo,
    Castle: RevertCastleInfo,
    EnPassant: RevertEnPassantInfo,
    Promotion: RevertPromotionInfo,
    Resign: void,
    Start: void,
};

const Game = struct {
    board: Board = Board{},
    active_color: Colors = Colors.White,
    last_action: Action = Action.Start,
    allocator: *std.mem.Allocator,

    fn apply_move(game: *Game, move: MoveInfo) RevertAction {
        const from = move.from;
        const to = move.to;
        const old_to = game.board.get_state_at(to);
        const old_from = game.board.get_state_at(from);

        game.board.move_piece(from, to);
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
            } else {
                game.board.move_piece(po.W_K1, po.W_QN1);
                game.board.move_piece(po.W_QR1, po.W_Q1);
            }
        } else {
            if (king_side) {
                game.board.move_piece(po.B_K1, po.B_KN1);
                game.board.move_piece(po.B_KR1, po.B_KB1);
            } else {
                game.board.move_piece(po.B_K1, po.B_QN1);
                game.board.move_piece(po.B_QR1, po.B_Q1);
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

    pub fn apply_action(game: *Game, action: Action) RevertAction {
        defer game.switch_active_color();
        switch (action) {
            Action.Move => {
                const move = action.Move;
                return game.apply_move(move);
            },
            Action.Castle => {
                const info = action.Castle;
                return game.apply_castle(info);
            },
            Action.EnPassant => {
                const enPassantInfo = action.EnPassant;
                return game.apply_enpassant(enPassantInfo);
            },
            Action.Promotion => {
                const promotionInfo = action.Promotion;
                return game.apply_promotion(promotionInfo);
            },
            Action.Resign => {
                return RevertAction{ .Resign = void };
            },
            Action.Start => {
                return RevertAction{ .Start = void };
            },
        }
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
            } else {
                game.board.move_piece(po.W_QN1, po.W_K1);
                game.board.move_piece(po.W_Q1, po.W_QR1);
            }
        } else {
            if (king_side) {
                game.board.move_piece(po.B_KN1, po.B_K1);
                game.board.move_piece(po.B_KB1, po.B_KR1);
            } else {
                game.board.move_piece(po.B_QN1, po.B_K1);
                game.board.move_piece(po.B_Q1, po.B_QR1);
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

    fn undo_action(game: *Game, revert_action: RevertAction) void {
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

test "test game init" {
    var allocator = std.heap.page_allocator;
    const game = Game{ .allocator = &allocator };
    try testing.expect(game.active_color == Colors.White);
    try testing.expect(game.last_action == Action.Start);
}
