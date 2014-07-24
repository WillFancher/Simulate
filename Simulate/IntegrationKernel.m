//
//  IntegrationKernel.m
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

#import "IntegrationKernel.h"
#import "integration.cl.h"

@implementation IntegrationKernel

- (void)runKernelInSystem:(ProliferatingSystem *)system queue:(OpenCLQueue *)queue {
    [queue dispatchSynchronous:^{
        cl_ndrange range = makeRangeForKernel((__bridge void *)(integration_kernel), system.cellData.length);
        if (range.global_work_size[0] > 0) {
            integration_kernel(&range,
                               system.cellData.deviceData,
                               system.integratorData.deviceData);
        }
    }];
}

@end
