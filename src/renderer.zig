const rl = @cImport({
    @cInclude("raylib.h");
});

const iso = @import("iso.zig");
const World = @import("world.zig").World;
const Player = @import("player.zig").Player;
const player_mod = @import("player.zig");

const TILE_SRC: f32 = 32; // source tile size in spritesheet
const TILE_DST: f32 = 64; // rendered tile size (2x scale)
const SHEET_COLS: f32 = 11;

var player_texture: rl.Texture2D = undefined;
var player_walk_texture: rl.Texture2D = undefined;
var attack_texture: rl.Texture2D = undefined;
var tile_texture: rl.Texture2D = undefined;

pub fn loadTextures() void {
    player_texture = rl.LoadTexture("assets/Player/idle/Sprite Sheet/idle full sprite sheet (transparent BG).png");
    player_walk_texture = rl.LoadTexture("assets/Player/walk/Sprite Sheet/walk complete sprite sheet (transparent BG).png");
    attack_texture = rl.LoadTexture("assets/Player/attack/Sprite Sheet/attack full sprite sheet (transparent BG).png");
    tile_texture = rl.LoadTexture("assets/isometric tileset/spritesheet.png");
}

pub fn unloadTextures() void {
    rl.UnloadTexture(player_texture);
    rl.UnloadTexture(player_walk_texture);
    rl.UnloadTexture(attack_texture);
    rl.UnloadTexture(tile_texture);
}

fn cameraAnchor() rl.Vector2 {
    return .{
        .x = @as(f32, @floatFromInt(rl.GetScreenWidth())) * 0.5,
        .y = @as(f32, @floatFromInt(rl.GetScreenHeight())) * 0.5,
    };
}

fn worldToCameraScreen(x: f32, y: f32, camera_target: *const Player) rl.Vector2 {
    const p = iso.gridToScreen(x, y);
    const target = iso.gridToScreen(camera_target.x, camera_target.y);
    const anchor = cameraAnchor();

    return .{
        .x = p.x - target.x + anchor.x,
        .y = p.y - target.y + anchor.y,
    };
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

pub fn drawWorld(world: *const World, camera_target: *const Player) void {
    for (world.tiles, 0..) |row, y| {
        for (row, 0..) |tile_id, x| {
            const p = worldToCameraScreen(@floatFromInt(x), @floatFromInt(y), camera_target);

            const src = tileRect(tile_id);
            // dest: left edge = pos.x - half tile width, top = pos.y (diamond apex)
            const dst = rl.Rectangle{
                .x = p.x - TILE_DST / 2,
                .y = p.y,
                .width = TILE_DST,
                .height = TILE_DST,
            };

            rl.DrawTexturePro(tile_texture, src, dst, .{ .x = 0, .y = 0 }, 0, rl.WHITE);
        }
    }
}

const PLAYER_SCALE: f32 = 2.0;

fn movementRow(dir: player_mod.Direction) f32 {
    const row: i32 = switch (dir) {
        .NW => 0,
        .W => 1,
        .SW => 2,
        .S => 3,
        .SE => 4,
        .E => 5,
        .NE => 6,
        .N => 7,
    };
    return @floatFromInt(row);
}

fn attackRow(dir: player_mod.Direction) f32 {
    const row: i32 = switch (dir) {
        .N => 0,
        .NW => 1,
        .W => 2,
        .SW => 3,
        .S => 4,
        .SE => 5,
        .E => 6,
        .NE => 7,
    };
    return @floatFromInt(row);
}

pub fn drawPlayer(player: *const Player) void {
    const p = cameraAnchor();
    const move_row = movementRow(player.direction);
    const attack_y_offset = (player_mod.ATTACK_FRAME_H - player_mod.FRAME_H) * PLAYER_SCALE * 0.5;

    const src: rl.Rectangle, const fw: f32, const fh: f32, const tex: rl.Texture2D, const y_offset: f32 =
        if (player.anim_state == .attacking) .{
            .{
                .x = @as(f32, @floatFromInt(player.attack_frame)) * player_mod.ATTACK_FRAME_W,
                .y = attackRow(player.direction) * player_mod.ATTACK_FRAME_H,
                .width = player_mod.ATTACK_FRAME_W,
                .height = player_mod.ATTACK_FRAME_H,
            },
            player_mod.ATTACK_FRAME_W,
            player_mod.ATTACK_FRAME_H,
            attack_texture,
            attack_y_offset,
        } else if (player.anim_state == .moving) .{
            .{
                .x = @as(f32, @floatFromInt(player.frame)) * player_mod.FRAME_W,
                .y = move_row * player_mod.FRAME_H,
                .width = player_mod.FRAME_W,
                .height = player_mod.FRAME_H,
            },
            player_mod.FRAME_W,
            player_mod.FRAME_H,
            player_walk_texture,
            0,
        } else .{
            .{
                .x = @as(f32, @floatFromInt(player.frame)) * player_mod.FRAME_W,
                .y = move_row * player_mod.FRAME_H,
                .width = player_mod.FRAME_W,
                .height = player_mod.FRAME_H,
            },
            player_mod.FRAME_W,
            player_mod.FRAME_H,
            player_texture,
            0,
        };

    const dw = fw * PLAYER_SCALE;
    const dh = fh * PLAYER_SCALE;
    const dst = rl.Rectangle{
        .x = p.x - dw / 2,
        .y = p.y + iso.TILE_H / 2 - dh + y_offset - player.jumpOffsetPixels(),
        .width = dw,
        .height = dh,
    };

    rl.DrawTexturePro(tex, src, dst, .{ .x = 0, .y = 0 }, 0, rl.WHITE);
}
