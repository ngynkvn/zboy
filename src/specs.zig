const std = @import("std");

const CPU_FREQ_MHZ = 4.194304; // MHz
const WORK_RAM_KB = 8;
const VIDEO_RAM_KB = 8;
const RESOLUTION_W = 160;
const RESOLUTION_H = 144;

const MAX_SPRITES = 40;
const MAX_SPRITES_LINE = 10;

const SPRITE_W = 8;
const SPRITE_H1 = 8;
const SPRITE_H2 = 16;

const H_SYNC_KHZ = 9.198; // KHz
const V_SYNC_HZ = 59.73; // Hz

const SOUND_CHANNEL_COUNT = 4;

const Memory = struct {
    bytes: [0xFFFF + 1]u8,
    pub fn get(self: Memory, addr: u16) u8 {
        return self.bytes[addr];
    }
    pub fn set(self: *Memory, addr: u16, v: u8) void {
        self.bytes[addr] = v;
    }
};

fn init_memory() Memory {
    return Memory{ .bytes = [_]u8{0} ** 65536 };
}

const JoypadInput = enum { UP, DOWN, LEFT, RIGHT, B, A, START, SELECT };

pub const VBLNK: u8 = 0b00000001;
pub const LCDST: u8 = 0b00000010;
pub const TIMER: u8 = 0b00000100;
pub const SRIAL: u8 = 0b00001000;
pub const JOYPD: u8 = 0b00010000;

const JOYPAD_ADDR: u16 = 0xFF00;
const JOYPAD_INTERRUPT: u8 = 0b1000;
const JoypadReadError = error{ OutOfBounds, ButtonMuxIssue };
fn read_joypad(m: Memory) JoypadInput {
    var input = m.bytes[JOYPAD_ADDR];
    const BUTTON_MASK = 0b00_11_0000;
    const INPUT_MASK = 0b00_00_1111;

    switch (input & BUTTON_MASK) {
        // Select actions button
        0b00_01_0000 => {
            return switch (m.bytes[JOYPAD_ADDR] & INPUT_MASK) {
                0b0000_1000 => JoypadInput.START,
                0b0000_0100 => JoypadInput.SELECT,
                0b0000_0010 => JoypadInput.B,
                0b0000_0001 => JoypadInput.A,
                else => {
                    std.log.err("err {}", .{m.bytes[JOYPAD_ADDR]});
                    unreachable;
                },
            };
        },
        // Select directions button
        0b00_10_0000 => {
            return switch (m.bytes[JOYPAD_ADDR] & INPUT_MASK) {
                0b0000_1000 => JoypadInput.DOWN,
                0b0000_0100 => JoypadInput.UP,
                0b0000_0010 => JoypadInput.LEFT,
                0b0000_0001 => JoypadInput.RIGHT,
                else => {
                    std.log.err("err {}", .{m.bytes[JOYPAD_ADDR]});
                    unreachable;
                },
            };
        },
        else => {
            std.log.err("err {}", .{m.bytes[JOYPAD_ADDR]});
            unreachable;
        },
    }
}

fn write_joypad(ji: JoypadInput, m: *Memory) void {
    switch (ji) {
        JoypadInput.DOWN, JoypadInput.START => m.bytes[JOYPAD_ADDR] |= 0b00_00_1000,
        JoypadInput.UP, JoypadInput.SELECT => m.bytes[JOYPAD_ADDR] |= 0b00_00_0100,
        JoypadInput.LEFT, JoypadInput.B => m.bytes[JOYPAD_ADDR] |= 0b00_00_0010,
        JoypadInput.RIGHT, JoypadInput.A => m.bytes[JOYPAD_ADDR] |= 0b00_00_0001,
    }
}

test "expect memory to read and write joypad" {
    var mem = init_memory();
    // Directions
    mem.bytes[JOYPAD_ADDR] ^= mem.bytes[JOYPAD_ADDR];
    mem.bytes[JOYPAD_ADDR] |= 0b00_10_0000;
    write_joypad(JoypadInput.RIGHT, &mem);
    try std.testing.expectEqual(JoypadInput.RIGHT, read_joypad(mem));

    mem.bytes[JOYPAD_ADDR] ^= mem.bytes[JOYPAD_ADDR];
    mem.bytes[JOYPAD_ADDR] |= 0b00_10_0000;
    write_joypad(JoypadInput.LEFT, &mem);
    try std.testing.expectEqual(JoypadInput.LEFT, read_joypad(mem));

    mem.bytes[JOYPAD_ADDR] ^= mem.bytes[JOYPAD_ADDR];
    mem.bytes[JOYPAD_ADDR] |= 0b00_10_0000;
    write_joypad(JoypadInput.UP, &mem);
    try std.testing.expectEqual(JoypadInput.UP, read_joypad(mem));

    mem.bytes[JOYPAD_ADDR] ^= mem.bytes[JOYPAD_ADDR];
    mem.bytes[JOYPAD_ADDR] |= 0b00_10_0000;
    write_joypad(JoypadInput.DOWN, &mem);
    try std.testing.expectEqual(JoypadInput.DOWN, read_joypad(mem));
}
