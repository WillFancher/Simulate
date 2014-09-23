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
#import "SourceProliferationKernel.h"
#import "MoveKernel.h"
#import "ChunkedKernel.h"

@interface ChunkedProliferatingSystem ()

@property NSArray *kernels;

@end

@implementation ChunkedProliferatingSystem

- (instancetype)initWithQueue:(OpenCLQueue*)queue {
    if (self = [super init]) {
        self.queue = queue;
        self.cellData = [NSMutableArray array];
        [self.cellData addObject:[[SharedFloat4Data alloc] initWithLength:1024 queue:queue]];
        cl_float4 cell;
        cell.x = 3;
        cell.y = 3;
        cell.z = 3;
        cell.w = 1;
        ((SharedFloat4Data *)self.cellData[0]).hostData[0] = cell;
        
//        self.sourceData = [[SharedFloat4Data alloc] initWithLength:1000];
//        int count = 0;
//        for (int x = 0; x < 10; ++x) {
//            for (int y = 0; y < 10; ++y) {
//                for (int z = 0; z < 10; ++z) {
//                    cl_float4 *hostData = self.sourceData.hostData;
//                    hostData[count].x = x * 10;
//                    hostData[count].y = y * 10;
//                    hostData[count].z = z * 10;
//                    hostData[count].w = 120;
//                    ++count;
//                }
//            }
//        }
        self.sourceData = [[SharedFloat4Data alloc] initWithLength:1 queue:queue];
        self.sourceData.hostData[0].x = 1;
        self.sourceData.hostData[0].y = 0;
        self.sourceData.hostData[0].z = 0;
        self.sourceData.hostData[0].w = 120;
        
        SourceBranch *firstBranch = [[SourceBranch alloc] init];
        firstBranch.indexInSources = 0;
        cl_float3 direction;
        direction.x = 1;
        direction.y = 1;
        direction.z = 1;
        firstBranch.direction = direction;
        firstBranch.cellsSinceLastBranch = 0;
        self.sourceBranches = [NSMutableArray arrayWithObjects:firstBranch, nil];
        
        self.kernels = @[
                         [[ApplyO2Kernel alloc] init],
                         [[ProliferationKernel alloc] init],
                         [[SourceProliferationKernel alloc] init],
                         [[MoveKernel alloc] init]
                         ];
    }
    return self;
}

- (void)step {
    [self.sourceData copyFromHost:self.queue];
    for (SharedFloat4Data *chunk in self.cellData) {
        [chunk copyFromHost:self.queue];
    }
    [self.sourceData copyFromHost:self.queue];
    for (id<ChunkedKernel> kernel in self.kernels) {
        [kernel runKernelInSystem:self queue:self.queue];
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
