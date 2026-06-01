const rl = @cImport({
    @cInclude("raylib.h");
});

pub const TILE_W: f32 = 64;
pub const TILE_H: f32 = 32;

pub fn gridToScreen(x: f32, y: f32) rl.Vector2 {
    return .{
        .x = (x - y) * TILE_W * 0.5,
        .y = (x + y) * TILE_H * 0.5,
    };
}
