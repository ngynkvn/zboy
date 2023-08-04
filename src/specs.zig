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

const Memory = struct { bytes: [0xFFFF + 1]u8 };

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
    _ = input;
    const BUTTON_MASK = 0b00_11_0000;
    const INPUT_MASK = 0b00_00_1111;

    switch (m.bytes[JOYPAD_ADDR] & BUTTON_MASK) {
        // Select actions button
        0b00_01_0000 => {
            return switch (m.bytes[JOYPAD_ADDR] & INPUT_MASK) {
                0b0000_1000 => JoypadInput.START,
                0b0000_0100 => JoypadInput.SELECT,
                0b0000_0010 => JoypadInput.B,
                0b0000_0001 => JoypadInput.A,
                else => unreachable,
            };
        },
        // Select directions button
        0b00_10_0000 => {
            return switch (m.bytes[JOYPAD_ADDR] & INPUT_MASK) {
                0b0000_1000 => JoypadInput.DOWN,
                0b0000_0100 => JoypadInput.UP,
                0b0000_0010 => JoypadInput.LEFT,
                0b0000_0001 => JoypadInput.RIGHT,
                else => unreachable,
            };
        },
        else => unreachable,
    }
}

fn write_joypad(ji: JoypadInput, m: *Memory) void {
    switch (ji) {
        JoypadInput.DOWN, JoypadInput.START => m.bytes[JOYPAD_ADDR] &= 0b0000_1000,
        JoypadInput.UP, JoypadInput.SELECT => m.bytes[JOYPAD_ADDR] &= 0b0000_0100,
        JoypadInput.LEFT, JoypadInput.B => m.bytes[JOYPAD_ADDR] &= 0b0000_0010,
        JoypadInput.RIGHT, JoypadInput.A => m.bytes[JOYPAD_ADDR] &= 0b0000_0001,
    }
}

test "expect memory to read and write joypad" {
    var mem = init_memory();
    // Directions
    mem.bytes[JOYPAD_ADDR] ^= mem.bytes[JOYPAD_ADDR];
    mem.bytes[JOYPAD_ADDR] |= 0b00_10_0000;
    write_joypad(JoypadInput.A, &mem);
    try std.testing.expectEqual(JoypadInput.A, read_joypad(mem));

    // Zero out
    mem.bytes[JOYPAD_ADDR] ^= mem.bytes[JOYPAD_ADDR];
    mem.bytes[JOYPAD_ADDR] |= 0b00_10_0000;
    write_joypad(JoypadInput.B, &mem);
    try std.testing.expectEqual(JoypadInput.B, read_joypad(mem));
}
