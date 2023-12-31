const r = @cImport(@cInclude("raylib.h"));
pub fn main() !void {
    r.InitWindow(960, 540, "My Window Name");
    r.SetTargetFPS(144);
    defer r.CloseWindow();

    while (!r.WindowShouldClose()) {
        r.BeginDrawing();
        r.ClearBackground(r.BLACK);
        r.EndDrawing();
    }
}