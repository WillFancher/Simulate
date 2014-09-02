//
//  ChunkedKernel.h
//  Simulate
//
//  Created by Will Fancher on 8/26/14.
//
//

#import <Foundation/Foundation.h>
#import "ChunkedProliferatingSystem.h"

@protocol ChunkedKernel <NSObject>

- (void)runKernelInSystem:(ChunkedProliferatingSystem *)system
                    queue:(OpenCLQueue *) queue;

@end
