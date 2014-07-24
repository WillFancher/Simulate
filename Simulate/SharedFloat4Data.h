//
//  SharedFloat4Data.h
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

#import <Foundation/Foundation.h>
@import OpenCL;

@interface SharedFloat4Data : NSObject

@property cl_float4 *hostData;
@property void *deviceData;
@property(readonly) int length;

- (instancetype)initWithLength:(int)length;
- (instancetype)initWithHostPointer:(cl_float4*)hostData length:(int)length;
- (void)copyFromHost;
- (void)copyFromDevice;

@end
