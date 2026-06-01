const rl = @cImport({
    @cInclude("raylib.h");
});

const iso = @import("iso.zig");
const World = @import("world.zig").World;
const Player = @import("player.zig").Player;
const player_mod = @import("player.zig");

const origin_x: f32 = 400;
const origin_y: f32 = 200;

const TILE_SRC: f32 = 32; // source tile size in spritesheet
const TILE_DST: f32 = 64; // rendered tile size (2x scale)
const SHEET_COLS: f32 = 11;

var player_texture: rl.Texture2D = undefined;
var attack_texture: rl.Texture2D = undefined;
var tile_texture: rl.Texture2D = undefined;

pub fn loadTextures() void {
    player_texture = rl.LoadTexture("assets/Player/idle/Sprite Sheet/idle full sprite sheet (transparent BG).png");
    attack_texture = rl.LoadTexture("assets/Player/attack/Sprite Sheet/attack full sprite sheet (transparent BG).png");
    tile_texture = rl.LoadTexture("assets/isometric tileset/spritesheet.png");
}

pub fn unloadTextures() void {
    rl.UnloadTexture(player_texture);
    rl.UnloadTexture(attack_texture);
    rl.UnloadTexture(tile_texture);
}

fn tileRect(id: u8) rl.Rectangle {
    const i: f32 = @floatFromInt(id);
    return .{
        .x = @mod(i, SHEET_COLS) * TILE_SRC,
        .y = @floor(i / SHEET_COLS) * TILE_SRC,
        .width = TILE_SRC,
        .height = TILE_SRC,
    };
}

pub fn drawWorld(world: *const World) void {
    for (world.tiles, 0..) |row, y| {
        for (row, 0..) |tile_id, x| {
            const p = iso.gridToScreen(@floatFromInt(x), @floatFromInt(y));

            const src = tileRect(tile_id);
            // dest: left edge = pos.x - half tile width, top = pos.y (diamond apex)
            const dst = rl.Rectangle{
                .x = p.x + origin_x - TILE_DST / 2,
                .y = p.y + origin_y,
                .width = TILE_DST,
                .height = TILE_DST,
            };

            rl.DrawTexturePro(tile_texture, src, dst, .{ .x = 0, .y = 0 }, 0, rl.WHITE);
        }
    }
}

const PLAYER_SCALE: f32 = 2.0;

pub fn drawPlayer(player: *const Player) void {
    const p = iso.gridToScreen(player.x, player.y);
    const row: f32 = @floatFromInt(@intFromEnum(player.direction));

    const src: rl.Rectangle, const fw: f32, const fh: f32, const tex: rl.Texture2D =
        if (player.anim_state == .attacking) .{
            .{
                .x = @as(f32, @floatFromInt(player.attack_frame)) * player_mod.ATTACK_FRAME_W,
                .y = row * player_mod.ATTACK_FRAME_H,
                .width = player_mod.ATTACK_FRAME_W,
                .height = player_mod.ATTACK_FRAME_H,
            },
            player_mod.ATTACK_FRAME_W,
            player_mod.ATTACK_FRAME_H,
            attack_texture,
        } else .{
            .{
                .x = @as(f32, @floatFromInt(player.frame)) * player_mod.FRAME_W,
                .y = row * player_mod.FRAME_H,
                .width = player_mod.FRAME_W,
                .height = player_mod.FRAME_H,
            },
            player_mod.FRAME_W,
            player_mod.FRAME_H,
            player_texture,
        };

    const dw = fw * PLAYER_SCALE;
    const dh = fh * PLAYER_SCALE;
    const dst = rl.Rectangle{
        .x = p.x + origin_x - dw / 2,
        .y = p.y + origin_y + iso.TILE_H / 2 - dh,
        .width = dw,
        .height = dh,
    };

    rl.DrawTexturePro(tex, src, dst, .{ .x = 0, .y = 0 }, 0, rl.WHITE);
}
