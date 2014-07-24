//
//  SharedIntData.h
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

#import <Foundation/Foundation.h>
@import OpenCL;

@interface SharedIntData : NSObject

@property cl_int *hostData;
@property void *deviceData;
@property(readonly) int length;

- (instancetype)initWithLength:(int)length;
- (instancetype)initWithHostPointer:(cl_int*)hostData length:(int)length;
- (void)copyFromHost;
- (void)copyFromDevice;

@end
