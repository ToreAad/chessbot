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

pub const GuiState = struct {
    screen: Screens,
    game: chess.Game,
    mouse_position: rl.Vector2,
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
    ) !GuiState {
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
        return GuiState{
            .screen = Screens.Menu,
            .game = game,
            .mouse_position = rl.Vector2{ .x = 0, .y = 0 },
            .tiles = tiles,
            .revert_action_list = revert_action_list,
            .white_player = white_player,
            .black_player = black_player,
        };
    }

    pub fn deinit(self: *GuiState) void {
        self.revert_action_list.deinit();
    }

    fn update_gameplay(self: *GuiState) !void {
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

        for (self.tiles, 0..) |_, i| {
            self.tiles[i].update(self.mouse_position, mouse_state);
        }

        const new_state = try self.maybe_change_game_state();

        if (new_state != null) {
            switch (new_state.?) {
                .Checkmate => self.screen = Screens.Ending,
                .Remis => self.screen = Screens.Ending,
                .Resign => self.screen = Screens.Ending,
                else => {
                    try self.revert_action_list.append(new_state.?);
                },
            }
        }
    }

    fn maybe_change_game_state(self: *GuiState) !?chess.GameState {
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

        if (rl.isKeyPressed(rl.KeyboardKey.key_x)) {
            self.screen = Screens.Ending;
            return null;
        }
        return null;
    }

    fn update_menu(self: *GuiState) !void {
        if (rl.isKeyPressed(rl.KeyboardKey.key_space)) {
            try self.reset_board();
            self.screen = Screens.Gameplay;
        }
    }

    fn update_ending(self: *GuiState) void {
        if (rl.isKeyPressed(rl.KeyboardKey.key_space)) {
            self.screen = Screens.Menu;
        }
    }

    pub fn update(self: *GuiState) !void {
        self.mouse_position = rl.getMousePosition();

        switch (self.screen) {
            .Menu => try self.update_menu(),
            .Gameplay => try self.update_gameplay(),
            .Ending => self.update_ending(),
        }
    }

    fn get_action(self: *GuiState, down_selected_position: chess.Position, up_selected_position: chess.Position) !chess.Action {
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

    fn reset_selected(self: *GuiState) void {
        for (self.tiles, 0..) |_, i| {
            self.tiles[i].down_selected = false;
            self.tiles[i].up_selected = false;
        }
    }

    fn get_down_selected_index(self: *GuiState) !?usize {
        for (self.tiles, 0..) |tile, i| {
            if (tile.down_selected) {
                return i;
            }
        }
        return null;
    }

    fn get_up_selected_index(self: *GuiState) !?usize {
        for (self.tiles, 0..) |tile, i| {
            if (tile.up_selected) {
                return i;
            }
        }
        return null;
    }

    fn index_to_position(index: usize) !chess.Position {
        const file = @as(u8, @intCast(index % 8));
        const rank = @as(u8, @intCast(index / 8));
        return chess.Position{ .file = file, .rank = rank };
    }
};
