//
//  ProliferatingSystem.h
//  Simulator
//
//  Created by Will Fancher on 6/18/14.
//
//

@import Foundation;
@import OpenCL;
#import "OpenCLQueue.h"
#import "SharedFloat4Data.h"
#import "SharedIntData.h"

@interface ProliferatingSystem : NSObject

@property(strong) SharedFloat4Data *cellData;
@property(strong) SharedIntData *integratorData;
@property(strong) SharedFloat4Data *sourceData;

- (void)stepWithQueue:(OpenCLQueue *)queue;
- (int)livingCells;

@end
