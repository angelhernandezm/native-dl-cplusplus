# IDE setup: CLion and Visual Studio for CUDA/C++

This repo is a plain **CMake** project with a `CMakePresets.json`, so CLion and Visual
Studio both open it directly. You don't need to keep a `.sln` or `.idea` folder in git,
and both IDEs use the same compiler flags.

| Preset (configure) | Generator | Use it for |
|---|---|---|
| `windows-debug` / `windows-release` | Ninja + MSVC | Daily work in **CLion** and **VS Open Folder** |
| `vs2022` / `vs2026` | Visual Studio `.sln` | **Nsight** kernel debugging in Visual Studio |
| `linux-debug` / `linux-release` | Ninja + GCC | Linux / WSL |

Every preset builds into `build/<preset>/` (ignored by git).
Debug builds pass `-G` to nvcc (device debug info). Release builds (`RelWithDebInfo`)
pass `-lineinfo` so Nsight Compute can map profiling results back to your source.

---

## 1. Prerequisites (Windows), in this order

1. **NVIDIA driver**: run `nvidia-smi` to confirm it works.
2. **Visual Studio 2022 or 2026** (Community is fine) with the **Desktop development with C++**
   workload. It brings MSVC, CMake and Ninja.
   CLion also needs this, because it uses the MSVC compiler from this install.
3. **CUDA Toolkit**: install it **after** Visual Studio, so the installer can add the
   MSBuild CUDA integration and **Nsight Visual Studio Edition**.
4. Open a new terminal and run `nvcc --version` to confirm it works.

> **The usual problem: toolkit and MSVC versions don't match.** Each CUDA release supports
> a range of MSVC versions, listed in the *CUDA Installation Guide for Windows*. If Visual
> Studio updates past that range, nvcc stops with
> `unsupported Microsoft Visual Studio version`. You can fix it in one of three ways:
> - Upgrade the CUDA Toolkit (the best fix), or
> - In the VS Installer, go to **Individual components** and add an older
>   *MSVC v14x build tools* toolset, or
> - As a stop-gap, configure with `-DALLOW_UNSUPPORTED_HOST_COMPILER=ON`.

---

## 2. Visual Studio

### Everyday editing, building and host debugging (Open Folder)

1. **File → Open → Folder…** and pick the **repo root**, the folder that contains
   `CMakeLists.txt`.
2. VS finds `CMakePresets.json`. Pick **Windows x64 Debug (Ninja + MSVC)** in the
   configuration drop-down on the toolbar.
3. In the startup item drop-down, choose **hello_cuda.exe**.
4. **Ctrl+Shift+B** builds. **F5** runs it under the host (CPU) debugger.

If `.cu` files don't get C++ coloring, go to **Tools → Options → Text Editor → File Extension**
and map `cu` and `cuh` to *Microsoft Visual C++*. The CUDA installer usually does this for you.

### Stepping through kernels with Nsight (the `.sln` route)

Nsight VSE works best with a real VS solution, so the presets can generate one:

```bat
cmake --preset vs2022
```

Use `vs2026` instead if you're on VS 2026. That preset needs CMake 4.2 or newer.

1. Open `build\vs2022\native_dl_cplusplus.sln`.
2. Right-click **hello_cuda** and choose **Set as Startup Project**. Set the configuration to **Debug**.
3. Put a breakpoint inside the `welcome()` kernel.
4. Choose **Extensions → Nsight → Start CUDA Debugging**. Use this, not F5: F5 only
   debugs host code.
5. Open **Extensions → Nsight → Windows → Warp Info** and **Locals** to inspect
   `blockIdx` and `threadIdx`.

When you add or rename files, edit `CMakeLists.txt` and build again. The `.sln` is
generated from it, so don't edit the project in VS.

---

## 3. CLion

### One-time toolchain setup

1. **Settings → Build, Execution, Deployment → Toolchains → + → Visual Studio**.
2. Point it at your VS install and set **Architecture: amd64**.
3. Move it to the top of the list so it becomes the default.
   Keep CLion's bundled CMake and Ninja.

### Open the project

1. **File → Open…** and pick the **repo root**. Don't pick `src/`: that's where the old
   `.idea` folder was created.
2. CLion reads `CMakePresets.json`. In **Settings → Build, Execution, Deployment → CMake**:
   - Enable the **windows-debug** and **windows-release** profiles.
   - Set **Toolchain = Visual Studio** on each of them.
   - Delete or disable CLion's default *Debug* profile. Otherwise CLion also creates a
     `cmake-build-debug/` folder.
3. Pick **hello_cuda | windows-debug** in the run widget, then build (Ctrl+F9) and run (Shift+F10).

### Things to know

- CLion fully understands `.cu` and `.cuh` files: completion, navigation and
  `__global__` highlighting all work.
- CLion's debugger stops at breakpoints in **host code only**. To debug a kernel, use
  Nsight in Visual Studio (see above), or `cuda-gdb` on Linux.
- If you get `No CMAKE_CUDA_COMPILER could be found`, restart CLion after installing CUDA,
  so it sees the new `PATH` and `CUDA_PATH`. If that doesn't help, add
  `-DCMAKE_CUDA_COMPILER="%CUDA_PATH%/bin/nvcc.exe"` to the profile's CMake options.

---

## 4. Command line (any terminal with MSVC on PATH)

From the **x64 Native Tools Command Prompt for VS**:

```bat
cmake --preset windows-debug
cmake --build --preset windows-debug
build\windows-debug\hello_cuda.exe
```

On Linux or WSL, use the `linux-debug` preset instead.

---

## 5. Settings for one machine only (other GPUs, extra flags)

The default target is `sm_86` (RTX 30xx). To build for a different GPU without changing
the shared presets, create a **`CMakeUserPresets.json`** (git ignores it):

```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "my-debug",
      "displayName": "My Debug (native GPU)",
      "inherits": "windows-debug",
      "cacheVariables": { "CMAKE_CUDA_ARCHITECTURES": "native" }
    }
  ]
}
```

Common values: `75` Turing (RTX 20xx), `86` Ampere (RTX 30xx), `89` Ada (RTX 40xx),
`120` Blackwell (RTX 50xx). You can also list several, for example `"86;89"`.

---

## 6. Adding new samples

Add one line per program to `CMakeLists.txt`:

```cmake
add_cuda_sample(vector_add src/vector_add.cu)
```

`add_cuda_sample` links the CUDA runtime and applies the Debug and Release flags described
above. Both IDEs pick up the new target after CMake reloads.
