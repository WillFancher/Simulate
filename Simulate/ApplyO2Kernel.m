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

- (void)runKernelInSystem:(ProliferatingSystem *)system queue:(OpenCLQueue *)queue {
    cl_mem cellMem = gcl_create_buffer_from_ptr(system.cellData.deviceData);
    cl_mem integratorMem = gcl_create_buffer_from_ptr(system.integratorData.deviceData);
    cl_mem sourceMem = gcl_create_buffer_from_ptr(system.sourceData.deviceData);
    cl_int numSources = system.sourceData.length;
    cl_float threshold = 15;
    
    checkCLError(clSetKernelArg(kernel, 0, sizeof(threshold), &threshold));
    checkCLError(clSetKernelArg(kernel, 1, sizeof(cellMem), &cellMem));
    checkCLError(clSetKernelArg(kernel, 2, sizeof(integratorMem), &integratorMem));
    checkCLError(clSetKernelArg(kernel, 3, sizeof(numSources), &numSources));
    checkCLError(clSetKernelArg(kernel, 4, sizeof(sourceMem), &sourceMem));
    
    size_t globalSize = system.cellData.length;
    checkCLError(clEnqueueNDRangeKernel(queue.command_queue, kernel, 1, NULL, &globalSize, NULL, 0, NULL, NULL));
    
    checkCLError(clReleaseMemObject(cellMem));
    checkCLError(clReleaseMemObject(integratorMem));
    checkCLError(clReleaseMemObject(sourceMem));
    checkCLError(clFinish(queue.command_queue));
}

- (void)dealloc {
    clReleaseKernel(kernel);
}

@end
