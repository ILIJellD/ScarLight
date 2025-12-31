# Repository Guidelines

## Project Structure & Module Organization
- `boot/` contains the NASM boot stages (`boot/mbr.asm`, `boot/loader.asm`) plus shared constants in `boot/include/boot.inc`.
- `kernel/` holds the C entry point `kernel/main.c`. Build outputs land in `kernel/` (e.g., `kernel/main.o`, `kernel/kernel.bin`).
- `hd60M.img` is the disk image; `bochsrc` configures Bochs; `bochsout.txt` is the emulator log.

## Build, Test, and Development Commands
- Assemble boot code with NASM (also used for `.asm`, `.nasm`, `.S`):
  - `nasm -f bin boot/mbr.asm -o boot/mbr.bin`
  - `nasm -f bin boot/loader.asm -o boot/loader.bin`
- Compile C with GCC (freestanding, 32-bit example):
  - `gcc -m32 -ffreestanding -c kernel/main.c -o kernel/main.o`
- Link with `ld` to a flat binary (match `KERNEL_ENTRY_POINT` in `boot/include/boot.inc`):
  - `ld -m elf_i386 -Ttext 0xc0001500 -e main --oformat binary -o kernel/kernel.bin kernel/main.o`
- Write binaries into the image with `dd` (keep sector counts in sync with `boot/loader.asm`):
  - `dd if=boot/mbr.bin of=hd60M.img bs=512 count=1 conv=notrunc`
  - `dd if=boot/loader.bin of=hd60M.img bs=512 count=4 seek=2 conv=notrunc`
  - `dd if=kernel/kernel.bin of=hd60M.img bs=512 count=200 seek=9 conv=notrunc`
- Run kernel tests in Bochs: `bochs -f bochsrc`.

## Coding Style & Naming Conventions
- NASM syntax is used; labels are lower_snake_case (e.g., `loader_start`, `rd_disk_m_16`).
- Constants in `boot/include/boot.inc` use ALL_CAPS with `equ`.
- Keep labels at column 1 and align comments when practical.
- Keep C freestanding and minimal; match the existing K&R brace style in `kernel/main.c`.

## Testing Guidelines
- No automated tests are present; validate changes by booting in Bochs and checking screen output or `bochsout.txt`.
- If you add tests, place them under a new `tests/` directory and document how to run them here.

## Commit & Pull Request Guidelines
- This checkout has no git history, so no enforced commit format. Prefer short, imperative subjects (e.g., "Load kernel above 1MB").
- For PRs, include a summary, rebuild steps, and emulator evidence (log snippet or screenshot) when boot behavior changes.

## Generated Artifacts & Ignore Rules
- Ignore build outputs: `*.bin`, `*.img`, `*.o`, `bochsout.txt`, `bochs.out`.
- Regenerate artifacts after source changes; avoid hand-editing binaries or disk images.
