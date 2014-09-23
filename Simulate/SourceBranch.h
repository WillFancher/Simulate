//
//  SourceBranch.h
//  Simulate
//
//  Created by Will Fancher on 9/10/14.
//
//

#import <Foundation/Foundation.h>
#import <OpenCL/opencl.h>

@interface SourceBranch : NSObject <NSCopying>

@property int indexInSources;
@property cl_float3 direction;
@property int cellsSinceLastBranch;

@end
