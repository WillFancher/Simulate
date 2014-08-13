//
//  OpenCLQueue.m
//  OpenCL Simulator
//
//  Created by Will Fancher on 5/8/14.
//
//

#import "OpenCLQueue.h"

NSString *descriptionOfCLError(cl_int err) {
    switch (err) {
        case CL_SUCCESS:                            return @"Success!";
        case CL_DEVICE_NOT_FOUND:                   return @"Device not found.";
        case CL_DEVICE_NOT_AVAILABLE:               return @"Device not available";
        case CL_COMPILER_NOT_AVAILABLE:             return @"Compiler not available";
        case CL_MEM_OBJECT_ALLOCATION_FAILURE:      return @"Memory object allocation failure";
        case CL_OUT_OF_RESOURCES:                   return @"Out of resources";
        case CL_OUT_OF_HOST_MEMORY:                 return @"Out of host memory";
        case CL_PROFILING_INFO_NOT_AVAILABLE:       return @"Profiling information not available";
        case CL_MEM_COPY_OVERLAP:                   return @"Memory copy overlap";
        case CL_IMAGE_FORMAT_MISMATCH:              return @"Image format mismatch";
        case CL_IMAGE_FORMAT_NOT_SUPPORTED:         return @"Image format not supported";
        case CL_BUILD_PROGRAM_FAILURE:              return @"Program build failure";
        case CL_MAP_FAILURE:                        return @"Map failure";
        case CL_INVALID_VALUE:                      return @"Invalid value";
        case CL_INVALID_DEVICE_TYPE:                return @"Invalid device type";
        case CL_INVALID_PLATFORM:                   return @"Invalid platform";
        case CL_INVALID_DEVICE:                     return @"Invalid device";
        case CL_INVALID_CONTEXT:                    return @"Invalid context";
        case CL_INVALID_QUEUE_PROPERTIES:           return @"Invalid queue properties";
        case CL_INVALID_COMMAND_QUEUE:              return @"Invalid command queue";
        case CL_INVALID_HOST_PTR:                   return @"Invalid host pointer";
        case CL_INVALID_MEM_OBJECT:                 return @"Invalid memory object";
        case CL_INVALID_IMAGE_FORMAT_DESCRIPTOR:    return @"Invalid image format descriptor";
        case CL_INVALID_IMAGE_SIZE:                 return @"Invalid image size";
        case CL_INVALID_SAMPLER:                    return @"Invalid sampler";
        case CL_INVALID_BINARY:                     return @"Invalid binary";
        case CL_INVALID_BUILD_OPTIONS:              return @"Invalid build options";
        case CL_INVALID_PROGRAM:                    return @"Invalid program";
        case CL_INVALID_PROGRAM_EXECUTABLE:         return @"Invalid program executable";
        case CL_INVALID_KERNEL_NAME:                return @"Invalid kernel name";
        case CL_INVALID_KERNEL_DEFINITION:          return @"Invalid kernel definition";
        case CL_INVALID_KERNEL:                     return @"Invalid kernel";
        case CL_INVALID_ARG_INDEX:                  return @"Invalid argument index";
        case CL_INVALID_ARG_VALUE:                  return @"Invalid argument value";
        case CL_INVALID_ARG_SIZE:                   return @"Invalid argument size";
        case CL_INVALID_KERNEL_ARGS:                return @"Invalid kernel arguments";
        case CL_INVALID_WORK_DIMENSION:             return @"Invalid work dimension";
        case CL_INVALID_WORK_GROUP_SIZE:            return @"Invalid work group size";
        case CL_INVALID_WORK_ITEM_SIZE:             return @"Invalid work item size";
        case CL_INVALID_GLOBAL_OFFSET:              return @"Invalid global offset";
        case CL_INVALID_EVENT_WAIT_LIST:            return @"Invalid event wait list";
        case CL_INVALID_EVENT:                      return @"Invalid event";
        case CL_INVALID_OPERATION:                  return @"Invalid operation";
        case CL_INVALID_GL_OBJECT:                  return @"Invalid OpenGL object";
        case CL_INVALID_BUFFER_SIZE:                return @"Invalid buffer size";
        case CL_INVALID_MIP_LEVEL:                  return @"Invalid mip-map level";
        default: return @"Unknown";
    }
}

void checkCLError(cl_int err) {
    if (err) {
        NSString *errStr = descriptionOfCLError(err);
        @throw [NSException exceptionWithName:@"OpenCL error" reason:errStr userInfo:nil];
    }
}

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

- (void)dispatchSynchronous:(void(^)()) kernel {
    dispatch_sync(self.queue, kernel);
}

@end