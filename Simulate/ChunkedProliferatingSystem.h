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

@interface ChunkedProliferatingSystem : NSObject

@property NSMutableArray *cellData;
@property SharedFloat4Data *sourceData;

- (void)stepWithQueue:(OpenCLQueue *)queue;
- (int)livingCells;

@end
