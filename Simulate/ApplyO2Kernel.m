//
//  ApplyO2Kernel.m
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

#import "ApplyO2Kernel.h"
#import "applyO2.cl.h"

@interface ApplyO2Kernel () {
    cl_kernel kernel;
}

@end

@implementation ApplyO2Kernel

- (instancetype)init {
    self = [super init];
    if (self) {
        kernel = gcl_create_kernel_from_block((__bridge void *)(applyO2_kernel));
    }
    return self;
}

- (void)runKernelInSystem:(ChunkedProliferatingSystem *)system queue:(OpenCLQueue *)queue {
    cl_mem sourceMem = system.sourceData.deviceData;
    for (SharedFloat4Data *chunk in system.cellData) {
        cl_mem cellMem = chunk.deviceData;
        cl_int numSources = system.sourceData.length;
        cl_float upperThreshold = 15;
        cl_float lowerThreshold = 10;
        
        int arg = 0;
        checkCLError(clSetKernelArg(kernel, arg++, sizeof(upperThreshold), &upperThreshold));
        checkCLError(clSetKernelArg(kernel, arg++, sizeof(lowerThreshold), &lowerThreshold));
        checkCLError(clSetKernelArg(kernel, arg++, sizeof(cellMem), &cellMem));
        checkCLError(clSetKernelArg(kernel, arg++, sizeof(numSources), &numSources));
        checkCLError(clSetKernelArg(kernel, arg++, sizeof(sourceMem), &sourceMem));
        
        size_t globalSize = chunk.length;
        checkCLError(clEnqueueNDRangeKernel(queue.command_queue, kernel, 1, NULL, &globalSize, NULL, 0, NULL, NULL));
        
        checkCLError(clFinish(queue.command_queue));
    }
    checkCLError(clFinish(queue.command_queue));
}

- (void)dealloc {
    clReleaseKernel(kernel);
}

@end
