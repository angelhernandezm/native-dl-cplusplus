// Build with CMake (see docs/IDE_SETUP.md), or by hand:
//   nvcc hello_cuda.cu -gencode arch=compute_86,code=sm_86 -o hello_cuda

#include <stdio.h>
#include <cuda_runtime.h>

__global__ void welcome() {
   printf("Welcome to DL with C++ - block %d, thread %d\n", blockIdx.x, threadIdx.x);
}

int main() {
    welcome<<<3,3>>>();

    auto err = cudaGetLastError();
    if (err != cudaSuccess)
        printf("Kernel launch error: %s\n", cudaGetErrorString(err));

    err = cudaDeviceSynchronize();
    if (err != cudaSuccess)
        printf("Kernel execution error: %s\n", cudaGetErrorString(err));

    return 0;
}