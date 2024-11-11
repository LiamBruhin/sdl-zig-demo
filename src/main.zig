const std = @import("std");
const c = @import("c.zig");
const panic = std.debug.panic;

const window_width = 1000;
const window_height = 1000;

var running: bool = false;

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

    const Renderer = c.SDL_CreateRenderer(screen, -1, c.SDL_RENDERER_SOFTWARE);

    running = true;

    while (running) {
        pollEvents();
        _ = c.SDL_SetRenderDrawColor(Renderer, 136, 138, 140, 255);
        _ = c.SDL_RenderClear(Renderer);
        c.SDL_RenderPresent(Renderer);
    }
}

pub fn pollEvents() void {
    var event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&event) != 0) {
        switch (event.type) {
            c.SDL_KEYDOWN => {
                switch (event.key.keysym.scancode) {
                    c.SDL_SCANCODE_ESCAPE => {
                        running = false;
                    },
                    else => {},
                }
            },
            c.SDL_QUIT => {
                running = false;
            },
            else => {},
        }
    }
}
