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
#import <GLKit/GLKit.h>

#define NUM_ITERATIONS 140

static NSString *descriptionOfCLError(cl_int err) {
    switch (err) {
        case CL_SUCCESS:                            return @"Success!";
        case CL_DEVICE_NOT_FOUND:                   return @"Device not found.";
        case CL_DEVICE_NOT_AVAILABLE:               return @"Device not available";
        case CL_COMPILER_NOT_AVAILABLE:             return @"Compiler not available";
        case CL_MEM_OBJECT_ALLOCATION_FAILURE:      return @"Memory object allocation failure";
        case CL_OUT_OF_RESOURCES:                   return @"Out of resources";
        case CL_OUT_OF_HOST_MEMORY:                 return @"Out of host memory";
        case CL_PROFILING_INFO_NOT_AVAILABLE:       return @"Profiling information not available";
        case CL_MEM_COPY_OVERLAP:                   return @"Memory copy overlap";
        case CL_IMAGE_FORMAT_MISMATCH:              return @"Image format mismatch";
        case CL_IMAGE_FORMAT_NOT_SUPPORTED:         return @"Image format not supported";
        case CL_BUILD_PROGRAM_FAILURE:              return @"Program build failure";
        case CL_MAP_FAILURE:                        return @"Map failure";
        case CL_INVALID_VALUE:                      return @"Invalid value";
        case CL_INVALID_DEVICE_TYPE:                return @"Invalid device type";
        case CL_INVALID_PLATFORM:                   return @"Invalid platform";
        case CL_INVALID_DEVICE:                     return @"Invalid device";
        case CL_INVALID_CONTEXT:                    return @"Invalid context";
        case CL_INVALID_QUEUE_PROPERTIES:           return @"Invalid queue properties";
        case CL_INVALID_COMMAND_QUEUE:              return @"Invalid command queue";
        case CL_INVALID_HOST_PTR:                   return @"Invalid host pointer";
        case CL_INVALID_MEM_OBJECT:                 return @"Invalid memory object";
        case CL_INVALID_IMAGE_FORMAT_DESCRIPTOR:    return @"Invalid image format descriptor";
        case CL_INVALID_IMAGE_SIZE:                 return @"Invalid image size";
        case CL_INVALID_SAMPLER:                    return @"Invalid sampler";
        case CL_INVALID_BINARY:                     return @"Invalid binary";
        case CL_INVALID_BUILD_OPTIONS:              return @"Invalid build options";
        case CL_INVALID_PROGRAM:                    return @"Invalid program";
        case CL_INVALID_PROGRAM_EXECUTABLE:         return @"Invalid program executable";
        case CL_INVALID_KERNEL_NAME:                return @"Invalid kernel name";
        case CL_INVALID_KERNEL_DEFINITION:          return @"Invalid kernel definition";
        case CL_INVALID_KERNEL:                     return @"Invalid kernel";
        case CL_INVALID_ARG_INDEX:                  return @"Invalid argument index";
        case CL_INVALID_ARG_VALUE:                  return @"Invalid argument value";
        case CL_INVALID_ARG_SIZE:                   return @"Invalid argument size";
        case CL_INVALID_KERNEL_ARGS:                return @"Invalid kernel arguments";
        case CL_INVALID_WORK_DIMENSION:             return @"Invalid work dimension";
        case CL_INVALID_WORK_GROUP_SIZE:            return @"Invalid work group size";
        case CL_INVALID_WORK_ITEM_SIZE:             return @"Invalid work item size";
        case CL_INVALID_GLOBAL_OFFSET:              return @"Invalid global offset";
        case CL_INVALID_EVENT_WAIT_LIST:            return @"Invalid event wait list";
        case CL_INVALID_EVENT:                      return @"Invalid event";
        case CL_INVALID_OPERATION:                  return @"Invalid operation";
        case CL_INVALID_GL_OBJECT:                  return @"Invalid OpenGL object";
        case CL_INVALID_BUFFER_SIZE:                return @"Invalid buffer size";
        case CL_INVALID_MIP_LEVEL:                  return @"Invalid mip-map level";
        default: return @"Unknown";
    }
}

static void checkCLError(cl_int err) {
    if (err) {
        NSString *errStr = descriptionOfCLError(err);
        @throw [NSException exceptionWithName:@"OpenCL error" reason:errStr userInfo:nil];
    }
}

@interface OpenGLView () {
    GLuint vao;
    GLuint points_vbo;
    GLuint colors_vbo;
    GLuint shaderProgram;
    
    CGPoint mouseLocation;
    GLKBaseEffect *effect;
    
    cl_context context;
    dispatch_queue_t cl_queue;
    cl_command_queue command_queue;
    cl_kernel kernel;
    cl_mem cl_colors;
    cl_mem cl_points;
    
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

- (void)hey {
    printf("Using OpenGL version: %s\n", glGetString(GL_VERSION));
    int scale = 5;
    int count = 0;
    for (int x = -scale; x < scale; ++x) {
        for (int y = -scale; y < scale; ++y) {
            for (int z = -scale; z < scale; ++z) {
                
                
                count++;
            }
        }
    }
}

- (void)glinit {
    effect = [[GLKBaseEffect alloc] init];
//    effect.lightingType = GLKLightingTypePerPixel;
//    
//    // Turn on the first light
//    effect.light0.enabled = GL_TRUE;
//    effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
//    effect.light0.position = GLKVector4Make(-5.f, -5.f, 10.f, 1.0f);
//    effect.light0.specularColor = GLKVector4Make(1.0f, 0.0f, 0.0f, 1.0f);
//    
//    // Turn on the second light
//    effect.light1.enabled = GL_TRUE;
//    effect.light1.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
//    effect.light1.position = GLKVector4Make(15.f, 15.f, 10.f, 1.0f);
//    effect.light1.specularColor = GLKVector4Make(1.0f, 0.0f, 0.0f, 1.0f);
//    
//    // Set material
//    effect.material.diffuseColor = GLKVector4Make(0.f, 0.5f, 1.0f, 1.0f);
//    effect.material.ambientColor = GLKVector4Make(0.0f, 0.5f, 0.0f, 1.0f);
//    effect.material.specularColor = GLKVector4Make(1.0f, 0.0f, 0.0f, 1.0f);
//    effect.material.shininess = 20.0f;
//    effect.material.emissiveColor = GLKVector4Make(0.2f, 0.f, 0.2f, 1.0f);
    
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
    
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    
    glGenBuffers(1, &points_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, points_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glGenBuffers(1, &colors_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, colors_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(colors), colors, GL_STATIC_DRAW);
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
    char openCLVersion[150];
    checkCLError(clGetPlatformInfo(NULL, CL_PLATFORM_VERSION, sizeof(openCLVersion), openCLVersion, NULL));
    printf("Using OpenCL version: %s\n", openCLVersion);
    
    int err;
    CGLShareGroupObj kCGLShareGroup = CGLGetShareGroup(self.openGLContext.CGLContextObj);
    gcl_gl_set_sharegroup(kCGLShareGroup);
    
    cl_queue = gcl_create_dispatch_queue(CL_DEVICE_TYPE_ALL, NULL);
    context = gcl_get_context();
    cl_colors = clCreateFromGLBuffer(context, CL_MEM_READ_WRITE, colors_vbo, &err);
    checkCLError(err);
    cl_points = clCreateFromGLBuffer(context, CL_MEM_READ_WRITE, points_vbo, &err);
    checkCLError(err);
    command_queue = clCreateCommandQueue(context, gcl_get_device_id_with_dispatch_queue(cl_queue), 0, &err);
    checkCLError(err);
    kernel = gcl_create_kernel_from_block((__bridge void *)(test_kernel));
    checkCLError(clFinish(command_queue));
    
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

- (void)drawRect:(NSRect)dirtyRect {
    [self cl_execute];
    
    glEnable(GL_BLEND);
    glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ZERO);
    
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    
    glClearColor(0, 0, .29, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glMatrixMode(GL_MODELVIEW);
    
    float aspect = fabsf(self.bounds.size.width / self.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    effect.transform.projectionMatrix = projectionMatrix;
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    effect.transform.modelviewMatrix = modelViewMatrix;
    [effect prepareToDraw];
    
    glBindVertexArray(vao);
    glPointSize(5);
    glDrawArrays(GL_POINTS, 0, 3);
    
    glFinish();
}

- (void)cl_execute {
    cl_float time = -[start timeIntervalSinceNow];
    
    checkCLError(clEnqueueAcquireGLObjects(command_queue, 1, &cl_colors, 0, NULL, NULL));
    
    checkCLError(clSetKernelArg(kernel, 0, sizeof(cl_mem), &cl_colors));
    checkCLError(clSetKernelArg(kernel, 1, sizeof(cl_mem), &cl_points));
    checkCLError(clSetKernelArg(kernel, 2, sizeof(cl_float), &time));
    
    size_t global_size = 3;
    checkCLError(clEnqueueNDRangeKernel(command_queue, kernel, 1, NULL, &global_size, NULL, 0, NULL, NULL));
    
    checkCLError(clEnqueueReleaseGLObjects(command_queue, 1, &cl_colors, 0, NULL, NULL));
    checkCLError(clFinish(command_queue));
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

- (void)mouseDragged:(NSEvent *)theEvent {
    CGPoint oldLocation = mouseLocation;
    mouseLocation = [theEvent locationInWindow];
}

@end
