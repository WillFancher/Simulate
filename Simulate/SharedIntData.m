//
//  SharedIntData.m
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

#import "SharedIntData.h"

@implementation SharedIntData

- (instancetype)initWithHostPointer:(cl_int*)hostData length:(int)length {
    self = [super init];
    if (self) {
        self.hostData = hostData;
        self.deviceData = gcl_malloc(length * sizeof(cl_int), NULL, 0);
        _length = length;
    }
    return self;
}

- (instancetype)initWithLength:(int)length {
    return [self initWithHostPointer:calloc(length, sizeof(cl_int)) length:length];
}

- (void)dealloc {
    free(self.hostData);
    if (self.deviceData) {
        gcl_free(self.deviceData);
    }
}

- (void)copyFromHost:(OpenCLQueue *)queue {
//    gcl_memcpy(self.deviceData, self.hostData, self.length * sizeof(cl_int));
    cl_mem mem = gcl_create_buffer_from_ptr(self.deviceData);
    checkCLError(clEnqueueWriteBuffer(queue.command_queue, mem, CL_TRUE, 0, self.length * sizeof(cl_int), self.hostData, 0, NULL, NULL));
    checkCLError(clReleaseMemObject(mem));
    checkCLError(clFinish(queue.command_queue));
}

- (void)copyFromDevice:(OpenCLQueue *)queue {
//    gcl_memcpy(self.hostData, self.deviceData, self.length * sizeof(cl_int));
    cl_mem mem = gcl_create_buffer_from_ptr(self.deviceData);
    checkCLError(clEnqueueReadBuffer(queue.command_queue, mem, CL_TRUE, 0, self.length * sizeof(cl_int), self.hostData, 0, NULL, NULL));
    checkCLError(clReleaseMemObject(mem));
    checkCLError(clFinish(queue.command_queue));
}

@end
