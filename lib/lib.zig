const std = @import("std");
const testing = std.testing;
const chess = @import("chess");

const Position = extern struct {
    file: u8,
    rank: u8,
};

const ActionInfo = extern struct {
    Move: u32,
    Castle: u32,
    EnPassant: u32,
    Promotion: u32,
    Resign: u32,
};

export fn get_action_info() ActionInfo {
    return ActionInfo{
        .Move = 0,
        .Castle = 1,
        .EnPassant = 2,
        .Promotion = 3,
        .Resign = 4,
    };
}

const Action = extern struct {
    type: u32,
    from: Position,
    to: Position,
    promotion: u32,
};

const Board = [8 * 8]u32;

const PawnFlag = 1 << 0;
const KnightFlag = 1 << 1;
const BishopFlag = 1 << 2;
const RookFlag = 1 << 3;
const QueenFlag = 1 << 4;
const KingFlag = 1 << 5;
const UnmovedKingFlag = 1 << 6;
const UnmovedRookFlag = 1 << 7;
const WhiteFlag = 1 << 8;
const BlackFlag = 1 << 9;

const PieceFlagInfo = extern struct {
    PawnFlag: u32,
    KnightFlag: u32,
    BishopFlag: u32,
    RookFlag: u32,
    QueenFlag: u32,
    KingFlag: u32,
    UnmovedKingFlag: u32,
    UnmovedRookFlag: u32,
    WhiteFlag: u32,
    BlackFlag: u32,
};

export fn get_pieceflag_info() PieceFlagInfo {
    return PieceFlagInfo{
        .PawnFlag = PawnFlag,
        .KnightFlag = KnightFlag,
        .BishopFlag = BishopFlag,
        .RookFlag = RookFlag,
        .QueenFlag = QueenFlag,
        .KingFlag = KingFlag,
        .UnmovedKingFlag = UnmovedKingFlag,
        .UnmovedRookFlag = UnmovedRookFlag,
        .WhiteFlag = WhiteFlag,
        .BlackFlag = BlackFlag,
    };
}
