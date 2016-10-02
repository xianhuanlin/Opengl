//
//  skyboxView.m
//  VideoPlayDemo
//
//  Created by lin xianhuan on 2016/10/2.
//  Copyright © 2016年 lin xianhuan. All rights reserved.
//

#import "skyboxView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGL.h>
#import <QuartzCore/QuartzCore.h>
#import <GLKit/GLKit.h>

static const GLchar *shaderVetex = "res/shaders/skybox/skybox.vert";
static const GLchar *shaderFragment = "res/shaders/skybox/skybox.frag";

static const GLfloat skyboxVertices[] = {
    -1.0f, 1.0f, -1.0f,
    -1.0f, -1.0f, -1.0f,
    1.0f, -1.0f, -1.0f,
    1.0f, -1.0f, -1.0f,
    1.0f, 1.0f, -1.0f,
    -1.0f, 1.0f, -1.0f,
    
    -1.0f, -1.0f, 1.0f,
    -1.0f, -1.0f, -1.0f,
    -1.0f, 1.0f, -1.0f,
    -1.0f, 1.0f, -1.0f,
    -1.0f, 1.0f, 1.0f,
    -1.0f, -1.0f, 1.0f,
    
    1.0f, -1.0f, -1.0f,
    1.0f, -1.0f, 1.0f,
    1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, -1.0f,
    1.0f, -1.0f, -1.0f,
    
    -1.0f, -1.0f, 1.0f,
    -1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f,
    1.0f, -1.0f, 1.0f,
    -1.0f, -1.0f, 1.0f,
    
    -1.0f, 1.0f, -1.0f,
    1.0f, 1.0f, -1.0f,
    1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f,
    -1.0f, 1.0f, 1.0f,
    -1.0f, 1.0f, -1.0f,
    
    -1.0f, -1.0f, -1.0f,
    -1.0f, -1.0f, 1.0f,
    1.0f, -1.0f, -1.0f,
    1.0f, -1.0f, -1.0f,
    -1.0f, -1.0f, 1.0f,
    1.0f, -1.0f, 1.0f
};


@implementation skyboxView{
    CADisplayLink           *_displayLink;
    
    EAGLContext             *_context;
    
    GLuint                  _renderBuffer;
    GLuint                  _textureSkyBox;
    GLuint                  _vertexBuffer;
    GLuint                  _indexBuffer;
    GLuint                  _program;
    NSData                  *_buf;
    int                     _imageWidth;
    int                     _imageHight;
    
    GLKMatrix4              _matrixView;
    GLKMatrix4              _matrixProj;
}



- (void)setupVBO
{
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(skyboxVertices), skyboxVertices, GL_DYNAMIC_DRAW);
}

- (void)setupShaders{
    // Read vertex shader source
    NSString *vertexShaderSource = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"skybox" ofType:@"vert"] encoding:NSUTF8StringEncoding error:nil];
    const char *vertexShaderSourceCString = [vertexShaderSource cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Create and compile vertex shader
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSourceCString, NULL);
    glCompileShader(vertexShader);
    
    // Read fragment shader source
    NSString *fragmentShaderSource = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"skybox" ofType:@"frag"] encoding:NSUTF8StringEncoding error:nil];
    const char *fragmentShaderSourceCString = [fragmentShaderSource cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Create and compile fragment shader
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSourceCString, NULL);
    glCompileShader(fragmentShader);
    
    // Create and link program
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    
    // Use program
    glUseProgram(program);
    
    _program = program;
}

- (void)setupMatrix{
    _matrixView = GLKMatrix4MakeLookAt(0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f);
    
    _matrixProj = GLKMatrix4MakePerspective(M_PI/8, [UIScreen mainScreen].bounds.size.width/[UIScreen mainScreen].bounds.size.height , 1.0f, 5000.0f);
}

- (void) initOpenGL
{
    if([UIApplication sharedApplication].applicationState !=UIApplicationStateActive){
        return;
    }
    
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    // Create a framebuffer
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    
    glGenTextures(1, &_textureSkyBox);

    
    [self setupVBO];
    [self setupShaders];
    [self setupMatrix];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startDisplay];
    });
}

- (void)drawTexture{
    glDepthFunc(GL_LEQUAL);  // Change depth function so depth test passes when values are equal to depth buffer's content
   
    glBindTexture(GL_TEXTURE_CUBE_MAP, _textureSkyBox);
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    glDepthFunc(GL_LESS);
}

+ (Class)layerClass{
    return [CAEAGLLayer class];
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    
    [self initOpenGL];
    
    return self;
}

- (void)startDisplay
{
    if (_displayLink != nil)
    {
        [self stopDisplay];
    }
    
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = NO;
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(display)];
    _displayLink.frameInterval = 2;
    
    [_displayLink addToRunLoop: [NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
}

- (void)stopDisplay
{
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
}

- (void)display
{
   // CGRect rect = [UIScreen mainScreen].bounds;

    glUniformMatrix4fv(glGetUniformLocation(_program, "view"), 1, GL_FALSE, _matrixView.m);
    glUniformMatrix4fv(glGetUniformLocation(_program, "projection"), 1, GL_FALSE, _matrixProj.m);
    
    glClearColor(1.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self drawTexture];
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)updateDrawingRect:(CGRect)rect{
    
}

- (void)updateTexture{

}

-(void)OnVideoDecodeCallback:(void*)buf len:(int)len w:(int)width h:(int)height{
    @synchronized (self) {
        @autoreleasepool {
            _buf = [NSData dataWithBytes:buf length:len];
        }
        
        _imageWidth = width;
        _imageHight = height;
    }
}

+ (skyboxView*)Create:(UIView*)parent{
    
    skyboxView*p = [[skyboxView alloc]initWithFrame:parent.frame];
    [parent addSubview:p];
    
    return p;
}

- (void)loadSkyBox:(NSArray*)arr{
    
    for (int n = 0; n < arr.count; n++){
        
        
        UIImage*image = [UIImage imageNamed:arr[n] inBundle:[NSBundle mainBundle] compatibleWithTraitCollection:nil];;
        
        CGImageRef imageref = [image CGImage];
        CGColorSpaceRef colorspace=CGColorSpaceCreateDeviceRGB();
        
        size_t width=CGImageGetWidth(imageref);
        size_t height=CGImageGetHeight(imageref);
        size_t bytesPerPixel=4;
        size_t bytesPerRow=bytesPerPixel*width;
        int bitsPerComponent = 8;
        
        unsigned char * imagedata=malloc(width*height*bytesPerPixel);
        memset(imagedata, 0, width*height*bytesPerPixel);
        
        CGContextRef cgcnt = CGBitmapContextCreate(imagedata,
                                                   width,
                                                   height,
                                                   bitsPerComponent,
                                                   bytesPerRow,
                                                   colorspace,
                                                   kCGImageAlphaPremultipliedFirst);
        //将图像写入一个矩形
        CGRect therect = CGRectMake(0, 0, width, height);
        CGContextDrawImage(cgcnt, therect, imageref);
        
        CGColorSpaceRelease(colorspace);
        CGContextRelease(cgcnt);
        
        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + n, 0, GL_RGBA, (int)width, (int)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imagedata);
        
        free(imagedata);
    }
    
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
    
}
@end
