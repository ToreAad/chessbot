const rl = @import("raylib");

fn draw_square(x: i32, y: i32, size: i32, color: rl.Color) void {
    rl.drawRectangle(x, y, size, size, color);
}

pub fn draw_board(x_offset: i32, y_offset: i32, square_size: i32) void {
    var file: u8 = 0;
    while (file < 8) : (file += 1) {
        var rank: u8 = 0;
        while (rank < 8) : (rank += 1) {
            const x = file * square_size;
            const y = rank * square_size;
            const color = if ((file + rank) % 2 == 0) rl.Color.white else rl.Color.dark_gray;
            draw_square(x_offset + x, y_offset + y, square_size, color);
        }
    }
}
