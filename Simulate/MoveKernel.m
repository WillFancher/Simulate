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

- (void)runKernelInSystem:(ChunkedProliferatingSystem *)system queue:(OpenCLQueue *)queue {
    NSMutableArray *newChunks = [NSMutableArray array];
    
    for (SharedFloat4Data *chunk in system.cellData) {
        SharedFloat4Data *outBuffer = [[SharedFloat4Data alloc] initWithLength:chunk.length queue:queue];
        
        cl_mem outMem = outBuffer.deviceData;
        
        // Make sure outMem is a duplicate of original chunk
        [chunk copyFromDevice:queue];
        checkCLError(clEnqueueWriteBuffer(queue.command_queue, outMem, CL_TRUE, 0, chunk.length * sizeof(cl_float4), chunk.hostData, 0, NULL, NULL));
        
        for (int i = 0; i < MOVEMENT_ITERATIONS; ++i) {
            for (SharedFloat4Data *otherChunk in system.cellData) {
                cl_int numIterations = MOVEMENT_ITERATIONS;
                cl_int numCells = otherChunk.length;
                cl_mem cellMem = otherChunk.deviceData;
                
                checkCLError(clSetKernelArg(kernel, 0, sizeof(numIterations), &numIterations));
                checkCLError(clSetKernelArg(kernel, 1, sizeof(numCells), &numCells));
                checkCLError(clSetKernelArg(kernel, 2, sizeof(outMem), &outMem));
                checkCLError(clSetKernelArg(kernel, 3, sizeof(cellMem), &cellMem));
                
                size_t globalSize = outBuffer.length;
                checkCLError(clEnqueueNDRangeKernel(queue.command_queue, kernel, 1, NULL, &globalSize, NULL, 0, NULL, NULL));
                checkCLError(clFinish(queue.command_queue));
            }
        }
        
        checkCLError(clFinish(queue.command_queue));
        [newChunks addObject:outBuffer];
    }
    
    for (int i = 0; i < newChunks.count; ++i) {
        [newChunks[i] copyFromDevice:queue];
        system.cellData[i] = newChunks[i];
    }
}

- (void)dealloc {
    clReleaseKernel(kernel);
}

@end
