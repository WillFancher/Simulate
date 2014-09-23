//
//  OpenCLQueue.h
//  Simulator
//
//  Created by Will Fancher on 5/8/14.
//
//

#import <OpenCL/opencl.h>
#import <OpenGL/OpenGL.h>
#import "checkCLError.h"

/*
 OpenCLQueue is a class used to get a queue ready for running OpenCL kernels
 */

@interface OpenCLQueue : NSObject

@property dispatch_queue_t queue;
@property cl_context context;
@property cl_device_id device;
@property cl_command_queue command_queue;

- (instancetype)initWithCGLContext:(CGLContextObj)context;

// Prints all devices available to the platform
- (void)printAvailableDevices;

// Print the selected device
- (void)printDeviceInfo;

// Dispatch a block on a queue capable of running opencl commands for the device
- (void)dispatchSynchronous:(dispatch_block_t) kernel;
- (void)dispatchAsynchronous:(dispatch_block_t) kernel;

@end
