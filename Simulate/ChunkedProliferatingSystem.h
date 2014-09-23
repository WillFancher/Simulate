//
//  ChunkedProliferatingSystem.h
//  Simulate
//
//  Created by Will Fancher on 8/26/14.
//
//

#import <Foundation/Foundation.h>
#import "OpenCLQueue.h"
#import "SharedFloat4Data.h"
#import "SourceBranch.h"

@interface ChunkedProliferatingSystem : NSObject

@property OpenCLQueue *queue;
@property NSMutableArray *cellData;
@property NSMutableArray *sourceBranches;
@property SharedFloat4Data *sourceData;

- (instancetype)initWithQueue:(OpenCLQueue*)queue;
- (void)step;
- (int)livingCells;

@end
