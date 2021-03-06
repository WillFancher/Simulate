//
//  SimulationView.m
//  Simulate
//
//  Created by Will Fancher on 7/30/14.
//
//

#import "SimulationView.h"
#import "make_image.cl.h"
#import "zero_image_alpha.cl.h"
#import "OpenCLQueue.h"
#import "ChunkedProliferatingSystem.h"
@import GLKit;
@import GLUT;
@import OpenCL;

#define NUM_ITERATIONS 75

@interface SimulationView () {
    GLKBaseEffect *effect;
    float xrot, yrot;
    CGPoint mousePos;
    float scale;
    
    float totalRadius;
    float pointRadius;
    int numGLPoints;
    NSTimer *glTimer;
    
    GLfloat *points;
    GLfloat *colors;
    
    GLuint vao;
    GLuint points_vbo;
    GLuint colors_vbo;
    
    cl_kernel make_image_cl_kernel;
    cl_kernel zero_image_cl_kernel;
    cl_mem cl_colors;
    cl_mem cl_points;
    
    OpenCLQueue *queue;
    ChunkedProliferatingSystem *system;
    
    NSLock *lock;
    BOOL glInitialized;
}

@end

@implementation SimulationView

- (void)awakeFromNib {
    lock = [[NSLock alloc] init];
    glInitialized = NO;
}

- (void)prepareOpenGL {
    queue = [[OpenCLQueue alloc] initWithCGLContext:self.openGLContext.CGLContextObj];
    [queue printAvailableDevices];
    printf("\nUsing device:\n\n");
    [queue printDeviceInfo];
    printf("\n\n");
    system = [[ChunkedProliferatingSystem alloc] initWithQueue:queue];
    
    [self glinit];
    [self clinit];
}

- (void)gl_time:(id)sender {
    [self setNeedsDisplay:YES];
}

- (void)glinit {
    glTimer = [NSTimer timerWithTimeInterval:0.001
                                      target:self
                                    selector:@selector(gl_time:)
                                    userInfo:nil
                                     repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:glTimer
                                 forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:glTimer
                                 forMode:NSEventTrackingRunLoopMode];
    
    [self.openGLContext makeCurrentContext];
    printf("Using OpenGL version: %s\n", glGetString(GL_VERSION));
    xrot = 20;
    yrot = 20;
    mousePos = CGPointZero;
    scale = 3;
    
    effect = [[GLKBaseEffect alloc] init];
    
    
    pointRadius = 0.5;
    totalRadius = 25;
    int count = 0;
    numGLPoints = ceil(pow(1 + 2 * totalRadius / (pointRadius * 2), 3));
    
    points = malloc(numGLPoints * 3 * sizeof(GLfloat));
    colors = malloc(numGLPoints * 4 * sizeof(GLfloat));
    
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
    glBufferData(GL_ARRAY_BUFFER, numGLPoints * 3 * sizeof(GLfloat), points, GL_STATIC_DRAW);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    glGenBuffers(1, &colors_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, colors_vbo);
    glBufferData(GL_ARRAY_BUFFER, numGLPoints * 4 * sizeof(GLfloat), colors, GL_STATIC_DRAW);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    glFinish();
    
    glInitialized = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    if (!glInitialized) {
        return;
    }
    
    @synchronized(lock) {
        [self.openGLContext makeCurrentContext];
        
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
        modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, scale * 0.2 / totalRadius, scale * 0.2 / totalRadius, scale * 0.2 / totalRadius);
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, xrot, 0, 1, 0);
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, yrot, 1, 0, 0);
        effect.transform.modelviewMatrix = modelViewMatrix;
        [effect prepareToDraw];
        
        glBindVertexArray(vao);
        glPointSize(pointRadius * 4);
        glDrawArrays(GL_POINTS, 0, numGLPoints);
        
        [self renderSources];
        
        if (glGetError()) {
            printf("GLError: %s\n", gluErrorString(glGetError()));
        }
    }
}

- (void)renderSources {
    GLuint sources_vao;
    GLuint sources_points_vbo;
    GLuint sources_colors_vbo;
    
    int len = system.sourceData.length;
    
    size_t pointSize = len * 3 * sizeof(GLfloat);
    GLfloat *sources_points = malloc(pointSize);
    size_t colorSize = len * 4 * sizeof(GLfloat);
    GLfloat *sources_colors = malloc(colorSize);
    for (int i = 0; i < len; ++i) {
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
    glBufferData(GL_ARRAY_BUFFER, pointSize, sources_points, GL_STATIC_DRAW);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    glGenBuffers(1, &sources_colors_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, sources_colors_vbo);
    glBufferData(GL_ARRAY_BUFFER, colorSize, sources_colors, GL_STATIC_DRAW);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    glBindVertexArray(sources_vao);
    glDisable(GL_DEPTH_TEST);
    glDrawArrays(GL_POINTS, 0, system.sourceData.length);
    
    glFinish();
    
    glDeleteBuffers(1, &sources_points_vbo);
    glDeleteBuffers(1, &sources_colors_vbo);
    glDeleteVertexArrays(1, &sources_vao);
    
    glFinish();
    
    free(sources_points);
    free(sources_colors);
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

- (void)scrollWheel:(NSEvent *)theEvent {
    scale += [theEvent deltaY];
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
    
    [queue dispatchAsynchronous:^{
        int i = 0;
        while (true) {
            printf("%d:\t%d\tliving cells\t%lu\tchunks\n\t%d\tsources\t\t%d\tbranches\n",
                   ++i,
                   [system livingCells],
                   (unsigned long)system.cellData.count,
                   system.sourceData.length,
                   (int)system.sourceBranches.count);
            [self cl_execute];
            [self saveDensitiesToFile: [NSString stringWithFormat:@"%d.txt", i]];
        }
    }];
}

- (void)cl_execute {
    [system step];
    
    @synchronized(lock) {
        checkCLError(clEnqueueAcquireGLObjects(queue.command_queue, 1, &cl_points, 0, NULL, NULL));
        checkCLError(clEnqueueAcquireGLObjects(queue.command_queue, 1, &cl_colors, 0, NULL, NULL));
        
        checkCLError(clSetKernelArg(zero_image_cl_kernel, 0, sizeof(cl_colors), &cl_colors));
        size_t zeroAlphaGlobalSize = numGLPoints;
        checkCLError(clEnqueueNDRangeKernel(queue.command_queue, zero_image_cl_kernel, 1, NULL, &zeroAlphaGlobalSize, NULL, 0, NULL, NULL));
        checkCLError(clFinish(queue.command_queue));
        
        for (SharedFloat4Data *chunk in system.cellData) {
            cl_mem chunkMem = chunk.deviceData;
            cl_int numCells = chunk.length;
            
            checkCLError(clSetKernelArg(make_image_cl_kernel, 0, sizeof(chunkMem), &chunkMem));
            checkCLError(clSetKernelArg(make_image_cl_kernel, 1, sizeof(numCells), &numCells));
            checkCLError(clSetKernelArg(make_image_cl_kernel, 2, sizeof(cl_points), &cl_points));
            checkCLError(clSetKernelArg(make_image_cl_kernel, 3, sizeof(cl_colors), &cl_colors));
            checkCLError(clSetKernelArg(make_image_cl_kernel, 4, sizeof(pointRadius), &pointRadius));
            
            size_t global_size = numGLPoints;
            checkCLError(clEnqueueNDRangeKernel(queue.command_queue, make_image_cl_kernel, 1, NULL, &global_size, NULL, 0, NULL, NULL));
            
            checkCLError(clFinish(queue.command_queue));
        }
        
        checkCLError(clEnqueueReadBuffer(queue.command_queue, cl_points, CL_TRUE, 0, numGLPoints * 3 * sizeof(GLfloat), points, 0, NULL, NULL));
        checkCLError(clEnqueueReadBuffer(queue.command_queue, cl_colors, CL_TRUE, 0, numGLPoints * 4 * sizeof(GLfloat), colors, 0, NULL, NULL));
        
        checkCLError(clEnqueueReleaseGLObjects(queue.command_queue, 1, &cl_points, 0, NULL, NULL));
        checkCLError(clEnqueueReleaseGLObjects(queue.command_queue, 1, &cl_colors, 0, NULL, NULL));
        checkCLError(clFinish(queue.command_queue));
    }
}

- (void)saveDensitiesToFile:(NSString *)path {
    NSMutableString *str = [NSMutableString string];
    for (int i = 0; i < numGLPoints; ++i) {
        if (colors[i * 4 + 3] != 0) {
            [str appendFormat:@"%d %d %d %f\n", (int)points[i * 3], (int)points[i * 3 + 1], (int)points[i * 3 + 2], colors[i * 4 + 3]];
        }
    }
    [str writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)dealloc {
    free(points);
    free(colors);
}

@end
