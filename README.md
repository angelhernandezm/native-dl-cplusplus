# native-dl-cplusplus

Deep learning from scratch in native C++ and CUDA.

## Build

The project uses CMake with presets, so CLion and Visual Studio both open it directly.
See **[docs/IDE_SETUP.md](docs/IDE_SETUP.md)** for step-by-step setup instructions for each IDE.

```bat
cmake --preset windows-debug
cmake --build --preset windows-debug
build\windows-debug\hello_cuda.exe
```

On Linux or WSL, use the `linux-debug` preset instead.
