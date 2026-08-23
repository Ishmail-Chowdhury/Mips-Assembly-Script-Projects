#!/usr/bin/env python3
"""Assemble the repository's MIPS subset and emit Quartus-friendly memory files."""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
from dataclasses import dataclass


REGISTER_ALIASES = {
    "$zero": 0,
    "$at": 1,
    "$v0": 2,
    "$v1": 3,
    "$a0": 4,
    "$a1": 5,
    "$a2": 6,
    "$a3": 7,
    "$t0": 8,
    "$t1": 9,
    "$t2": 10,
    "$t3": 11,
    "$t4": 12,
    "$t5": 13,
    "$t6": 14,
    "$t7": 15,
    "$s0": 16,
    "$s1": 17,
    "$s2": 18,
    "$s3": 19,
    "$s4": 20,
    "$s5": 21,
    "$s6": 22,
    "$s7": 23,
    "$t8": 24,
    "$t9": 25,
    "$k0": 26,
    "$k1": 27,
    "$gp": 28,
    "$sp": 29,
    "$fp": 30,
    "$ra": 31,
}

REGISTER_ALIASES.update({name[1:]: value for name, value in list(REGISTER_ALIASES.items())})

LABEL_PATTERN = re.compile(r"^([A-Za-z_.$][A-Za-z0-9_.$+\-]*):")
MEMORY_OPERAND_PATTERN = re.compile(r"^\s*([^()]+)\((\$[A-Za-z0-9]+)\)\s*$")

R_TYPE_FUNCTS = {
    "add": 0x20,
    "sub": 0x22,
    "and": 0x24,
    "or": 0x25,
    "xor": 0x26,
    "nor": 0x27,
    "slt": 0x2A,
    "sll": 0x00,
    "srl": 0x02,
    "sra": 0x03,
    "srlv": 0x06,
    "jr": 0x08,
}

I_TYPE_OPCODES = {
    "addi": 0x08,
    "andi": 0x0C,
    "ori": 0x0D,
    "lui": 0x0F,
    "lw": 0x23,
    "sw": 0x2B,
    "beq": 0x04,
    "bne": 0x05,
}

J_TYPE_OPCODES = {
    "j": 0x02,
    "jal": 0x03,
}


@dataclass
class SourceLine:
    path: pathlib.Path
    line_number: int
    text: str
    address: int


class AssemblyError(Exception):
    pass


def sanitize_stem(path: pathlib.Path) -> str:
    return re.sub(r"[^A-Za-z0-9]+", "_", path.stem).strip("_").lower()


def parse_register(token: str) -> int:
    token = token.strip()
    lowered = token.lower()
    if lowered in REGISTER_ALIASES:
        return REGISTER_ALIASES[lowered]
    if lowered.startswith("$") and lowered[1:].isdigit():
        value = int(lowered[1:], 10)
        if 0 <= value <= 31:
            return value
    raise AssemblyError(f"Unsupported register '{token}'")


def parse_immediate(token: str, labels: dict[str, int], current_address: int) -> int:
    token = token.strip()
    if token in labels:
        return labels[token]
    if token.lower().startswith("0x") or token.lower().startswith("-0x"):
        return int(token, 16)
    if token.lower().startswith("0b") or token.lower().startswith("-0b"):
        return int(token, 2)
    return int(token, 10)


def to_u16(value: int, context: str) -> int:
    if not -0x8000 <= value <= 0xFFFF:
        raise AssemblyError(f"{context} immediate {value} is out of 16-bit range")
    return value & 0xFFFF


def encode_r(rs: int, rt: int, rd: int, shamt: int, funct: int) -> int:
    return ((rs & 0x1F) << 21) | ((rt & 0x1F) << 16) | ((rd & 0x1F) << 11) | ((shamt & 0x1F) << 6) | (funct & 0x3F)


def encode_i(opcode: int, rs: int, rt: int, imm: int) -> int:
    return ((opcode & 0x3F) << 26) | ((rs & 0x1F) << 21) | ((rt & 0x1F) << 16) | (imm & 0xFFFF)


def encode_j(opcode: int, target: int) -> int:
    return ((opcode & 0x3F) << 26) | (target & 0x03FFFFFF)


def split_operands(raw: str) -> list[str]:
    if not raw.strip():
        return []
    return [part.strip() for part in raw.split(",")]


def first_pass(path: pathlib.Path) -> tuple[list[SourceLine], dict[str, int]]:
    items: list[SourceLine] = []
    labels: dict[str, int] = {}
    address = 0

    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.split("#", 1)[0].strip()
        if not line:
            continue

        while True:
            match = LABEL_PATTERN.match(line)
            if not match:
                break
            label = match.group(1)
            labels[label] = address
            line = line[match.end():].strip()
            if not line:
                break

        if not line:
            continue

        if line.startswith(".word"):
            values = split_operands(line[5:].strip())
            if not values:
                raise AssemblyError(f"{path}:{line_number}: .word requires at least one value")
            for value in values:
                items.append(SourceLine(path, line_number, f".word {value}", address))
                address += 4
            continue

        items.append(SourceLine(path, line_number, line, address))
        address += 4

    return items, labels


def encode_line(source: SourceLine, labels: dict[str, int]) -> int:
    text = source.text
    if text.startswith(".word"):
        value = parse_immediate(text[5:].strip(), labels, source.address)
        return value & 0xFFFFFFFF

    parts = text.split(None, 1)
    mnemonic = parts[0].lower()
    operands = split_operands(parts[1] if len(parts) > 1 else "")

    if mnemonic in {"add", "sub", "and", "or", "xor", "nor", "slt"}:
        if len(operands) != 3:
            raise AssemblyError(f"{source.path}:{source.line_number}: {mnemonic} expects rd, rs, rt")
        rd = parse_register(operands[0])
        rs = parse_register(operands[1])
        rt = parse_register(operands[2])
        return encode_r(rs, rt, rd, 0, R_TYPE_FUNCTS[mnemonic])

    if mnemonic in {"sll", "srl", "sra"}:
        if len(operands) != 3:
            raise AssemblyError(f"{source.path}:{source.line_number}: {mnemonic} expects rd, rt, shamt")
        rd = parse_register(operands[0])
        rt = parse_register(operands[1])
        shamt = parse_immediate(operands[2], labels, source.address)
        if not 0 <= shamt <= 31:
            raise AssemblyError(f"{source.path}:{source.line_number}: shift amount must be 0..31")
        return encode_r(0, rt, rd, shamt, R_TYPE_FUNCTS[mnemonic])

    if mnemonic == "srlv":
        if len(operands) != 3:
            raise AssemblyError(f"{source.path}:{source.line_number}: srlv expects rd, rt, rs")
        rd = parse_register(operands[0])
        rt = parse_register(operands[1])
        rs = parse_register(operands[2])
        return encode_r(rs, rt, rd, 0, R_TYPE_FUNCTS[mnemonic])

    if mnemonic == "jr":
        if len(operands) != 1:
            raise AssemblyError(f"{source.path}:{source.line_number}: jr expects rs")
        rs = parse_register(operands[0])
        return encode_r(rs, 0, 0, 0, R_TYPE_FUNCTS[mnemonic])

    if mnemonic in {"addi", "andi", "ori"}:
        if len(operands) != 3:
            raise AssemblyError(f"{source.path}:{source.line_number}: {mnemonic} expects rt, rs, imm")
        rt = parse_register(operands[0])
        rs = parse_register(operands[1])
        imm = parse_immediate(operands[2], labels, source.address)
        return encode_i(I_TYPE_OPCODES[mnemonic], rs, rt, to_u16(imm, mnemonic))

    if mnemonic == "lui":
        if len(operands) != 2:
            raise AssemblyError(f"{source.path}:{source.line_number}: lui expects rt, imm")
        rt = parse_register(operands[0])
        imm = parse_immediate(operands[1], labels, source.address)
        return encode_i(I_TYPE_OPCODES[mnemonic], 0, rt, to_u16(imm, mnemonic))

    if mnemonic in {"lw", "sw"}:
        if len(operands) != 2:
            raise AssemblyError(f"{source.path}:{source.line_number}: {mnemonic} expects rt, offset(base)")
        rt = parse_register(operands[0])
        match = MEMORY_OPERAND_PATTERN.match(operands[1])
        if not match:
            raise AssemblyError(f"{source.path}:{source.line_number}: invalid memory operand '{operands[1]}'")
        offset = parse_immediate(match.group(1), labels, source.address)
        base = parse_register(match.group(2))
        return encode_i(I_TYPE_OPCODES[mnemonic], base, rt, to_u16(offset, mnemonic))

    if mnemonic in {"beq", "bne"}:
        if len(operands) != 3:
            raise AssemblyError(f"{source.path}:{source.line_number}: {mnemonic} expects rs, rt, label")
        rs = parse_register(operands[0])
        rt = parse_register(operands[1])
        if operands[2] in labels:
            target = labels[operands[2]]
            offset_bytes = target - (source.address + 4)
            if offset_bytes % 4 != 0:
                raise AssemblyError(f"{source.path}:{source.line_number}: branch target is not word aligned")
            offset = offset_bytes // 4
        else:
            offset = parse_immediate(operands[2], labels, source.address)
        return encode_i(I_TYPE_OPCODES[mnemonic], rs, rt, to_u16(offset, mnemonic))

    if mnemonic in {"j", "jal"}:
        if len(operands) != 1:
            raise AssemblyError(f"{source.path}:{source.line_number}: {mnemonic} expects a target")
        target_address = parse_immediate(operands[0], labels, source.address)
        if target_address % 4 != 0:
            raise AssemblyError(f"{source.path}:{source.line_number}: jump target is not word aligned")
        return encode_j(J_TYPE_OPCODES[mnemonic], target_address >> 2)

    raise AssemblyError(f"{source.path}:{source.line_number}: unsupported instruction '{mnemonic}'")


def assemble(path: pathlib.Path) -> list[int]:
    items, labels = first_pass(path)
    return [encode_line(item, labels) for item in items]


def write_hex(words: list[int], path: pathlib.Path) -> None:
    path.write_text("\n".join(f"{word:08X}" for word in words) + "\n", encoding="utf-8")


def write_mif(words: list[int], path: pathlib.Path, depth: int) -> None:
    if depth < len(words):
        raise AssemblyError(f"Requested depth {depth} is smaller than program size {len(words)}")
    lines = [
        f"DEPTH = {depth};",
        "WIDTH = 32;",
        "ADDRESS_RADIX = HEX;",
        "DATA_RADIX = HEX;",
        "CONTENT BEGIN",
    ]
    for address, word in enumerate(words):
        lines.append(f"    {address:04X} : {word:08X};")
    if depth > len(words):
        lines.append(f"    [{len(words):04X}..{depth - 1:04X}] : 00000000;")
    lines.append("END;")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inputs", nargs="+", help="Assembly files to assemble")
    parser.add_argument("--output-dir", default="quartus/programs", help="Directory for generated memory files")
    parser.add_argument("--depth", type=int, default=1024, help="Quartus memory depth in 32-bit words")
    parser.add_argument("--format", choices=("hex", "mif", "both"), default="both", help="Generated file format")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    output_dir = pathlib.Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    for raw_input in args.inputs:
        input_path = pathlib.Path(raw_input)
        words = assemble(input_path)
        stem = sanitize_stem(input_path)
        if args.format in {"hex", "both"}:
            write_hex(words, output_dir / f"{stem}.hex")
        if args.format in {"mif", "both"}:
            write_mif(words, output_dir / f"{stem}.mif", args.depth)
        print(f"Assembled {input_path} -> {stem} ({len(words)} words)")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except AssemblyError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
