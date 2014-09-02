//
//  ChunkedProliferatingSystem.m
//  Simulate
//
//  Created by Will Fancher on 8/26/14.
//
//

#import "ChunkedProliferatingSystem.h"
#import "ApplyO2Kernel.h"
#import "ProliferationKernel.h"
#import "MoveKernel.h"
#import "ChunkedKernel.h"

@interface ChunkedProliferatingSystem ()

@property NSArray *kernels;

@end

@implementation ChunkedProliferatingSystem

- (instancetype)init {
    if (self = [super init]) {
        self.cellData = [NSMutableArray array];
        [self.cellData addObject:[[SharedFloat4Data alloc] initWithLength:1024]];
        cl_float4 cell;
        cell.x = 3;
        cell.y = 3;
        cell.z = 3;
        cell.w = 1;
        ((SharedFloat4Data *)self.cellData[0]).hostData[0] = cell;
        
        self.sourceData = [[SharedFloat4Data alloc] initWithLength:1000];
        int count = 0;
        for (int x = 0; x < 10; ++x) {
            for (int y = 0; y < 10; ++y) {
                for (int z = 0; z < 10; ++z) {
                    cl_float4 *hostData = self.sourceData.hostData;
                    hostData[count].x = x * 10;
                    hostData[count].y = y * 10;
                    hostData[count].z = z * 10;
                    hostData[count].w = 120;
                    ++count;
                }
            }
        }
        
        
        self.kernels = @[
                         [[ApplyO2Kernel alloc] init],
                         [[ProliferationKernel alloc] init],
                         [[MoveKernel alloc] init]
                         ];
    }
    return self;
}

- (void)stepWithQueue:(OpenCLQueue *)queue {
    [self.sourceData copyFromHost:queue];
    for (SharedFloat4Data *chunk in self.cellData) {
        [chunk copyFromHost:queue];
    }
    for (id<ChunkedKernel> kernel in self.kernels) {
        [kernel runKernelInSystem:self queue:queue];
    }
}

- (int)livingCells {
    int numAlive = 0;
    for (SharedFloat4Data *chunk in self.cellData) {
        int aliveInChunk = 0;
        for (int i = 0; i < chunk.length; ++i) {
            if (chunk.hostData[i].w > 0) {
                ++aliveInChunk;
            }
        }
        numAlive += aliveInChunk;
    }
    return numAlive;
}

@end
