cmake_minimum_required(VERSION 3.24)

# ---------------------------------------------------------------------------
# Options that must be known BEFORE project() enables the CUDA language,
# because CMake test-compiles a CUDA program during project().
# ---------------------------------------------------------------------------

# Target GPU architecture. 86 = Ampere consumer cards (RTX 30xx), matching the
# original `-gencode arch=compute_86,code=sm_86` command line.
# Override per machine, e.g. -DCMAKE_CUDA_ARCHITECTURES=89 (RTX 40xx),
# 120 (RTX 50xx) or "native" (whatever GPU is in this machine).
if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
    set(CMAKE_CUDA_ARCHITECTURES 86 CACHE STRING "CUDA architectures to build for")
endif()

# nvcc refuses host compilers (MSVC/GCC) newer than the ones it was released
# with. Prefer installing a matching CUDA Toolkit / MSVC toolset; use this
# switch only as a stop-gap.
option(ALLOW_UNSUPPORTED_HOST_COMPILER "Pass -allow-unsupported-compiler to nvcc" OFF)
if(ALLOW_UNSUPPORTED_HOST_COMPILER)
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -allow-unsupported-compiler" CACHE STRING "" FORCE)
endif()

project(native_dl_cplusplus LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# Lets clangd / CLion / VS Code pick up exact compiler flags.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(CUDAToolkit REQUIRED)

# ---------------------------------------------------------------------------
# Helper: one executable per sample, with sensible CUDA defaults.
# ---------------------------------------------------------------------------
function(add_cuda_sample name)
    add_executable(${name} ${ARGN})
    # Static runtime: no cudart DLL/.so needs to sit next to the binary.
    target_link_libraries(${name} PRIVATE CUDA::cudart_static)
    target_compile_options(${name} PRIVATE
        # Device-side debug info (-G) in Debug so Nsight can step through
        # kernels; line info in other configs for profiling.
        $<$<COMPILE_LANGUAGE:CUDA>:$<IF:$<CONFIG:Debug>,-G,-lineinfo>>
        # Keep MSVC happy with UTF-8 sources.
        $<$<AND:$<CXX_COMPILER_ID:MSVC>,$<COMPILE_LANGUAGE:CXX>>:/utf-8>
        $<$<AND:$<CXX_COMPILER_ID:MSVC>,$<COMPILE_LANGUAGE:CUDA>>:-Xcompiler=/utf-8>
    )
endfunction()

add_cuda_sample(hello_cuda src/hello_cuda.cu)
