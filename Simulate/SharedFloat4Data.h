//
//  SharedFloat4Data.h
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

#import "OpenCLQueue.h"
#import <OpenCL/opencl.h>

@interface SharedFloat4Data : NSObject

@property cl_float4 *hostData;
@property void *deviceData;
@property(readonly) int length;

- (instancetype)initWithLength:(int)length;
- (instancetype)initWithHostPointer:(cl_float4*)hostData length:(int)length;
- (void)copyFromHost:(OpenCLQueue *)queue;
- (void)copyFromDevice:(OpenCLQueue *)queue;

@end
