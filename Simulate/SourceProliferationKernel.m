//
//  SourceProliferationKernel.m
//  Simulate
//
//  Created by Will Fancher on 9/10/14.
//
//

#import "SourceProliferationKernel.h"
#import "source_move.cl.h"
#import <GLKit/GLKit.h>

@interface SourceProliferationKernel () {
    cl_kernel kernel;
}

@end

@implementation SourceProliferationKernel

- (instancetype)init {
    if (self = [super init]) {
        kernel = gcl_create_kernel_from_block((__bridge void *)(source_move_kernel));
    }
    return self;
}

- (void)runKernelInSystem:(ChunkedProliferatingSystem *)system
                    queue:(OpenCLQueue *) queue {
    NSMutableArray *branchesToAdd = [NSMutableArray array];
    for (SourceBranch *branch in system.sourceBranches) {
        if (branch.cellsSinceLastBranch >= 10) {
            branch.cellsSinceLastBranch = 0;
            SourceBranch *newBranch = branch.copy;
            
            GLKVector3 vec = GLKVector3Make(rand(), rand(), rand());
            vec = GLKVector3Normalize(vec);
            
            cl_float3 newDir;
            newDir.x = vec.x;
            newDir.y = vec.y;
            newDir.z = vec.z;
            newBranch.direction = newDir;
            [branchesToAdd addObject:newBranch];
        }
    }
    [system.sourceBranches addObjectsFromArray:branchesToAdd];
    
    SharedFloat4Data *newSources = [[SharedFloat4Data alloc] initWithLength:system.sourceData.length + (int)system.sourceBranches.count queue:queue];
    [system.sourceData copyFromDevice:queue];
    for (int i = 0; i < system.sourceData.length; ++i) {
        newSources.hostData[i] = system.sourceData.hostData[i];
    }
    
    SharedFloat4Data *sharedDirectionData = [[SharedFloat4Data alloc] initWithLength:(int)system.sourceBranches.count queue:queue];
    
    int nextIndex = system.sourceData.length;
    for (SourceBranch *branch in system.sourceBranches) {
        cl_float4 oldPoint = system.sourceData.hostData[branch.indexInSources];
        cl_float4 newPoint;
        newPoint.x = oldPoint.x + branch.direction.x;
        newPoint.y = oldPoint.y + branch.direction.y;
        newPoint.z = oldPoint.z + branch.direction.z;
        newPoint.w = oldPoint.w;
        newSources.hostData[nextIndex] = newPoint;
        branch.indexInSources = nextIndex;
        branch.cellsSinceLastBranch++;
        
        sharedDirectionData.hostData[nextIndex - system.sourceData.length].w = branch.indexInSources;
        
        nextIndex++;
    }
    
    [newSources copyFromHost:queue];
    system.sourceData = newSources;
    
    [sharedDirectionData copyFromHost:queue];
    
    for (SharedFloat4Data *chunk in system.cellData) {
        cl_int numSources = system.sourceData.length;
        cl_mem sourceData = system.sourceData.deviceData;
        cl_int numCells = chunk.length;
        cl_mem cellData = chunk.deviceData;
        cl_mem directionData = sharedDirectionData.deviceData;
        
        int arg = 0;
        checkCLError(clSetKernelArg(kernel, arg++, sizeof(numSources), &numSources));
        checkCLError(clSetKernelArg(kernel, arg++, sizeof(sourceData), &sourceData));
        checkCLError(clSetKernelArg(kernel, arg++, sizeof(numCells), &numCells));
        checkCLError(clSetKernelArg(kernel, arg++, sizeof(cellData), &cellData));
        checkCLError(clSetKernelArg(kernel, arg++, sizeof(directionData), &directionData));
        
        size_t globalSize = sharedDirectionData.length;
        checkCLError(clEnqueueNDRangeKernel(queue.command_queue, kernel, 1, NULL, &globalSize, NULL, 0, NULL, NULL));
        checkCLError(clFinish(queue.command_queue));
    }
    
    [sharedDirectionData copyFromDevice:queue];
    
    for (int i = 0; i < system.sourceBranches.count; ++i) {
        SourceBranch *branch = system.sourceBranches[i];
        
        cl_float3 newDirection;
        newDirection.x = sharedDirectionData.hostData[i].x;
        newDirection.y = sharedDirectionData.hostData[i].y;
        newDirection.z = sharedDirectionData.hostData[i].z;
        
        branch.direction = newDirection;
    }
}

- (void)dealloc {
    clReleaseKernel(kernel);
}

@end
