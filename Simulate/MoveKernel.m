//
//  MoveKernel.m
//  Simulator
//
//  Created by Will Fancher on 6/27/14.
//
//

#import "MoveKernel.h"
#import "SharedFloat4Data.h"
#import "move.cl.h"

#define MOVEMENT_ITERATIONS 5

@interface MoveKernel () {
    cl_kernel kernel;
}

@end

@implementation MoveKernel

- (instancetype)init {
    self = [super init];
    if (self) {
        kernel = gcl_create_kernel_from_block((__bridge void *)(move_kernel));
    }
    return self;
}

- (void)runKernelInSystem:(ProliferatingSystem *)system queue:(OpenCLQueue *)queue {
    __block SharedFloat4Data *outBuffer = [[SharedFloat4Data alloc] initWithLength:system.cellData.length];
//    [queue dispatchSynchronous:^{
//        [system.cellData copyFromHost:queue];
//        
//        cl_ndrange range = makeRangeForKernel((__bridge void *)(move_kernel), outBuffer.length);
//        for (int i = 0; i < MOVEMENT_ITERATIONS; ++i) {
//            if (outBuffer.length > 0) {
//                move_kernel(&range, MOVEMENT_ITERATIONS, outBuffer.length, system.cellData.deviceData, outBuffer.deviceData);
//                SharedFloat4Data *inBuffer = system.cellData;
//                system.cellData = outBuffer;
//                outBuffer = inBuffer;
//            }
//        }
//        [system.cellData copyFromDevice:queue];
//    }];
    [system.cellData copyFromHost:queue];
    
    for (int i = 0; i < MOVEMENT_ITERATIONS; ++i) {
        if (outBuffer.length > 0) {
            cl_int numIterations = MOVEMENT_ITERATIONS;
            cl_int numCells = outBuffer.length;
            cl_mem cellMem = gcl_create_buffer_from_ptr(system.cellData.deviceData);
            cl_mem outMem = gcl_create_buffer_from_ptr(outBuffer.deviceData);
            
            checkCLError(clSetKernelArg(kernel, 0, sizeof(numIterations), &numIterations));
            checkCLError(clSetKernelArg(kernel, 1, sizeof(numCells), &numCells));
            checkCLError(clSetKernelArg(kernel, 2, sizeof(cellMem), &cellMem));
            checkCLError(clSetKernelArg(kernel, 3, sizeof(outMem), &outMem));
            
            size_t globalSize = outBuffer.length;
            checkCLError(clEnqueueNDRangeKernel(queue.command_queue, kernel, 1, NULL, &globalSize, NULL, 0, NULL, NULL));
            
            checkCLError(clReleaseMemObject(cellMem));
            checkCLError(clReleaseMemObject(outMem));
            checkCLError(clFinish(queue.command_queue));
            
            SharedFloat4Data *inBuffer = system.cellData;
            system.cellData = outBuffer;
            outBuffer = inBuffer;
        }
    }
    
    [system.cellData copyFromDevice:queue];
}

- (void)dealloc {
    clReleaseKernel(kernel);
}

@end
