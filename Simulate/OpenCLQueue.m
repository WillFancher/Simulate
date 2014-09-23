//
//  OpenCLQueue.m
//  OpenCL Simulator
//
//  Created by Will Fancher on 5/8/14.
//
//

#import "OpenCLQueue.h"

static void printDeviceInfo(cl_device_id device) {
    char name[128];
    char vendor[128];
    clGetDeviceInfo(device, CL_DEVICE_NAME, 128, name, NULL);
    clGetDeviceInfo(device, CL_DEVICE_VENDOR, 128, vendor, NULL);
    printf("%s\t- %s\n", vendor, name);
}

@implementation OpenCLQueue

- (instancetype)initWithCGLContext:(CGLContextObj)kCGLContext; {
    self = [super init];
    if (self) {
        CGLShareGroupObj kCGLShareGroup = CGLGetShareGroup(kCGLContext);
        
        gcl_gl_set_sharegroup(kCGLShareGroup);
        
        // Create a dispatch queue.
        self.queue = gcl_create_dispatch_queue(CL_DEVICE_TYPE_GPU, NULL);
        
        if (!self.queue) {
            self.queue = gcl_create_dispatch_queue(CL_DEVICE_TYPE_CPU, NULL);
        }
        
        if (self.queue != NULL) {
            self.context = gcl_get_context();
            self.device = gcl_get_device_id_with_dispatch_queue(self.queue);
            int err;
            self.command_queue = clCreateCommandQueue(self.context, gcl_get_device_id_with_dispatch_queue(self.queue), 0, &err);
            checkCLError(err);
        } else {
            printf("\nYour system does not contain an OpenCL-compatible processor\n");
            exit(0);
        }
    }
    return self;
}

- (void)printAvailableDevices {
    size_t length;
    cl_device_id devices[8];
    clGetContextInfo(self.context, CL_CONTEXT_DEVICES, sizeof(devices), devices, &length);
    
    printf("The following devices are available for use:\n");
    int numDevices = (int)(length / sizeof(cl_device_id));
    for (int i = 0; i < numDevices; i++) {
        printDeviceInfo(devices[i]);
    }
}

- (void)printDeviceInfo {
    printDeviceInfo(self.device);
}

- (void)dispatchSynchronous:(dispatch_block_t) kernel {
    dispatch_sync(self.queue, kernel);
}

- (void)dispatchAsynchronous:(dispatch_block_t) kernel {
    dispatch_async(self.queue, kernel);
}

@end