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
        srand((uint)time(NULL));
        kernel = gcl_create_kernel_from_block((__bridge void *)(proliferation_kernel));
    }
    return self;
}

- (void)runKernelInSystem:(ChunkedProliferatingSystem *)system queue:(OpenCLQueue *)queue {
    for (SharedFloat4Data *chunk in system.cellData) {
        [chunk copyFromDevice:queue];
    }
    
    float threshold = .8;
    
    NSUInteger chunkToFill = 0;
    NSUInteger indexToFill = 0;
    for (int chunkIndex = 0; chunkIndex < system.cellData.count; ++chunkIndex) {
        SharedFloat4Data *chunk = system.cellData[chunkIndex];
        for (int i = 0; i < chunk.length; ++i) {
            if (chunk.hostData[i].w > 1 && (float)rand() / (float)RAND_MAX > threshold) {
                SharedFloat4Data *fillChunk = (SharedFloat4Data *)system.cellData[chunkToFill];
                while (true) {
                    if (fillChunk.hostData[indexToFill].w <= 0) {
                        cl_float4 newCell = chunk.hostData[i];
                        newCell.x += rand() % 2 == 0 ? .1 : -.1;
                        newCell.y += rand() % 2 == 0 ? .1 : -.1;
                        newCell.z += rand() % 2 == 0 ? .1 : -.1;
                        newCell.w = 1;
                        fillChunk.hostData[indexToFill] = newCell;
                        break;
                    }
                    
                    indexToFill++;
                    if (indexToFill == fillChunk.length) {
                        chunkToFill++;
                        indexToFill = 0;
                        if (chunkToFill == system.cellData.count) {
                            SharedFloat4Data *newChunk = [[SharedFloat4Data alloc] initWithLength:1024];
                            [system.cellData addObject:newChunk];
                            fillChunk = newChunk;
                        }
                    }
                }
            }
        }
    }
    
    for (SharedFloat4Data *chunk in system.cellData) {
        [chunk copyFromHost:queue];
    }
}

- (void)dealloc {
    clReleaseKernel(kernel);
}

@end
