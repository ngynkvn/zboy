const std = @import("std");
const PC: u16 = 0x0000;

const Register = enum { A, B, C, D, E, H, L, HL, ACC };

const LD = struct { from: Register, to: Register };

fn to_reg(loc: u8) Register {
    return switch (loc) {
        0b000 => Register.B,
        0b001 => Register.C,
        0b010 => Register.D,
        0b011 => Register.E,
        0b100 => Register.H,
        0b101 => Register.L,
        0b110 => Register.HL,
        0b111 => Register.ACC,
        else => unreachable,
    };
}

fn LD_INSTR(opcode: u8) LD {
    var x = opcode & 0b00_111_000;
    x = x >> 3;
    const y = opcode & 0b00_000_111;
    return LD{ .from = to_reg(x), .to = to_reg(y) };
}

test "expect ld B, B for opcode 0x40" {
    try std.testing.expectEqual(LD_INSTR(0x40), LD{ .from = Register.B, .to = Register.B });
    try std.testing.expectEqual(LD_INSTR(0x41), LD{ .from = Register.B, .to = Register.C });
    try std.testing.expectEqual(LD_INSTR(0x42), LD{ .from = Register.B, .to = Register.D });
}
