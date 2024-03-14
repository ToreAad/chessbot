const std = @import("std");
const rl = @import("raylib");
const chess = @import("chess");

const GuiTile = @import("gui_tile.zig").GuiTile;

pub const GuiState = struct {
    game: chess.Game,
    mouse_position: rl.Vector2,
    tiles: [64]GuiTile,
    revert_action_list: std.ArrayList(chess.GameState),
    white_player: chess.agent.RandomAgent,
    black_player: chess.agent.RandomAgent,

    pub fn init(
        allocator: std.mem.Allocator,
        x_offset: i32,
        y_offset: i32,
        square_size: i32,
    ) !GuiState {
        var game = chess.Game{ .allocator = allocator };
        game.set_up();

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
                    .selected = false,
                };
            }
        }
        const revert_action_list = std.ArrayList(chess.GameState).init(allocator);
        const white_player = chess.agent.RandomAgent.init();
        const black_player = chess.agent.RandomAgent.init();
        return GuiState{
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

    pub fn update(self: *GuiState) !void {
        if (rl.isKeyPressed(rl.KeyboardKey.key_right)) {
            if (self.game.active_color == chess.Colors.White) {
                const action = try self.white_player.get_action(&self.game);
                const revert_action = try self.game.apply_action(action);
                try self.revert_action_list.append(revert_action);
            } else {
                const action = try self.black_player.get_action(&self.game);
                const revert_action = try self.game.apply_action(action);
                try self.revert_action_list.append(revert_action);
            }
        } else if (rl.isKeyPressed(rl.KeyboardKey.key_left)) {
            if (self.revert_action_list.items.len > 0) {
                const revert_action = self.revert_action_list.pop();
                self.game.undo_action(revert_action.revert_action());
            }
        }

        const clicked = rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left);

        self.mouse_position = rl.getMousePosition();

        for (self.tiles, 0..) |_, i| {
            self.tiles[i].update(self.mouse_position, clicked);
        }
    }
};
