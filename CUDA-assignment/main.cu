#include <iostream>
#include <cstdlib>
#include <stdlib.h>
#include <time.h>
#include "timer.h"

#define threadNumberPerBlock 1024
#define mask 0xffffffff

__global__ void greatestNumber(unsigned int x, int *deviceArray, int *deviceMutex, int *deviceMaximum) {


    unsigned int threadIndX = threadIdx.x;
    unsigned int wid = threadIndX % 32;
    unsigned int blockD = blockDim.x;
   	unsigned int index = threadIndX + blockIdx.x * blockD;
    __shared__ int local[threadNumberPerBlock];
    local[threadIndX] = deviceArray[index];
	__syncthreads();
    //performing the wrap reduction
    for (int oSet = 32; oSet > 0; oSet /= 2) {
        int value = __shfl_down_sync(mask, local[threadIndX], oSet);
        if(value > local[wid]) {
            local[wid] = value;
        }
        __syncthreads();
    }
    //findling maximum use atomicMax function.
    if(threadIndX == 0){
        atomicMax(deviceMaximum, local[0]);
	}

}


int main(){
    int *hostArray,*hostMaximum,*deviceArray,*deviceMaximum, *deviceMutex;
    unsigned int x = 402653184;
    unsigned int i = 0;
    dim3 blockNumber = x/threadNumberPerBlock;
    dim3 threadNumber = threadNumberPerBlock;
    hostArray=(int*)malloc(x*sizeof(int));
    cudaMalloc((void**)&deviceArray,x*sizeof(int));
    hostMaximum=(int*)malloc(sizeof(int));
    cudaMalloc((void**)&deviceMaximum,sizeof(int));
    cudaMemset(deviceMaximum, 0, sizeof(int));
	cudaMalloc((void**)&deviceMutex, sizeof(int));
	cudaMemset(deviceMutex, 0, sizeof(int));

   
    //putting numbers in the host array.
    while(i<x){
        hostArray[i]=i;
        i++; 
    }

    // serial code starts
    timespec serialStart , serialFinish , serialTimeSpent;
    clock_gettime( CLOCK_REALTIME , &serialStart);
    unsigned int j=0;

    while(j<x){
			if(hostArray[j] > *hostMaximum) 
                *hostMaximum = hostArray[j];
        j++;
	}
    
    clock_gettime( CLOCK_REALTIME , &serialFinish );
    serialTimeSpent = time_diff(serialStart , serialFinish);
    printf("Maximum number found by serial version is %d \n",*hostMaximum);
    printf("serial time spent %ld.%09ld sec.\n" , serialTimeSpent.tv_sec , serialTimeSpent.tv_nsec);
    //serial code ends



   //parallel code starts
    timespec parallelStart , parallelFinish , parallelTimeSpent;


    timespec parallelCopyStart, parallelCopyFinish, parallelCopyTimeSpent;
    clock_gettime( CLOCK_REALTIME , &parallelCopyStart);

    //copying the host data to device data.
    cudaMemcpy(deviceArray,hostArray,x*sizeof(int),cudaMemcpyHostToDevice);
    

    clock_gettime( CLOCK_REALTIME , &parallelCopyFinish );
    clock_gettime( CLOCK_REALTIME , &parallelStart);
    greatestNumber<<<blockNumber,threadNumber>>>(x, deviceArray , deviceMutex , deviceMaximum);
    clock_gettime( CLOCK_REALTIME , &parallelFinish );

    //copying the device data to host data.
    cudaMemcpy(hostMaximum,deviceMaximum,sizeof(int),cudaMemcpyDeviceToHost);
    parallelTimeSpent = time_diff(parallelStart , parallelFinish);
    parallelCopyTimeSpent = time_diff(parallelCopyStart , parallelCopyFinish);

    printf("Maximum number found by parallel version is %d \n",*hostMaximum);
    printf("parallel time spent  %ld.%09ld sec.\n" , parallelTimeSpent.tv_sec , parallelTimeSpent.tv_nsec);
    printf("parallel copy time spent  %ld.%09ld sec.\n" , parallelCopyTimeSpent.tv_sec , parallelCopyTimeSpent.tv_nsec);


    

    //now at the end make the memory free.
    free(hostArray);
    cudaFree(deviceArray);     
    free(hostMaximum);
    cudaFree(deviceMaximum);     


}
