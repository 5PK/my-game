pub const WIDTH = 16;
pub const HEIGHT = 16;

// tile IDs from spritesheet (11 columns, 32x32 each)
// 0  = dirt       22 = grass      33 = bush
// 55 = rock       99 = water      100 = water variant
pub const DIRT:  u8 = 0;
pub const GRASS: u8 = 22;
pub const BUSH:  u8 = 33;
pub const ROCK:  u8 = 55;
pub const WATER: u8 = 99;

pub const World = struct {
    tiles: [HEIGHT][WIDTH]u8,

    pub fn init() World {
        // G=grass, D=dirt path, W=water, B=bush, R=rock
        const G = GRASS;
        const D = DIRT;
        const W = WATER;
        const B = BUSH;
        const R = ROCK;
        return .{ .tiles = [HEIGHT][WIDTH]u8{
            [_]u8{ W, W, W, W, G, G, G, G, G, G, G, G, G, G, G, G },
            [_]u8{ W, W, W, G, G, B, G, G, G, G, G, G, G, B, G, G },
            [_]u8{ W, W, G, G, G, G, G, D, D, D, D, G, G, G, G, G },
            [_]u8{ W, G, G, B, G, G, G, D, G, G, D, G, G, G, G, G },
            [_]u8{ G, G, G, G, G, G, G, D, G, G, D, G, B, G, G, G },
            [_]u8{ G, B, G, G, G, G, G, D, G, G, D, G, G, G, G, G },
            [_]u8{ G, G, G, G, R, G, G, D, G, G, D, G, G, G, R, G },
            [_]u8{ G, G, G, G, G, G, G, D, G, G, D, G, G, G, G, G },
            [_]u8{ G, G, G, G, G, G, G, D, D, D, D, G, G, G, G, G },
            [_]u8{ G, G, R, G, G, G, G, G, G, G, G, G, G, G, G, G },
            [_]u8{ G, G, G, G, G, B, G, G, G, G, G, B, G, G, G, G },
            [_]u8{ G, G, G, G, G, G, G, G, G, G, G, G, G, G, G, G },
            [_]u8{ G, G, G, G, G, G, G, G, G, G, G, G, R, G, G, G },
            [_]u8{ G, B, G, G, G, G, G, G, G, G, G, G, G, G, G, G },
            [_]u8{ G, G, G, G, G, G, G, G, G, G, G, G, G, G, G, G },
            [_]u8{ G, G, G, G, G, G, G, G, G, G, G, G, G, G, G, G },
        }};
    }
};
