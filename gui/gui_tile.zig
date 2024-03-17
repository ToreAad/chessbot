const std = @import("std");
const rl = @import("raylib");
const chess = @import("chess");

const MouseState = @import("mouse_state.zig").MouseState;

pub const GuiTile = struct {
    rect: rl.Rectangle,
    color: rl.Color,
    hovered: bool,
    down_selected: bool,
    up_selected: bool,

    pub fn draw(self: *const GuiTile) void {
        rl.drawRectangleRec(self.rect, self.color);
        if (self.hovered) {
            rl.drawRectangleLinesEx(self.rect, 2.0, rl.Color.blue);
        }
        if (self.down_selected) {
            rl.drawRectangleLinesEx(self.rect, 4.0, rl.Color.red);
        }
        if (self.up_selected) {
            rl.drawRectangleLinesEx(self.rect, 2.0, rl.Color.red);
        }
    }

    pub fn update(self: *GuiTile, pos: rl.Vector2, mouse_state: MouseState) void {
        switch (mouse_state) {
            MouseState.Pressed => {
                self.down_selected = rl.checkCollisionPointRec(pos, self.rect);
                self.up_selected = false;
            },
            MouseState.Released => {
                self.up_selected = rl.checkCollisionPointRec(pos, self.rect);
            },
            else => {},
        }
        if (rl.checkCollisionPointRec(pos, self.rect)) {
            self.hovered = true;
        } else {
            self.hovered = false;
        }
    }
};
