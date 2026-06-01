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

pub const AnimState = enum { moving, idle, attacking };

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

    const ACCEL: f32 = 0.02;
    const FRICTION: f32 = 0.80;
    const FRAME_SPEED: f32 = 0.04;
    const ATTACK_FRAME_SPEED: f32 = 0.07;

    pub fn update(self: *Player) void {
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

    fn directionFromVelocity(vx: f32, vy: f32) Direction {
        if (vx >= 0 and vy < 0) return .NE;
        if (vx > 0 and vy >= 0) return .SE;
        if (vx <= 0 and vy > 0) return .SW;
        return .NW;
    }
};
