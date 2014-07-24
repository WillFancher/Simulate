//
//  ProliferationKernel.m
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

#import "ProliferationKernel.h"
#import "proliferation.cl.h"

@implementation ProliferationKernel

- (instancetype)init {
    self = [super init];
    if (self) {
        srandom((uint)time(NULL));
    }
    return self;
}

- (void)runKernelInSystem:(ProliferatingSystem *)system queue:(OpenCLQueue *)queue {
    [queue dispatchSynchronous:^{[system.cellData copyFromDevice];}];
    int numProliferating = 0;
    for (int i = 0; i < system.cellData.length; ++i) {
        if (system.cellData.hostData[i].w == 2) {
            ++numProliferating;
        }
    }
    
    SharedFloat4Data *buffer = [[SharedFloat4Data alloc] initWithLength:numProliferating];
    
    if (numProliferating > 0) {
        [queue dispatchSynchronous:^{
            cl_ndrange range = makeRangeForKernel((__bridge void *)(proliferation_kernel), numProliferating);
            proliferation_kernel(&range, random(), .8, system.cellData.length, system.cellData.deviceData, buffer.deviceData);
            [buffer copyFromDevice];
        }];
    }
    
    int newCellCount = 0;
    for (int i = 0; i < system.cellData.length; ++i) {
        if (system.cellData.hostData[i].w > 0) {
            ++newCellCount;
        }
    }
    
    for (int i = 0; i < numProliferating; ++i) {
        if (buffer.hostData[i].w > 0) {
            ++newCellCount;
        }
    }
    
    cl_float4 *newHostCellData = calloc(newCellCount, sizeof(cl_float4));
    int index = 0;
    for (int i = 0; i < system.cellData.length; ++i) {
        if (system.cellData.hostData[i].w > 0) {
            newHostCellData[index++] = system.cellData.hostData[i];
        }
    }
    for (int i = 0; i < numProliferating; ++i) {
        if (buffer.hostData[i].w > 0) {
            newHostCellData[index++] = buffer.hostData[i];
        }
    }
    
    system.cellData = nil;
    system.integratorData = nil;
    
    system.cellData = [[SharedFloat4Data alloc] initWithHostPointer:newHostCellData length:newCellCount];
    system.integratorData = [[SharedIntData alloc] initWithLength:newCellCount];
}

@end
