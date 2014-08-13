//
//  IntegrationKernel.m
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

#import "IntegrationKernel.h"
#import "integration.cl.h"

@interface IntegrationKernel () {
    cl_kernel kernel;
}

@end

@implementation IntegrationKernel

- (instancetype)init {
    self = [super init];
    if (self) {
        kernel = gcl_create_kernel_from_block((__bridge void *)(integration_kernel));
    }
    return self;
}

- (void)runKernelInSystem:(ProliferatingSystem *)system queue:(OpenCLQueue *)queue {
    cl_mem cellMem = gcl_create_buffer_from_ptr(system.cellData.deviceData);
    cl_mem integratorMem = gcl_create_buffer_from_ptr(system.integratorData.deviceData);
    
    checkCLError(clSetKernelArg(kernel, 0, sizeof(cellMem), &cellMem));
    checkCLError(clSetKernelArg(kernel, 1, sizeof(integratorMem), &integratorMem));
    
    size_t globalSize = system.cellData.length;
    checkCLError(clEnqueueNDRangeKernel(queue.command_queue, kernel, 1, NULL, &globalSize, NULL, 0, NULL, NULL));
    
    checkCLError(clReleaseMemObject(cellMem));
    checkCLError(clReleaseMemObject(integratorMem));
    checkCLError(clFinish(queue.command_queue));
}

- (void)dealloc {
    clReleaseKernel(kernel);
}

@end
