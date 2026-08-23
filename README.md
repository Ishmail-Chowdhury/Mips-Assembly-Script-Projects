# Mips-Assembly-Script-Projects

MIPS32 assembly implementations for:
- Booth's multiplication
- Restoring division
- Hamming decoding/correction
- MergeSort

## Quartus conversion

`tools/mips_to_quartus.py` assembles the repository's current MIPS subset and emits Quartus-friendly `.hex` and `.mif` memory images.

Example:

```bash
python3 tools/mips_to_quartus.py \
  "Booths (1) (2).asm" \
  "Divide (2) (1).asm" \
  "HammingCode2 (1).asm" \
  "MergeSortE (2).asm"
```

Generated files are written to `quartus/programs/` by default and can be used as memory initialization files in Quartus Prime Lite.

## Included MIPS32 processor

The `rtl/` directory now includes a simple single-cycle MIPS32/MIPS I-compatible execution platform for the instructions used by these routines:

- Arithmetic/logical: `add`, `sub`, `and`, `or`, `xor`, `nor`, `slt`
- Shifts/control: `sll`, `srl`, `sra`, `srlv`, `jr`
- Immediate/memory: `addi`, `andi`, `ori`, `lui`, `lw`, `sw`
- Flow control: `beq`, `bne`, `j`, `jal`

`rtl/mips32_system.v` ties the CPU to a unified dual-port word memory so the existing programs can execute unchanged, including their inline `.word` data regions.

Typical Quartus flow:

1. Run `tools/mips_to_quartus.py` on one of the `.asm` files.
2. Point `rtl/mips32_system.v` at the generated `.hex` file through the `INIT_FILE` parameter.
3. Simulate or synthesize the design in Quartus and monitor the exported debug signals (`debug_pc`, `debug_instruction`, `debug_reg_v0`, `debug_reg_v1`, and related register outputs).

Additional integration files:

- `rtl/mips32_system_tb.v`: simple testbench for simulation with cycle-by-cycle `pc`, `v0`, and `v1` visibility.
- `rtl/mips32_top_wrapper.v`: top-level wrapper that exposes `debug_pc`, `debug_v0`, and `debug_v1` for simulation/FPGA debug integration.