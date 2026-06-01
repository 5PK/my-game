const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");

const my_game = @import("my_game");

const World = @import("world.zig").World;
const Player = @import("player.zig").Player;
const renderer = @import("renderer.zig");

pub fn main() !void {
    rl.initWindow(
        1024,
        768,
        "Isometric Game",
    );

    defer rl.closeWindow();

    rl.setTargetFPS(60);

    renderer.loadTextures();
    defer renderer.unloadTextures();

    var world = World.init();

    var player = Player{
        .x = 4.0,
        .y = 4.0,
    };

    while (!rl.windowShouldClose()) {

        player.update();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        renderer.drawWorld(&world);
        renderer.drawPlayer(&player);
    }}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    try std.testing.fuzz({}, testOne, .{});
}

fn testOne(context: void, smith: *std.testing.Smith) !void {
    _ = context;
    // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!

    const gpa = std.testing.allocator;
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(gpa);
    while (!smith.eos()) switch (smith.value(enum { add_data, dup_data })) {
        .add_data => {
            const slice = try list.addManyAsSlice(gpa, smith.value(u4));
            smith.bytes(slice);
        },
        .dup_data => {
            if (list.items.len == 0) continue;
            if (list.items.len > std.math.maxInt(u32)) return error.SkipZigTest;
            const len = smith.valueRangeAtMost(u32, 1, @min(32, list.items.len));
            const off = smith.valueRangeAtMost(u32, 0, @intCast(list.items.len - len));
            try list.appendSlice(gpa, list.items[off..][0..len]);
            try std.testing.expectEqualSlices(
                u8,
                list.items[off..][0..len],
                list.items[list.items.len - len ..],
            );
        },
    };
}
