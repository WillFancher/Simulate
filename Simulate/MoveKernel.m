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

@implementation MoveKernel

- (void)runKernelInSystem:(ProliferatingSystem *)system queue:(OpenCLQueue *)queue {
    __block SharedFloat4Data *outBuffer = [[SharedFloat4Data alloc] initWithLength:system.cellData.length];
    [queue dispatchSynchronous:^{
        [system.cellData copyFromHost];
        
        cl_ndrange range = makeRangeForKernel((__bridge void *)(move_kernel), outBuffer.length);
        for (int i = 0; i < MOVEMENT_ITERATIONS; ++i) {
            if (outBuffer.length > 0) {
                move_kernel(&range, MOVEMENT_ITERATIONS, outBuffer.length, system.cellData.deviceData, outBuffer.deviceData);
                SharedFloat4Data *inBuffer = system.cellData;
                system.cellData = outBuffer;
                outBuffer = inBuffer;
            }
        }
        [system.cellData copyFromDevice];
    }];
}

@end
