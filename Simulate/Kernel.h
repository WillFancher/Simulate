//
//  Kernel.h
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

#import <Foundation/Foundation.h>
#import "ProliferatingSystem.h"

cl_ndrange makeRangeForKernel(void *kernel, int numWorkItems);

@protocol Kernel <NSObject>

- (void)runKernelInSystem:(ProliferatingSystem *)system queue:(OpenCLQueue *) queue;

@end
