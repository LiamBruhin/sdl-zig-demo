const std = @import("std");
const c = @import("c.zig");
const panic = std.debug.panic;
const print = std.debug.print;

const vec2D = struct {
    x: f64,
    y: f64,
    fn normalize(self: *vec2D) void {
        if ((self.x * self.x + self.y * self.y) != 0) {
            const magnitude = @sqrt(self.x * self.x + self.y * self.y);
            self.x /= magnitude;
            self.y /= magnitude;
        }
    }
};

const window_width: i32 = 1000;
const window_height: i32 = 1000;
const padding = 5;
const playerSize: f64 = 30;

const speed = 10;

var pos = vec2D{ .x = 500, .y = 500 };
var vel = vec2D{ .x = 0, .y = 0 };

var map = [10][10]i8{
    [_]i8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    [_]i8{ 1, 0, 1, 0, 0, 0, 0, 0, 0, 1 },
    [_]i8{ 1, 0, 1, 0, 0, 0, 0, 0, 0, 1 },
    [_]i8{ 1, 0, 1, 0, 0, 0, 0, 0, 0, 1 },
    [_]i8{ 1, 0, 1, 0, 0, 0, 0, 0, 0, 1 },
    [_]i8{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
    [_]i8{ 1, 0, 0, 0, 0, 0, 1, 1, 0, 1 },
    [_]i8{ 1, 0, 0, 0, 0, 0, 1, 1, 0, 1 },
    [_]i8{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
    [_]i8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
};

const blockSize = window_width / map.len;

pub fn main() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        panic("SDL_Init failed: {s}\n", .{c.SDL_GetError()});
    }
    defer c.SDL_Quit();

    const screen = c.SDL_CreateWindow(
        "testWindow",
        c.SDL_WINDOWPOS_UNDEFINED,
        c.SDL_WINDOWPOS_UNDEFINED,
        window_width,
        window_height,
        0,
    );
    defer c.SDL_DestroyWindow(screen);

    const Renderer: ?*c.SDL_Renderer = c.SDL_CreateRenderer(screen, -1, c.SDL_RENDERER_ACCELERATED) orelse {
        panic("SDL Failed to create a Renderer", .{});
    };

    var running: bool = true;

    while (running) {
        pollEvents(&running);

        const col: usize = @intFromFloat(@ceil(pos.x / blockSize));
        const colF: usize = @intFromFloat(@floor(pos.x / blockSize));
        const row: usize = @intFromFloat(@floor(pos.y / blockSize));
        const rowC: usize = @intFromFloat(@ceil(pos.y / blockSize));

        if (col < map.len and col > 0) {
            // NOTE: right case
            var wallPos: f64 = @floatFromInt(blockSize * col);
            var playerEdge: f64 = pos.x + (playerSize / 2);
            if ((map[row][col] == 1) and (playerEdge > wallPos)) {
                pos.x = wallPos - (playerSize / 2);
            }

            // NOTE: left case
            wallPos = @floatFromInt(blockSize * (col - 1));
            playerEdge = pos.x - (playerSize / 2);
            if ((map[row][col - 2] == 1) and (playerEdge < wallPos)) {
                pos.x = wallPos + (playerSize / 2);
            }

            //NOTE: Down
            wallPos = @floatFromInt(blockSize * (rowC));
            playerEdge = pos.y + (playerSize / 2);
            if ((map[rowC][colF] == 1) and (playerEdge > wallPos)) {
                pos.y = wallPos - (playerSize / 2);
            }

            //NOTE: Up
            wallPos = @floatFromInt(blockSize * (rowC - 1));
            playerEdge = pos.y - (playerSize / 2);
            if ((map[rowC - 2][colF] == 1) and (playerEdge < wallPos)) {
                pos.y = wallPos + (playerSize / 2);
            }
        }

        vel.normalize();
        pos.x += vel.x * speed;
        pos.y += vel.y * speed;

        render(Renderer);
    }
}

pub fn render(Renderer: ?*c.SDL_Renderer) void {
    _ = c.SDL_SetRenderDrawColor(Renderer, 0, 0, 0, 255);
    _ = c.SDL_RenderClear(Renderer);
    drawMap(Renderer);
    drawPlayer(Renderer);
    c.SDL_RenderPresent(Renderer);
}

pub fn pollEvents(running: *bool) void {
    var event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&event) != 0) {
        switch (event.type) {
            c.SDL_KEYDOWN => {
                switch (event.key.keysym.scancode) {
                    c.SDL_SCANCODE_ESCAPE => {
                        running.* = false;
                    },
                    c.SDL_SCANCODE_W => {
                        vel.y = -1;
                    },
                    c.SDL_SCANCODE_S => {
                        vel.y = 1;
                    },
                    c.SDL_SCANCODE_A => {
                        vel.x = -1;
                    },
                    c.SDL_SCANCODE_D => {
                        vel.x = 1;
                    },
                    else => {
                        vel.x = 0;
                        vel.y = 0;
                    },
                }
            },
            c.SDL_KEYUP => {
                switch (event.key.keysym.scancode) {
                    c.SDL_SCANCODE_W => {
                        vel.y = 0;
                    },
                    c.SDL_SCANCODE_S => {
                        vel.y = 0;
                    },
                    c.SDL_SCANCODE_A => {
                        vel.x = 0;
                    },
                    c.SDL_SCANCODE_D => {
                        vel.x = 0;
                    },
                    else => {},
                }
            },
            c.SDL_QUIT => {
                running.* = false;
            },
            else => {},
        }
    }
}

pub fn drawMap(Renderer: ?*c.SDL_Renderer) void {
    for (map, 0..) |row, y| {
        for (row, 0..) |block, x| {
            const rect = c.SDL_Rect{
                .y = @as(c_int, @intCast((window_width / 10) * y)) + padding,
                .x = @as(c_int, @intCast((window_height / 10) * x)) + padding,
                .h = @as(c_int, @intCast((window_height / 10))) - padding,
                .w = @as(c_int, @intCast((window_width / 10))) - padding,
            };
            if (block == 1) {
                _ = c.SDL_SetRenderDrawColor(Renderer, 255, 255, 255, 255);
            } else {
                _ = c.SDL_SetRenderDrawColor(Renderer, 136, 138, 140, 255);
            }
            _ = c.SDL_RenderFillRect(Renderer, &rect);
        }
    }
}

pub fn drawPlayer(Renderer: ?*c.SDL_Renderer) void {
    _ = c.SDL_SetRenderDrawColor(Renderer, 235, 79, 52, 255);
    const player = c.SDL_Rect{
        .y = @as(c_int, @intFromFloat(pos.y - playerSize / 2)),
        .x = @as(c_int, @intFromFloat(pos.x - playerSize / 2)),
        .h = @as(c_int, @intFromFloat(playerSize)),
        .w = @as(c_int, @intFromFloat(playerSize)),
    };
    _ = c.SDL_RenderFillRect(Renderer, &player);
    _ = c.SDL_SetRenderDrawColor(Renderer, 0, 0, 255, 255);
    _ = c.SDL_RenderDrawPoint(Renderer, @as(c_int, @intFromFloat(pos.x)), @as(c_int, @intFromFloat(pos.y)));
}
