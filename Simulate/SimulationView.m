//
//  SimulationView.m
//  Simulate
//
//  Created by Will Fancher on 7/30/14.
//
//

#import "SimulationView.h"
#import "test.cl.h"
#import "make_image.cl.h"
#import "zero_image_alpha.cl.h"
#import "OpenCLQueue.h"
#import "ChunkedProliferatingSystem.h"
@import GLKit;
@import OpenGL;
@import OpenCL;

#define NUM_ITERATIONS 75

@interface SimulationView () {
    GLKBaseEffect *effect;
    NSDate *start;
    float xrot, yrot;
    CGPoint mousePos;
    
    float totalRadius;
    float pointRadius;
    int numGLPoints;
    NSTimer *glTimer;
    
    GLuint vao;
    GLuint points_vbo;
    GLuint colors_vbo;
    
    GLuint sources_vao;
    GLuint sources_points_vbo;
    GLuint sources_colors_vbo;
    
    cl_kernel make_image_cl_kernel;
    cl_kernel zero_image_cl_kernel;
    cl_mem cl_colors;
    cl_mem cl_points;
    
    OpenCLQueue *queue;
    ChunkedProliferatingSystem *system;
    int iteration;
    NSTimer *clTimer;
}

@end

@implementation SimulationView

- (void)prepareOpenGL {
    iteration = 0;
    queue = [[OpenCLQueue alloc] initWithCGLContext:self.openGLContext.CGLContextObj];
    [queue printAvailableDevices];
    printf("\nUsing device:\n\n");
    [queue printDeviceInfo];
    printf("\n\n");
    system = [[ChunkedProliferatingSystem alloc] init];
    
    start = [NSDate date];
    [self setupTimer];
    [self glinit];
    [self clinit];
}

- (void)setupTimer {
    clTimer = [NSTimer timerWithTimeInterval:0.001   //a 1ms time interval
                                      target:self
                                    selector:@selector(cl_execute:)
                                    userInfo:nil
                                     repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:clTimer
                                 forMode:NSDefaultRunLoopMode];
    
    glTimer = [NSTimer timerWithTimeInterval:0.001
                                      target:self
                                    selector:@selector(gl_time:)
                                    userInfo:nil
                                     repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:glTimer
                                 forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:glTimer
                                 forMode:NSEventTrackingRunLoopMode];
}

- (void)gl_time:(id)sender {
    [self setNeedsDisplay:YES];
}

- (void)glinit {
    [self.openGLContext makeCurrentContext];
    printf("Using OpenGL version: %s\n", glGetString(GL_VERSION));
    xrot = 0;
    yrot = 0;
    mousePos = CGPointZero;
    
    effect = [[GLKBaseEffect alloc] init];
    
    
    pointRadius = 5;
    totalRadius = 100;
    int count = 0;
    numGLPoints = ceil(pow(1 + 2 * totalRadius / (pointRadius * 2), 3));
    
    GLfloat points[numGLPoints * 3];
    GLfloat colors[numGLPoints * 4];
    
    for (int x = -totalRadius; x <= totalRadius; x += pointRadius * 2) {
        for (int y = -totalRadius; y <= totalRadius; y += pointRadius * 2) {
            for (int z = -totalRadius; z <= totalRadius; z += pointRadius * 2) {
                points[count * 3 + 0] = x;
                points[count * 3 + 1] = y;
                points[count * 3 + 2] = z;
                
                colors[count * 4 + 0] = 1;
                colors[count * 4 + 1] = 1;
                colors[count * 4 + 2] = 1;
                colors[count * 4 + 3] = 1;
                
                ++count;
            }
        }
    }
    
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    
    glGenBuffers(1, &points_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, points_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    glGenBuffers(1, &colors_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, colors_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(colors), colors, GL_STATIC_DRAW);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    
    
    
    GLfloat sources_points[system.sourceData.length * 3];
    GLfloat sources_colors[system.sourceData.length * 4];
    for (int i = 0; i < system.sourceData.length; ++i) {
        sources_points[i * 3 + 0] = system.sourceData.hostData[i].x;
        sources_points[i * 3 + 1] = system.sourceData.hostData[i].y;
        sources_points[i * 3 + 2] = system.sourceData.hostData[i].z;
        
        sources_colors[i * 4 + 0] = 1;
        sources_colors[i * 4 + 1] = 0;
        sources_colors[i * 4 + 2] = 0;
        sources_colors[i * 4 + 3] = 1;
    }
    
    glGenVertexArrays(1, &sources_vao);
    glBindVertexArray(sources_vao);
    
    glGenBuffers(1, &sources_points_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, sources_points_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sources_points), sources_points, GL_STATIC_DRAW);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    glGenBuffers(1, &sources_colors_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, sources_colors_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sources_colors), sources_colors, GL_STATIC_DRAW);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    glFinish();
}

- (void)drawRect:(NSRect)dirtyRect {
    glEnable(GL_BLEND);
    glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ZERO);
    
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    
    glClearColor(.5, .5, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
//    float aspect = fabsf(self.bounds.size.width / self.bounds.size.height);
//    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(0, aspect, -1, 1);
//    effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 0.5 / totalRadius, 0.5 / totalRadius, 0.5 / totalRadius);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, xrot, 0, 1, 0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, yrot, 1, 0, 0);
    effect.transform.modelviewMatrix = modelViewMatrix;
    [effect prepareToDraw];
    
    glBindVertexArray(vao);
    glPointSize(5);
    glDrawArrays(GL_POINTS, 0, numGLPoints);
    
    glBindVertexArray(sources_vao);
    glDisable(GL_DEPTH_TEST);
//    glDrawArrays(GL_POINTS, 0, system.sourceData.length);
    
    glFinish();
}

- (void)mouseDown:(NSEvent *)theEvent {
    mousePos = [theEvent locationInWindow];
}

- (void)mouseDragged:(NSEvent *)theEvent {
    CGPoint pos = [theEvent locationInWindow];
    xrot += (mousePos.x - pos.x) * .01;
    yrot += (mousePos.y - pos.y) * .01;
    mousePos = pos;
}



// OpenCL Code

- (void)clinit {
    char openCLVersion[150];
    checkCLError(clGetPlatformInfo(NULL, CL_PLATFORM_VERSION, sizeof(openCLVersion), openCLVersion, NULL));
    printf("Using OpenCL version: %s\n", openCLVersion);
    
    int err;
    
    cl_colors = clCreateFromGLBuffer(queue.context, CL_MEM_READ_WRITE, colors_vbo, &err);
    checkCLError(err);
    cl_points = clCreateFromGLBuffer(queue.context, CL_MEM_READ_WRITE, points_vbo, &err);
    checkCLError(err);
    make_image_cl_kernel = gcl_create_kernel_from_block((__bridge void *)(make_image_kernel));
    zero_image_cl_kernel = gcl_create_kernel_from_block((__bridge void *)(zero_image_alpha_kernel));
    checkCLError(clFinish(queue.command_queue));
}

- (void)cl_execute:(id)sender {
    [queue dispatchAsynchronous:^{
        if (iteration >= NUM_ITERATIONS) {
            [clTimer invalidate];
            return;
        }
        printf("%d:\t%d\tliving cells\t%lu\tchunks\n", iteration, [system livingCells], (unsigned long)system.cellData.count);
        [system stepWithQueue:queue];
        
        checkCLError(clEnqueueAcquireGLObjects(queue.command_queue, 1, &cl_points, 0, NULL, NULL));
        checkCLError(clEnqueueAcquireGLObjects(queue.command_queue, 1, &cl_colors, 0, NULL, NULL));
        
        checkCLError(clSetKernelArg(zero_image_cl_kernel, 0, sizeof(cl_colors), &cl_colors));
        size_t zeroAlphaGlobalSize = numGLPoints;
        checkCLError(clEnqueueNDRangeKernel(queue.command_queue, zero_image_cl_kernel, 1, NULL, &zeroAlphaGlobalSize, NULL, 0, NULL, NULL));
        checkCLError(clFinish(queue.command_queue));
        
        for (SharedFloat4Data *chunk in system.cellData) {
            cl_mem chunkMem = gcl_create_buffer_from_ptr(chunk.deviceData);
            cl_int numCells = chunk.length;
            
            checkCLError(clSetKernelArg(make_image_cl_kernel, 0, sizeof(chunkMem), &chunkMem));
            checkCLError(clSetKernelArg(make_image_cl_kernel, 1, sizeof(numCells), &numCells));
            checkCLError(clSetKernelArg(make_image_cl_kernel, 2, sizeof(cl_points), &cl_points));
            checkCLError(clSetKernelArg(make_image_cl_kernel, 3, sizeof(cl_colors), &cl_colors));
            checkCLError(clSetKernelArg(make_image_cl_kernel, 4, sizeof(pointRadius), &pointRadius));
            
            size_t global_size = numGLPoints;
            checkCLError(clEnqueueNDRangeKernel(queue.command_queue, make_image_cl_kernel, 1, NULL, &global_size, NULL, 0, NULL, NULL));
            
            checkCLError(clReleaseMemObject(chunkMem));
            checkCLError(clFinish(queue.command_queue));
        }
        
        checkCLError(clEnqueueReleaseGLObjects(queue.command_queue, 1, &cl_points, 0, NULL, NULL));
        checkCLError(clEnqueueReleaseGLObjects(queue.command_queue, 1, &cl_colors, 0, NULL, NULL));
        checkCLError(clFinish(queue.command_queue));
        
        ++iteration;
        [self setNeedsDisplay:YES];
    }];
}

@end
