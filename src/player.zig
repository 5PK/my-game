const std = @import("std");

const rl = @cImport({
    @cInclude("raylib.h");
});

pub const FRAME_W: f32 = 64;
pub const FRAME_H: f32 = 64;
pub const FRAME_COUNT: i32 = 12;

pub const ATTACK_FRAME_W: f32 = 96;
pub const ATTACK_FRAME_H: f32 = 96;
pub const ATTACK_FRAME_COUNT: i32 = 7;

pub const Direction = enum(i32) {
    S = 0, SW = 1, W = 2, NW = 3, N = 4, NE = 5, E = 6, SE = 7,
};

pub const AnimState = enum { moving, idle, attacking, jumping };

pub const Player = struct {
    x: f32,
    y: f32,
    vx: f32 = 0,
    vy: f32 = 0,
    frame: i32 = 0,
    frame_timer: f32 = 0,
    direction: Direction = .S,
    anim_state: AnimState = .idle,
    attack_frame: i32 = 0,
    attack_timer: f32 = 0,
    jump_timer: f32 = 0,
    jump_start_x: f32 = 0,
    jump_start_y: f32 = 0,
    jump_target_x: f32 = 0,
    jump_target_y: f32 = 0,

    const ACCEL: f32 = 0.02;
    const FRICTION: f32 = 0.80;
    const FRAME_SPEED: f32 = 0.04;
    const ATTACK_FRAME_SPEED: f32 = 0.07;
    const JUMP_DURATION: f32 = 0.36;
    const JUMP_DISTANCE: f32 = 2.0;
    const JUMP_HEIGHT: f32 = 34.0;
    const MAP_MIN_EDGE_INSET: f32 = 1.0;
    const MAP_MAX_EDGE_EXTENSION: f32 = 2.0;

    pub fn update(self: *Player) void {
        if (self.anim_state == .jumping) {
            self.jump_timer += rl.GetFrameTime();
            const t = @min(self.jump_timer / JUMP_DURATION, 1.0);

            self.x = self.jump_start_x + (self.jump_target_x - self.jump_start_x) * t;
            self.y = self.jump_start_y + (self.jump_target_y - self.jump_start_y) * t;

            if (t >= 1.0) {
                self.anim_state = .idle;
                self.jump_timer = 0;
            }
            return;
        }

        if (self.anim_state == .attacking) {
            self.attack_timer += rl.GetFrameTime();
            if (self.attack_timer >= ATTACK_FRAME_SPEED) {
                self.attack_timer -= ATTACK_FRAME_SPEED;
                self.attack_frame += 1;
                if (self.attack_frame >= ATTACK_FRAME_COUNT) {
                    self.attack_frame = 0;
                    self.anim_state = .idle;
                }
            }
            // damp velocity so player slides to a stop during attack
            self.vx *= FRICTION;
            self.vy *= FRICTION;
            self.x += self.vx;
            self.y += self.vy;
            return;
        }

        if (rl.IsKeyPressed(rl.KEY_K)) {
            self.startJump();
            return;
        }

        if (rl.IsKeyDown(rl.KEY_E)) { 
            self.anim_state = .moving;
            self.vx -= ACCEL; self.vy -= ACCEL; 
        }
        if (rl.IsKeyDown(rl.KEY_D)) { 
            self.anim_state = .moving;
            self.vx += ACCEL; self.vy += ACCEL; 
        }
        if (rl.IsKeyDown(rl.KEY_F)) {
            self.anim_state = .moving;
            self.vx += ACCEL; self.vy -= ACCEL; 
        }
        if (rl.IsKeyDown(rl.KEY_S)) {
            self.anim_state = .moving;
            self.vx -= ACCEL; self.vy += ACCEL; 
        }

        self.vx *= FRICTION;
        self.vy *= FRICTION;
        self.x += self.vx;
        self.y += self.vy;

        const speed = @sqrt(self.vx * self.vx + self.vy * self.vy);
        if (speed > 0.02) {
            self.direction = directionFromVelocity(self.vx, self.vy);
            self.frame_timer += rl.GetFrameTime();
            if (self.frame_timer >= FRAME_SPEED) {
                self.frame_timer -= FRAME_SPEED;
                self.frame = @mod(self.frame + 1, FRAME_COUNT);
            }
        } else {
            self.frame = 0;
            self.frame_timer = 0;
        }

        if (rl.IsKeyPressed(rl.KEY_J)) {
            self.anim_state = .attacking;
            self.attack_frame = 0;
            self.attack_timer = 0;
        }
    }

    pub fn jumpOffsetPixels(self: *const Player) f32 {
        if (self.anim_state != .jumping) return 0;

        const t = @min(self.jump_timer / JUMP_DURATION, 1.0);
        return @sin(t * std.math.pi) * JUMP_HEIGHT;
    }

    pub fn clampToMap(self: *Player, width: usize, height: usize) void {
        const min_x = if (width > 2) MAP_MIN_EDGE_INSET else 0;
        const min_y = if (height > 2) MAP_MIN_EDGE_INSET else 0;
        const max_x = if (width > 0) @as(f32, @floatFromInt(width - 1)) + MAP_MAX_EDGE_EXTENSION else 0;
        const max_y = if (height > 0) @as(f32, @floatFromInt(height - 1)) + MAP_MAX_EDGE_EXTENSION else 0;

        if (self.x < min_x) {
            self.x = min_x;
            self.vx = 0;
        } else if (self.x > max_x) {
            self.x = max_x;
            self.vx = 0;
        }

        if (self.y < min_y) {
            self.y = min_y;
            self.vy = 0;
        } else if (self.y > max_y) {
            self.y = max_y;
            self.vy = 0;
        }
    }

    fn directionFromVelocity(vx: f32, vy: f32) Direction {
        const sx = vx - vy;
        const sy = vx + vy;
        const ax = @abs(sx);
        const ay = @abs(sy);

        if (ay > ax * 2.0) {
            return if (sy < 0) .N else .S;
        }

        if (ax > ay * 2.0) {
            return if (sx < 0) .W else .E;
        }

        if (sx >= 0 and sy < 0) return .NE;
        if (sx > 0 and sy >= 0) return .SE;
        if (sx <= 0 and sy > 0) return .SW;
        return .NW;
    }

    fn startJump(self: *Player) void {
        const d = jumpVector(self.direction);

        self.anim_state = .jumping;
        self.jump_timer = 0;
        self.jump_start_x = self.x;
        self.jump_start_y = self.y;
        self.jump_target_x = self.x + d.x * JUMP_DISTANCE;
        self.jump_target_y = self.y + d.y * JUMP_DISTANCE;
        self.vx = 0;
        self.vy = 0;
        self.frame = 0;
        self.frame_timer = 0;
    }

    fn jumpVector(dir: Direction) rl.Vector2 {
        return switch (dir) {
            .N => .{ .x = -0.5, .y = -0.5 },
            .S => .{ .x = 0.5, .y = 0.5 },
            .E => .{ .x = 0.5, .y = -0.5 },
            .W => .{ .x = -0.5, .y = 0.5 },
            .NE => .{ .x = 0, .y = -1 },
            .SE => .{ .x = 1, .y = 0 },
            .SW => .{ .x = 0, .y = 1 },
            .NW => .{ .x = -1, .y = 0 },
        };
    }
};
