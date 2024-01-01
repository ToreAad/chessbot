const std = @import("std");
const r = @cImport({
    @cInclude("raylib.h");
    @cInclude("raygui.h");
});

pub fn main() !void {
    r.InitWindow(960, 540, "My Window Name");
    r.SetTargetFPS(144);
    defer r.CloseWindow();

    while (!r.WindowShouldClose()) {
        r.BeginDrawing();
        r.ClearBackground(r.RED);

        // Draw the button
        const rect = r.Rectangle{ .x = 10.0, .y = 10.0, .width = 200.0, .height = 40.0 };
        const i = r.GuiButton(rect, "Hello, World!");
        if (i > 0) {
            // Button was clicked, you can add code here to handle the button click
            std.debug.print("Button clicked!", .{}); // Print to the console
        }

        r.EndDrawing();
    }
}
