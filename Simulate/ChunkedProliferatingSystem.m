//
//  ChunkedProliferatingSystem.m
//  Simulate
//
//  Created by Will Fancher on 8/26/14.
//
//

#import <GLKit/GLKit.h>
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
        
        self.sourceBranches = [NSMutableArray array];
        
        self.sourceData = [[SharedFloat4Data alloc] initWithLength:pow(2, 3)+1 queue:queue];
        
        cl_float4 *hostData = self.sourceData.hostData;
        hostData[0].x = 0;
        hostData[0].y = 0;
        hostData[0].z = 0;
        hostData[0].w = 120;
        SourceBranch *firstBranch = [[SourceBranch alloc] init];
        firstBranch.indexInSources = 0;
        firstBranch.cellsSinceLastBranch = 0;
        cl_float3 firstDir;
        firstDir.x = 1;
        firstDir.y = 0;
        firstDir.z = 0;
        firstBranch.direction = firstDir;
        [self.sourceBranches addObject:firstBranch];
        
        int count = 1;
        for (int x = -20; x <= 20; x += 40) {
            for (int y = -20; y <= 20; y += 40) {
                for (int z = -20; z <= 20; z += 40) {
                    hostData[count].x = x;
                    hostData[count].y = y;
                    hostData[count].z = z;
                    hostData[count].w = 120;
                    
                    SourceBranch *branch = [[SourceBranch alloc] init];
                    branch.indexInSources = count;
                    branch.cellsSinceLastBranch = 0;
                    
                    GLKVector3 vec = GLKVector3Make(-x, -y, -z);
                    vec = GLKVector3Normalize(vec);
                    cl_float3 dir;
                    dir.x = vec.x;
                    dir.y = vec.y;
                    dir.z = vec.z;
                    branch.direction = dir;
                    
                    [self.sourceBranches addObject:branch];
                    
                    ++count;
                }
            }
        }
        
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
