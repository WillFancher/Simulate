//
//  ProliferationKernel.m
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

#import "ProliferationKernel.h"
#import "proliferation.cl.h"

@interface ProliferationKernel () {
    cl_kernel kernel;
}

@end

@implementation ProliferationKernel

- (instancetype)init {
    self = [super init];
    if (self) {
        srandom((uint)time(NULL));
        kernel = gcl_create_kernel_from_block((__bridge void *)(proliferation_kernel));
    }
    return self;
}

- (void)runKernelInSystem:(ProliferatingSystem *)system queue:(OpenCLQueue *)queue {
    [queue dispatchSynchronous:^{[system.cellData copyFromDevice:queue];}];
    int numProliferating = 0;
    for (int i = 0; i < system.cellData.length; ++i) {
        if (system.cellData.hostData[i].w == 2) {
            ++numProliferating;
        }
    }
    
    SharedFloat4Data *buffer = [[SharedFloat4Data alloc] initWithLength:numProliferating];
    
    if (numProliferating > 0) {
//        [queue dispatchSynchronous:^{
//            cl_ndrange range = makeRangeForKernel((__bridge void *)(proliferation_kernel), numProliferating);
//            proliferation_kernel(&range, random(), .8, system.cellData.length, system.cellData.deviceData, buffer.deviceData);
//            [buffer copyFromDevice:queue];
//        }];
        cl_ulong rand = random();
        cl_float threshold = .8;
        cl_int numCells = system.cellData.length;
        cl_mem cellMem = gcl_create_buffer_from_ptr(system.cellData.deviceData);
        cl_mem bufferMem = gcl_create_buffer_from_ptr(buffer.deviceData);
        
        checkCLError(clSetKernelArg(kernel, 0, sizeof(rand), &rand));
        checkCLError(clSetKernelArg(kernel, 1, sizeof(threshold), &threshold));
        checkCLError(clSetKernelArg(kernel, 2, sizeof(numCells), &numCells));
        checkCLError(clSetKernelArg(kernel, 3, sizeof(cellMem), &cellMem));
        checkCLError(clSetKernelArg(kernel, 4, sizeof(bufferMem), &bufferMem));
        
        size_t globalSize = numProliferating;
        checkCLError(clEnqueueNDRangeKernel(queue.command_queue, kernel, 1, NULL, &globalSize, NULL, 0, NULL, NULL));
        
        checkCLError(clReleaseMemObject(cellMem));
        checkCLError(clReleaseMemObject(bufferMem));
        checkCLError(clFinish(queue.command_queue));
        
        [buffer copyFromDevice:queue];
    }
    
    int newCellCount = 0;
    for (int i = 0; i < system.cellData.length; ++i) {
        if (system.cellData.hostData[i].w > 0) {
            ++newCellCount;
        }
    }
    
    for (int i = 0; i < numProliferating; ++i) {
        if (buffer.hostData[i].w > 0) {
            ++newCellCount;
        }
    }
    
    cl_float4 *newHostCellData = calloc(newCellCount, sizeof(cl_float4));
    int index = 0;
    for (int i = 0; i < system.cellData.length; ++i) {
        if (system.cellData.hostData[i].w > 0) {
            newHostCellData[index++] = system.cellData.hostData[i];
        }
    }
    for (int i = 0; i < numProliferating; ++i) {
        if (buffer.hostData[i].w > 0) {
            newHostCellData[index++] = buffer.hostData[i];
        }
    }
    
    system.cellData = nil;
    system.integratorData = nil;
    
    system.cellData = [[SharedFloat4Data alloc] initWithHostPointer:newHostCellData length:newCellCount];
    system.integratorData = [[SharedIntData alloc] initWithLength:newCellCount];
}

- (void)dealloc {
    clReleaseKernel(kernel);
}

@end
