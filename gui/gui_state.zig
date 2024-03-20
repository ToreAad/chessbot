const std = @import("std");
const rl = @import("raylib");
const chess = @import("chess");

const GuiTile = @import("gui_tile.zig").GuiTile;
const MouseState = @import("mouse_state.zig").MouseState;

pub const Screens = enum {
    Menu,
    Gameplay,
    Ending,
};

pub const Endings = enum {
    Checkmate,
    Remis,
    Resign,
};

pub const MenuInfo = struct {
    fn update(self: *MenuInfo) !Screens {
        _ = self;
        if (rl.isKeyPressed(rl.KeyboardKey.key_space)) {
            return Screens.Gameplay;
        }
        return Screens.Menu;
    }
};

pub const EndingInfo = struct {
    ending: Endings,
    winner: chess.Colors,

    fn update(self: *EndingInfo) !Screens {
        _ = self;
        if (rl.isKeyPressed(rl.KeyboardKey.key_space)) {
            return Screens.Gameplay;
        }
        return Screens.Ending;
    }
};

pub const Screen = union(enum) {
    Menu: MenuInfo,
    Gameplay: GameplayInfo,
    Ending: EndingInfo,
};

pub const GameplayInfo = struct {
    game: chess.Game,
    tiles: [64]GuiTile,
    revert_action_list: std.ArrayList(chess.GameState),
    white_player: chess.agent.RandomAgent,
    black_player: chess.agent.RandomAgent,

    fn reset_board(self: *GuiState) !void {
        const board_setup =
            \\ RNBQKBNR
            \\ PPPPPPPP
            \\ ........
            \\ ........
            \\ ........
            \\ ........
            \\ pppppppp
            \\ rnbqkbnr
        ;
        try self.game.board.set_up_from_string(board_setup);
        for (self.tiles, 0..) |_, i| {
            self.tiles[i].down_selected = false;
            self.tiles[i].up_selected = false;
            self.tiles[i].hovered = false;
        }
    }

    pub fn init(
        allocator: std.mem.Allocator,
        x_offset: i32,
        y_offset: i32,
        square_size: i32,
    ) !GameplayInfo {
        var game = chess.Game{ .allocator = allocator };

        const board_setup =
            \\ RNBQKBNR
            \\ PPPPPPPP
            \\ ........
            \\ ........
            \\ ........
            \\ ........
            \\ pppppppp
            \\ rnbqkbnr
        ;
        try game.board.set_up_from_string(board_setup);

        var tiles: [64]GuiTile = undefined;
        var file: u8 = 0;
        while (file < 8) : (file += 1) {
            var rank: u8 = 0;
            while (rank < 8) : (rank += 1) {
                const x = file * square_size;
                const y = rank * square_size;
                tiles[file + rank * 8] = GuiTile{
                    .rect = rl.Rectangle{
                        .x = @as(f32, @floatFromInt(x + x_offset)),
                        .y = @as(f32, @floatFromInt(y + y_offset)),
                        .width = @as(f32, @floatFromInt(square_size)),
                        .height = @as(f32, @floatFromInt(square_size)),
                    },
                    .color = if ((file + rank) % 2 == 0) rl.Color.white else rl.Color.dark_gray,
                    .hovered = false,
                    .down_selected = false,
                    .up_selected = false,
                };
            }
        }
        const revert_action_list = std.ArrayList(chess.GameState).init(allocator);
        const white_player = chess.agent.RandomAgent.init();
        const black_player = chess.agent.RandomAgent.init();
        return GameplayInfo{
            .game = game,
            .tiles = tiles,
            .revert_action_list = revert_action_list,
            .white_player = white_player,
            .black_player = black_player,
        };
    }

    pub fn deinit(self: *GameplayInfo) void {
        self.revert_action_list.deinit();
    }

    fn update(self: *GameplayInfo) !Screens {
        if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_right)) {
            if (self.revert_action_list.items.len > 0) {
                const revert_action = self.revert_action_list.pop();
                self.game.undo_action(revert_action.revert_action());
            }
        }

        const mouse_state = blk: {
            const btn = rl.MouseButton.mouse_button_left;
            if (rl.isMouseButtonPressed(btn)) {
                break :blk MouseState.Pressed;
            } else if (rl.isMouseButtonDown(btn)) {
                break :blk MouseState.Down;
            } else if (rl.isMouseButtonReleased(btn)) {
                break :blk MouseState.Released;
            } else if (rl.isMouseButtonUp(btn)) {
                break :blk MouseState.Up;
            } else {
                unreachable;
            }
        };

        const mouse_position = rl.getMousePosition();

        for (self.tiles, 0..) |_, i| {
            self.tiles[i].update(mouse_position, mouse_state);
        }

        if (rl.isKeyPressed(rl.KeyboardKey.key_x)) {
            return Screens.Ending;
        }

        const new_state = try self.maybe_change_game_state();

        if (new_state != null) {
            switch (new_state.?) {
                .Checkmate => return Screens.Ending,
                .Remis => return Screens.Ending,
                .Resign => return Screens.Ending,
                else => {
                    try self.revert_action_list.append(new_state.?);
                },
            }
        }
        return Screens.Gameplay;
    }

    fn maybe_change_game_state(self: *GameplayInfo) !?chess.GameState {
        if (rl.isMouseButtonReleased(rl.MouseButton.mouse_button_left)) {
            // get down selected tile
            const down_selected_index = try self.get_down_selected_index();
            if (down_selected_index == null) {
                self.reset_selected();
                return null;
            }

            // get file and rank of down selected tile
            const down_selected_position = try index_to_position(down_selected_index.?);

            // get up selected tile
            const up_selected_index = try self.get_up_selected_index();
            if (up_selected_index == null) {
                self.reset_selected();
                return null;
            }
            self.reset_selected();
            // get file and rank of up selected tile
            const up_selected_position = try index_to_position(up_selected_index.?);

            // get action from down and up selected tiles
            const action = try self.get_action(down_selected_position, up_selected_position);

            if (false == try chess.Rules.legal_action(&self.game, action)) {
                // self.reset_selected();
                return null;
            }
            // apply action to game
            return try self.game.apply_action(action);
        }

        if (rl.isKeyPressed(rl.KeyboardKey.key_space)) {
            if (self.game.active_color == chess.Colors.White) {
                const action = try self.white_player.get_action(&self.game);
                return try self.game.apply_action(action);
            } else {
                const action = try self.black_player.get_action(&self.game);
                return try self.game.apply_action(action);
            }
        }
        return null;
    }

    fn index_to_position(index: usize) !chess.Position {
        const file = @as(u8, @intCast(index % 8));
        const rank = @as(u8, @intCast(index / 8));
        return chess.Position{ .file = file, .rank = rank };
    }

    fn get_action(self: *GameplayInfo, down_selected_position: chess.Position, up_selected_position: chess.Position) !chess.Action {
        const from_square = try self.game.board.get_square_at(down_selected_position);

        const move = chess.game.MoveInfo{ .from = down_selected_position, .to = up_selected_position };

        switch (from_square.piece) {
            .Pawn => {
                if (up_selected_position.rank == 0 or up_selected_position.rank == 7) {
                    return chess.Action{
                        .Promotion = chess.game.PromotionInfo{
                            .piece = chess.Piece.Queen,
                            .move = move,
                        },
                    };
                }
                return chess.Action{
                    .Move = move,
                };
            },

            .UnmovedKing => {
                if (move.to.file == move.from.file + 2) {
                    return chess.Action{
                        .Castle = chess.game.CastleInfo{
                            .color = from_square.color,
                            .king_side = true,
                        },
                    };
                } else if (move.to.file == move.from.file - 3) {
                    return chess.Action{
                        .Castle = chess.game.CastleInfo{
                            .color = from_square.color,
                            .king_side = false,
                        },
                    };
                }
                return chess.Action{
                    .Move = move,
                };
            },
            else => {
                return chess.Action{
                    .Move = move,
                };
            },
        }
    }

    fn reset_selected(self: *GameplayInfo) void {
        for (self.tiles, 0..) |_, i| {
            self.tiles[i].down_selected = false;
            self.tiles[i].up_selected = false;
        }
    }

    fn get_down_selected_index(self: *GameplayInfo) !?usize {
        for (self.tiles, 0..) |tile, i| {
            if (tile.down_selected) {
                return i;
            }
        }
        return null;
    }

    fn get_up_selected_index(self: *GameplayInfo) !?usize {
        for (self.tiles, 0..) |tile, i| {
            if (tile.up_selected) {
                return i;
            }
        }
        return null;
    }

    pub fn get_ending(self: *GameplayInfo) EndingInfo {
        _ = self;
        return EndingInfo{
            .ending = Endings.Checkmate,
            .winner = chess.Colors.White,
        };
    }
};

pub const GuiState = struct {
    screen: Screen,
    allocator: std.mem.Allocator,
    x_offset: i32,
    y_offset: i32,
    square_size: i32,

    pub fn init(
        allocator: std.mem.Allocator,
        x_offset: i32,
        y_offset: i32,
        square_size: i32,
    ) !GuiState {
        return GuiState{
            .screen = Screen{
                .Menu = MenuInfo{},
            },
            .allocator = allocator,
            .x_offset = x_offset,
            .y_offset = y_offset,
            .square_size = square_size,
        };
    }

    pub fn update(self: *GuiState) !void {
        const new_screen = switch (self.screen) {
            .Menu => |*menu| try menu.update(),
            .Gameplay => |*gameplay| try gameplay.update(),
            .Ending => |*ending| try ending.update(),
        };

        const old_screen = switch (self.screen) {
            .Menu => Screens.Menu,
            .Gameplay => Screens.Gameplay,
            .Ending => Screens.Ending,
        };

        if (new_screen != old_screen) {
            try self.change_screen(new_screen);
        }
    }

    fn change_screen(self: *GuiState, new_screen: Screens) !void {
        switch (new_screen) {
            .Menu => {
                self.screen = Screen{
                    .Menu = MenuInfo{},
                };
            },
            .Gameplay => {
                self.screen = Screen{
                    .Gameplay = try GameplayInfo.init(
                        self.allocator,
                        self.x_offset,
                        self.y_offset,
                        self.square_size,
                    ),
                };
            },
            .Ending => {
                const ending = self.screen.Gameplay.get_ending();
                self.screen.Gameplay.deinit();
                self.screen = Screen{
                    .Ending = ending,
                };
            },
        }
    }
};
