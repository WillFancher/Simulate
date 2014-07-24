//
//  OpenGLView.m
//  Simulate
//
//  Created by Will Fancher on 7/21/14.
//
//

#import "OpenGLView.h"
#import "OpenCLQueue.h"
#import "ProliferatingSystem.h"
#import "test.cl.h"

#import <OpenGL/gl.h>
#import <OpenGL/gl3.h>

#define NUM_ITERATIONS 140

@interface OpenGLView () {
    GLuint vao;
    GLuint points_vbo;
    GLuint colors_vbo;
    GLuint shaderProgram;
    
    cl_context context;
    dispatch_queue_t cl_queue;
    cl_command_queue command_queue;
    cl_kernel kernel;
    cl_mem cl_colors;
    
    NSDate *start;
}

@end

@implementation OpenGLView

- (void)prepareOpenGL {
    [self setupTimer];
    start = [NSDate date];
    [self glinit];
    [self clinit];
}

- (void)glinit {
    printf("Using OpenGL version: %s\n", glGetString(GL_VERSION));
    static GLfloat points[] = {
        0.0f,  0.5f,  0.0f,
        0.5f, -0.5f,  0.0f,
        -0.5f, -0.5f,  0.0f
    };
    static GLfloat colors[] = {
        1.0f, 0.0f,  0.0f, 1.0f,
        0.0f, 1.0f,  0.0f, 1.0f,
        0.0f, 0.0f,  1.0f, 1.0f
    };
    
    glGenBuffers(1, &points_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, points_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW);
    
    glGenBuffers(1, &colors_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, colors_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(colors), colors, GL_STATIC_DRAW);
    
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, points_vbo);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glBindBuffer(GL_ARRAY_BUFFER, colors_vbo);
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    
    shaderProgram = glCreateProgram();
    
    [self loadShaderForResource:@"vertex" ofType:GL_VERTEX_SHADER];
    [self loadShaderForResource:@"fragment" ofType:GL_FRAGMENT_SHADER];
    
    glLinkProgram(shaderProgram);
    glValidateProgram(shaderProgram);
    
    GLsizei logLen;
    glGetProgramiv(shaderProgram, GL_INFO_LOG_LENGTH, &logLen);
    if (logLen > 0) {
        GLchar info[logLen+1];
        glGetProgramInfoLog(shaderProgram, logLen, &logLen, info);
        fprintf(stderr, "%s\n", info);
    }
    glFinish();
}

- (void)clinit {
    int err;
    CGLShareGroupObj kCGLShareGroup = CGLGetShareGroup(self.openGLContext.CGLContextObj);
    gcl_gl_set_sharegroup(kCGLShareGroup);
    
    cl_queue = gcl_create_dispatch_queue(CL_DEVICE_TYPE_ALL, NULL);
    context = gcl_get_context();
    cl_colors = clCreateFromGLBuffer(context, CL_MEM_READ_WRITE, colors_vbo, &err);
    command_queue = clCreateCommandQueue(context, gcl_get_device_id_with_dispatch_queue(cl_queue), 0, &err);
    kernel = gcl_create_kernel_from_block((__bridge void *)(test_kernel));
    clFinish(command_queue);
    
//    dispatch_queue_t q = dispatch_queue_create("edu.louisville.simulate.1", NULL);
//    OpenCLQueue *queue = [[OpenCLQueue alloc] initWithCGLContext:self.openGLContext.CGLContextObj];
//    [queue printAvailableDevices];
//    printf("\nUsing device:\n\n");
//    [queue printDeviceInfo];
//    printf("\n\n");
//    
//    dispatch_async(q, ^{
//        ProliferatingSystem *system = [[ProliferatingSystem alloc] init];
//        
//        for (int i = 0; i < NUM_ITERATIONS; ++i) {
//            printf("%d:\t%d\tliving cells\n", i, [system livingCells]);
//            [system stepWithQueue:queue];
//        }
//        printf("Final:\t%d\tliving cells\n", [system livingCells]);
//    });
}

- (void)loadShaderForResource:(NSString *)resource ofType:(GLenum)type {
    GLuint shader = glCreateShader(type);
    const GLchar *text = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:resource
                                                                                             ofType:type == GL_VERTEX_SHADER ? @"vs" : type == GL_FRAGMENT_SHADER ? @"fs" : nil]
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil] UTF8String];
    glShaderSource(shader, 1, &text, NULL);
    glCompileShader(shader);
    glAttachShader(shaderProgram, shader);
}

- (const GLchar *)textForResource:(NSString *)resource ofType:(NSString *)type {
    return [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:resource ofType:type] encoding:NSUTF8StringEncoding error:nil] UTF8String];
}

- (void)drawRect:(NSRect)dirtyRect {
    [self cl_execute];
    
    glEnable(GL_BLEND);
    glBlendFuncSeparate(GL_ONE, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ZERO);
    
    glClearColor(0, 0, .29, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    glUseProgram(shaderProgram);
    
    glBindVertexArray(vao);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    glFinish();
}

- (void)cl_execute {
    cl_float time = [start timeIntervalSinceNow];
    
    clEnqueueAcquireGLObjects(command_queue, 1, &cl_colors, 0, NULL, NULL);
    
    clSetKernelArg(kernel, 0, sizeof(cl_mem), &cl_colors);
    clSetKernelArg(kernel, 1, sizeof(cl_float), &time);
    
    size_t global_size = 3;
    clEnqueueNDRangeKernel(command_queue, kernel, 1, NULL, &global_size, NULL, 0, NULL, NULL);
    
    clEnqueueReleaseGLObjects(command_queue, 1, &cl_colors, 0, NULL, NULL);
    clFinish(command_queue);
}

- (void)setupTimer
{
    NSTimer *renderTimer = [NSTimer timerWithTimeInterval:0.001   //a 1ms time interval
                                          target:self
                                        selector:@selector(timerFired:)
                                        userInfo:nil
                                         repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:renderTimer
                                 forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:renderTimer
                                 forMode:NSEventTrackingRunLoopMode]; //Ensure timer fires during resize
}

// Timer callback method
- (void)timerFired:(id)sender
{
    // It is good practice in a Cocoa application to allow the system to send the -drawRect:
    // message when it needs to draw, and not to invoke it directly from the timer.
    // All we do here is tell the display it needs a refresh
    [self setNeedsDisplay:YES];
}

@end
