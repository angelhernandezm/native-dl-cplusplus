// Compile with: nvcc -std=c++14 -x cu -arch=sm_75 hello_cuda.cu -o hello_cuda

#include <stdio.h>

__global__ void welcome() {
   printf("Welcome to DL with C++ — block %d, thread %d\n", blockIdx.x, threadIdx.x);
}

int main() {
  welcome<<<3,3>>>(); // 3 blocks, 3 threads each
  cudaDeviceSynchronize();

  return 0;
}