//
//  SharedFloat4Data.m
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

#import "SharedFloat4Data.h"

@implementation SharedFloat4Data

- (instancetype)initWithHostPointer:(cl_float4*)hostData length:(int)length {
    self = [super init];
    if (self) {
        self.hostData = hostData;
        self.deviceData = gcl_malloc(length * sizeof(cl_float4), NULL, 0);
        _length = length;
    }
    return self;
}

- (instancetype)initWithLength:(int)length {
    return [self initWithHostPointer:calloc(length, sizeof(cl_float4)) length:length];
}

- (void)dealloc {
    free(self.hostData);
    if (self.deviceData) {
        gcl_free(self.deviceData);
    }
}

- (void)copyFromHost {
    gcl_memcpy(self.deviceData, self.hostData, self.length * sizeof(cl_float4));
}

- (void)copyFromDevice {
    gcl_memcpy(self.hostData, self.deviceData, self.length * sizeof(cl_float4));
}

@end
