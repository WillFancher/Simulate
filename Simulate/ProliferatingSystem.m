//
//  ProliferatingSystem.m
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

#import "ProliferatingSystem.h"
#import "ApplyO2Kernel.h"
#import "IntegrationKernel.h"
#import "ProliferationKernel.h"
#import "MoveKernel.h"

@interface ProliferatingSystem ()

@property(strong) NSArray *kernels;

@end

@implementation ProliferatingSystem

- (instancetype)init {
    self = [super init];
    if (self) {
        int numCells = 1;
        
        
        self.cellData = [[SharedFloat4Data alloc] initWithLength:numCells];
        
        self.cellData.hostData[0].x = 3;
        self.cellData.hostData[0].y = 3;
        self.cellData.hostData[0].z = 3;
        self.cellData.hostData[0].w = 1;
        
        self.integratorData = [[SharedIntData alloc] initWithLength:numCells];
        
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
            [[IntegrationKernel alloc] init],
            [[ProliferationKernel alloc] init],
            [[MoveKernel alloc] init]
        ];
    }
    return self;
}

- (void)stepWithQueue:(OpenCLQueue *)queue {
    [queue dispatchSynchronous:^{
        [self.cellData copyFromHost:queue];
        [self.integratorData copyFromHost:queue];
        [self.sourceData copyFromHost:queue];
    }];
    for (id<Kernel> kernel in self.kernels) {
        [kernel runKernelInSystem:self queue:queue];
    }
}

- (int)livingCells {
    int count = 0;
    for (int j = 0; j < self.cellData.length; ++j) {
        if (self.cellData.hostData[j].w > 0) {
            ++count;
        }
    }
    return count;
}

@end
