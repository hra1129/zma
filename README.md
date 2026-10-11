# zma

Z80/R800クロスアセンブラです。
Windowsのコマンドラインアプリですが、Linux/MacOS用にビルドすることも可能です。

Z80/R800 cross assembler.
It is a command line application for Windows, but can also be built for Linux.

## how to build

### for Linux and macOS

```sh
cd src/linux
make
```
=======
## document

- [zma_取扱説明書.pdf](zma_取扱説明書.pdf)
- [zma_doc.md](zma_doc.md)

## operand regression tests (Windows)

Build `src\zma.vcxproj` with Visual Studio 2022, then run:

```powershell
powershell -NoProfile -File src\test_pattern\test_invalid_operands.ps1 -Executable src\x64\Debug\zma.exe
powershell -NoProfile -File src\test_pattern\test_conditional_layout.ps1 -Executable src\x64\Debug\zma.exe
```

The tests check invalid operands, error counts, continued processing, and the
existing opcode binary fixtures. Conditional layout tests also cover nested IFs,
per-invocation macro decisions, relative jump boundaries, and the 1,024-candidate
search limit. Use `-Executable` to test another build.
