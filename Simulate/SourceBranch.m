//
//  SourceBranch.m
//  Simulate
//
//  Created by Will Fancher on 9/10/14.
//
//

#import "SourceBranch.h"

@implementation SourceBranch

- (id)copyWithZone:(NSZone *)zone {
    SourceBranch *newBranch = [[SourceBranch allocWithZone:zone] init];
    newBranch.indexInSources = self.indexInSources;
    newBranch.direction = self.direction;
    newBranch.cellsSinceLastBranch = self.cellsSinceLastBranch;
    return newBranch;
}

@end
