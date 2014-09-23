//
//  SharedFloat4Data.m
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

#import "SharedFloat4Data.h"

@implementation SharedFloat4Data

- (instancetype)initWithHostPointer:(cl_float4*)hostData length:(int)length queue:(OpenCLQueue*)queue {
    self = [super init];
    if (self) {
        self.hostData = hostData;
        cl_int err;
        self.deviceData = clCreateBuffer(queue.context, CL_MEM_READ_WRITE, length * sizeof(cl_float4), NULL, &err);
        checkCLError(err);
        _length = length;
        [self copyFromHost:queue];
    }
    return self;
}

- (instancetype)initWithLength:(int)length queue:(OpenCLQueue*)queue {
    return [self initWithHostPointer:calloc(length, sizeof(cl_float4)) length:length queue:queue];
}

- (void)dealloc {
    checkCLError(clReleaseMemObject(_deviceData));
    free(_hostData);
}

- (void)copyFromHost:(OpenCLQueue *)queue {
    checkCLError(clEnqueueWriteBuffer(queue.command_queue, self.deviceData, CL_TRUE, 0, self.length * sizeof(cl_float4), self.hostData, 0, NULL, NULL));
    checkCLError(clFinish(queue.command_queue));
}

- (void)copyFromDevice:(OpenCLQueue *)queue {
    checkCLError(clEnqueueReadBuffer(queue.command_queue, self.deviceData, CL_TRUE, 0, self.length * sizeof(cl_float4), self.hostData, 0, NULL, NULL));
    checkCLError(clFinish(queue.command_queue));
}

@end
