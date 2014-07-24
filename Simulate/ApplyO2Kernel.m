//
//  ApplyO2Kernel.m
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

#import "ApplyO2Kernel.h"
#import "applyO2.cl.h"

@implementation ApplyO2Kernel

- (void)runKernelInSystem:(ProliferatingSystem *)system queue:(OpenCLQueue *)queue {
    [queue dispatchSynchronous:^{
        cl_ndrange range = makeRangeForKernel((__bridge void *)(applyO2_kernel), system.cellData.length);
        if (range.global_work_size[0] > 0) {
            applyO2_kernel(&range,
                           15, // threshold,
                           system.cellData.deviceData,
                           system.integratorData.deviceData,
                           system.sourceData.length,
                           system.sourceData.deviceData);
        }
    }];
}

@end
