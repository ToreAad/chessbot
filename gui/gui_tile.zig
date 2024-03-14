const std = @import("std");
const rl = @import("raylib");
const chess = @import("chess");

pub const GuiTile = struct {
    rect: rl.Rectangle,
    color: rl.Color,
    hovered: bool,
    selected: bool,

    pub fn draw(self: *const GuiTile) void {
        rl.drawRectangleRec(self.rect, self.color);
        if (self.hovered) {
            rl.drawRectangleLinesEx(self.rect, 4.0, rl.Color.blue);
        }
        if (self.selected) {
            rl.drawRectangleLinesEx(self.rect, 4.0, rl.Color.red);
        }
    }

    pub fn update(self: *GuiTile, pos: rl.Vector2, clicked: bool) void {
        if (rl.checkCollisionPointRec(pos, self.rect)) {
            self.hovered = true;
            if (clicked) {
                self.selected = !self.selected;
            }
        } else {
            self.hovered = false;
            if (clicked) {
                self.selected = false;
            }
        }
    }
};
