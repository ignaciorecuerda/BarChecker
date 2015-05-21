/*===============================================================================
Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of QUALCOMM Incorporated, registered in the United States 
and other countries. Trademarks of QUALCOMM Incorporated are used with permission.
===============================================================================*/

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <sys/time.h>

#import <QCAR/QCAR.h>
#import <QCAR/State.h>
#import <QCAR/Tool.h>
#import <QCAR/Renderer.h>
#import <QCAR/TrackableResult.h>
#import <QCAR/VideoBackgroundConfig.h>

#import "ImageTargetsEAGLView.h"
#import "Texture.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"
#import "Teapot.h"


//******************************************************************************
// *** OpenGL ES thread safety ***
//
// OpenGL ES on iOS is not thread safe.  We ensure thread safety by following
// this procedure:
// 1) Create the OpenGL ES context on the main thread.
// 2) Start the QCAR camera, which causes QCAR to locate our EAGLView and start
//    the render thread.
// 3) QCAR calls our renderFrameQCAR method periodically on the render thread.
//    The first time this happens, the defaultFramebuffer does not exist, so it
//    is created with a call to createFramebuffer.  createFramebuffer is called
//    on the main thread in order to safely allocate the OpenGL ES storage,
//    which is shared with the drawable layer.  The render (background) thread
//    is blocked during the call to createFramebuffer, thus ensuring no
//    concurrent use of the OpenGL ES context.
//
//******************************************************************************


namespace {
    // --- Data private to this unit ---

    // Teapot texture filenames
    const char* textureFilenames[] = {
        "TextureTeapotBrass.png",
        "TextureTeapotBlue.png",
        "TextureTeapotRed.png",
        "building_texture.jpeg"
    };
    
    /*//cambio esto para redimensionar
    static float planeVertices[] =
    {
        -1, -1, 0.0, 1, -1, 0.0, 1, 1, 0.0, -1, 1, 0.0,
    };
    static const float planeTexcoords[] =
    {
        0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0
    };
    static const float planeNormals[] =
    {
        0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0
    };
    static const unsigned short planeIndices[] =
    {
        0, 1, 2, 0, 2, 3
    };
    
    // Model scale factor
    const float kObjectScaleNormal = 3.0f;
    const float kObjectScaleOffTargetTracking = 12.0f;*/
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat viewWidth; // quiero que tenga unos margenes de 35 por cada lado
    CGFloat viewHeight;
}


@interface ImageTargetsEAGLView (PrivateMethods)

- (void)initShaders;
- (void)createFramebuffer;
- (void)deleteFramebuffer;
- (void)setFramebuffer;
- (BOOL)presentFramebuffer;



@end


@implementation ImageTargetsEAGLView
    
// You must implement this method, which ensures the view's underlying layer is
// of type CAEAGLLayer
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}


//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app
{
    self = [super initWithFrame:frame];
    
    if (self) {
        vapp = app;
        
        NSString *dbn = @"Database.sqlite";
        self.dbManager = [[DBManager alloc] initWithDatabaseFilename:dbn];
        
        
        NSString *query = [NSString stringWithFormat:@"insert into targetInfo values('%@', '%@', '%@', '%@', '%@')", @"chips", @"chips_titulo", @"chips_subtitulo", @"linux.png", @"chips_text"];
        
        // Execute the query.
        [self.dbManager executeQuery:query];
        
        if (self.dbManager.affectedRows != 0)
            NSLog(@"Query was executed successfully. Affected rows = %d", self.dbManager.affectedRows);
        else
            NSLog(@"Could not execute the query.");
    
        query = [NSString stringWithFormat:@"insert into targetInfo values('%@', '%@', '%@', '%@', '%@')", @"stones", @"Titulo", @"Subtitulo", @"ugr-logo.png", @"Lorem Ipsum es simplemente el texto de relleno de las imprentas y archivos de texto. Lorem Ipsum ha sido el texto de relleno estándar de las industrias desde el año 1500, cuando un impresor (N. del T. persona que se dedica a la imprenta) desconocido usó una galería de textos y los mezcló de tal manera que logró hacer un libro de textos especimen. No sólo sobrevivió 500 años, sino que tambien ingresó como texto de relleno en documentos electrónicos, quedando esencialmente igual al original. Fue popularizado en los 60s con la creación de las hojas , las cuales contenian pasajes de Lorem Ipsum, y más recientemente con software de autoedición, http://www.google.es como por ejemplo Aldus PageMaker, el cual incluye versiones de Lorem Ipsum. Al contrario del pensamiento popular, el texto de Lorem Ipsum no es simplemente texto aleatorio. Tiene sus raices en una pieza cl´sica de la literatura del Latin, que data del año 45 antes de Cristo, haciendo que este adquiera mas de 2000 años de antiguedad. Richard McClintock, un profesor de Latin de la Universidad de Hampden-Sydney en Virginia, encontró una de las palabras más oscuras de la lengua del latín, , en un pasaje de Lorem Ipsum, y al seguir leyendo distintos textos del latín, descubrió la fuente indudable. Lorem Ipsum viene de las secciones 1.10.32 y 1.10.33 de  (Los Extremos del Bien y El Mal) por Cicero, escrito en el año 45 antes de Cristo. Este libro es un tratado de teoría de éticas, muy popular durante el Renacimiento. La primera linea del Lorem Ipsum, , viene de una linea en la sección 1.10.32"];

        [self.dbManager executeQuery:query];
        
        if (self.dbManager.affectedRows != 0)
            NSLog(@"Query was executed successfully. Affected rows = %d", self.dbManager.affectedRows);
        else
            NSLog(@"Could not execute the query.");
        
        
        // Enable retina mode if available on this device
        if (YES == [vapp isRetinaDisplay]) {
            [self setContentScaleFactor:2.0f];
        }
        
        // Load the augmentation textures
        for (int i = 0; i < NUM_AUGMENTATION_TEXTURES; ++i) {
            augmentationTexture[i] = [[Texture alloc] initWithImageFile:[NSString stringWithCString:textureFilenames[i] encoding:NSASCIIStringEncoding]];
        }

        // Create the OpenGL ES context
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        // The EAGLContext must be set for each thread that wishes to use it.
        // Set it the first time this method is called (on the main thread)
        if (context != [EAGLContext currentContext]) {
            [EAGLContext setCurrentContext:context];
        }
        
        glGenTextures(1, &texture[0]);
        glBindTexture(GL_TEXTURE_2D, texture[0]);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
       
        
        //-------------------------------------------------------------------------------------
        
        //CGRect frame = {0,0,144,100};
        
        if ( [(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"] ) {
            viewWidth = screenRect.size.width-300;
            viewHeight = screenRect.size.height-550;
        }
        else {
            viewWidth = screenRect.size.width-70; // quiero que tenga unos margenes de 35 por cada lado
            viewHeight = screenRect.size.height-223;
        }
        
        self.targetInfoView = [[UIView alloc] init];
        self.targetInfoView.backgroundColor = [UIColor whiteColor];
        
        /*UITextView *button = [UITe buttonWithType:UIButtonTypeRoundedRect];
        [button setTitle:@"Show View" forState:UIControlStateNormal];
        button.frame = CGRectMake(0.0, 0.0, 60.0, 40.0);
        [self.targetInfoView addSubview:button];*/
        
        self.logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"linux.png"]];
        self.logo.contentMode = UIViewContentModeScaleAspectFit;
        self.logo.frame = CGRectMake(10, 10, (viewWidth/2)-20, (viewWidth/2)-20);
        
        self.title = [[UILabel alloc] initWithFrame:CGRectMake((viewWidth/2)+10, 30, (viewWidth/2)-20, 20)];
        [self.title setTextColor:[UIColor blackColor]];
        [self.title setBackgroundColor:[UIColor clearColor]];
        [self.title setTextAlignment:NSTextAlignmentCenter];
        self.title.text = @"Titulo";
        //[title setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
        
        self.subtitle = [[UILabel alloc] initWithFrame:CGRectMake((viewWidth/2)+10, 60, (viewWidth/2)-20, 20)];
        [self.subtitle setTextColor:[UIColor blackColor]];
        [self.subtitle setBackgroundColor:[UIColor clearColor]];
        [self.subtitle setTextAlignment:NSTextAlignmentCenter];
        self.subtitle.text = @"Subtitulo";
        //[subtitle setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
        
        self.textV = [[UITextView alloc] initWithFrame:CGRectMake(10, (viewWidth/2), (viewWidth)-20, viewHeight-((viewWidth/2)+10))];
        [self.textV setFont:[UIFont systemFontOfSize:11]];
        self.textV.text = @"Lorem Ipsum es simplemente el texto de relleno de las imprentas y archivos de texto. Lorem Ipsum ha sido el texto de relleno estándar de las industrias desde el año 1500, cuando un impresor (N. del T. persona que se dedica a la imprenta) desconocido usó una galería de textos y los mezcló de tal manera que logró hacer un libro de textos especimen. No sólo sobrevivió 500 años, sino que tambien ingresó como texto de relleno en documentos electrónicos, quedando esencialmente igual al original. Fue popularizado en los 60s con la creación de las hojas , las cuales contenian pasajes de Lorem Ipsum, y más recientemente con software de autoedición, http://www.google.es como por ejemplo Aldus PageMaker, el cual incluye versiones de Lorem Ipsum. Al contrario del pensamiento popular, el texto de Lorem Ipsum no es simplemente texto aleatorio. Tiene sus raices en una pieza cl´sica de la literatura del Latin, que data del año 45 antes de Cristo, haciendo que este adquiera mas de 2000 años de antiguedad. Richard McClintock, un profesor de Latin de la Universidad de Hampden-Sydney en Virginia, encontró una de las palabras más oscuras de la lengua del latín, , en un pasaje de Lorem Ipsum, y al seguir leyendo distintos textos del latín, descubrió la fuente indudable. Lorem Ipsum viene de las secciones 1.10.32 y 1.10.33 de  (Los Extremos del Bien y El Mal) por Cicero, escrito en el año 45 antes de Cristo. Este libro es un tratado de teoría de éticas, muy popular durante el Renacimiento. La primera linea del Lorem Ipsum, , viene de una linea en la sección 1.10.32";
        self.textV.scrollEnabled = YES;
        self.textV.editable = NO;
        self.textV.dataDetectorTypes = UIDataDetectorTypeLink;
        
        [self.targetInfoView addSubview:self.title];
        [self.targetInfoView addSubview:self.subtitle];
        [self.targetInfoView addSubview:self.logo];
        [self.targetInfoView addSubview:self.textV];
        
        //-------------------------------------------------------------------------------------

        offTargetTrackingEnabled = NO;
        
        [self loadBuildingsModel];
        [self initShaders];
    }
    
    return self;
}


- (void)dealloc
{
    [self deleteFramebuffer];
    
    // Tear down context
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [context release];
    [buildingModel release];

    for (int i = 0; i < NUM_AUGMENTATION_TEXTURES; ++i) {
        [augmentationTexture[i] release];
    }

    [self.targetInfoView release];
    [super dealloc];
}


- (void)finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  The render loop has
    // been stopped, so we now make sure all OpenGL ES commands complete before
    // we (potentially) go into the background
    if (context) {
        [EAGLContext setCurrentContext:context];
        glFinish();
    }
}


- (void)freeOpenGLESResources
{
    // Called in response to applicationDidEnterBackground.  Free easily
    // recreated OpenGL ES resources
    //[self.targetInfoView release];
    [self deleteFramebuffer];
    glFinish();
}

- (void) setOffTargetTrackingMode:(BOOL) enabled {
    offTargetTrackingEnabled = enabled;
}

- (void) loadBuildingsModel {
    buildingModel = [[SampleApplication3DModel alloc] initWithTxtResourceName:@"buildings"];
    [buildingModel read];
}


//------------------------------------------------------------------------------
#pragma mark - UIGLViewProtocol methods

// Draw the current frame using OpenGL
//
// This method is called by QCAR when it wishes to render the current frame to
// the screen.
//
// *** QCAR will call this method periodically on a background thread ***
- (void)renderFrameQCAR
{
    [self setFramebuffer];
    
    // Clear colour and depth buffers
    //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Render video background and retrieve tracking state
    QCAR::State state = QCAR::Renderer::getInstance().begin();
    QCAR::Renderer::getInstance().drawVideoBackground();
    
    /*glEnable(GL_DEPTH_TEST);
    // We must detect if background reflection is active and adjust the culling direction.
    // If the reflection is active, this means the pose matrix has been reflected as well,
    // therefore standard counter clockwise face culling will result in "inside out" models.
    if (offTargetTrackingEnabled) {
        glDisable(GL_CULL_FACE);
    } else {
        glEnable(GL_CULL_FACE);
    }
    glCullFace(GL_BACK);
    if(QCAR::Renderer::getInstance().getVideoBackgroundConfig().mReflection == QCAR::VIDEO_BACKGROUND_REFLECTION_ON)
        glFrontFace(GL_CW);  //Front camera
    else
        glFrontFace(GL_CCW);   //Back camera*/
    
    //NSLog(@"%d", state.getNumTrackableResults());
    for (int i = 0; i < state.getNumTrackableResults(); ++i) {
        // Get the trackable
        const QCAR::TrackableResult* result = state.getTrackableResult(i);
        const QCAR::Trackable& trackable = result->getTrackable();
        
        //QCAR::Matrix44F modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(result->getPose());
        
        // OpenGL 2
        /*QCAR::Matrix44F modelViewProjection;
        
        if (offTargetTrackingEnabled) {
            SampleApplicationUtils::rotatePoseMatrix(90, 1, 0, 0,&modelViewMatrix.data[0]);
            SampleApplicationUtils::scalePoseMatrix(kObjectScaleOffTargetTracking, kObjectScaleOffTargetTracking, kObjectScaleOffTargetTracking, &modelViewMatrix.data[0]);
        } else {
            SampleApplicationUtils::translatePoseMatrix(0.0f, 0.0f, kObjectScaleNormal, &modelViewMatrix.data[0]);
            SampleApplicationUtils::scalePoseMatrix(kObjectScaleNormal, kObjectScaleNormal, kObjectScaleNormal, &modelViewMatrix.data[0]);
        }
        
        SampleApplicationUtils::multiplyMatrix(&vapp.projectionMatrix.data[0], &modelViewMatrix.data[0], &modelViewProjection.data[0]);
        
        glUseProgram(shaderProgramID);*/
        
        QCAR::Matrix34F pose = result->getPose();
        //QCAR::Vec3F position(pose.data[3], pose.data[7], pose.data[11]);
        //float distance = sqrt(position.data[0] * position.data[0] +
        //                      position.data[1] * position.data[1] +
        //                      position.data[2] * position.data[2]);
        //distance = distance/100;
        
        //for(int i = 0; i < 12; i++)
        //    planeVertices[i] = planeVertices[i]*distance;
        
        /*glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0,
                              (const GLvoid*) &planeVertices[0]);
        glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0,
                              (const GLvoid*) &planeNormals[0]);
        glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0,
                              (const GLvoid*) &planeTexcoords[0]);
        glEnableVertexAttribArray(vertexHandle);
        glEnableVertexAttribArray(normalHandle);
        glEnableVertexAttribArray(textureCoordHandle);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texture[0]);
        glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE,
                           (GLfloat*)&modelViewProjection.data[0] );
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT,
                       (const GLvoid*) &planeIndices[0]);*/
        
        NSString* string = [NSString stringWithFormat:@"%s" , trackable.getName()];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (!self.targetInfoView.superview) {
                [self loadData: string];
                [self addSubview:self.targetInfoView];
            }
        });
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            CGSize targetSize = CGSizeMake(pose.data[0], pose.data[1]);
            CGPoint targetCenter = [self calcScreenCoordsOf:targetSize inPose:pose];
            CGFloat screenWidth = screenRect.size.width/2;
            if(!isnan(targetCenter.x) && !isnan(targetCenter.y)) {
                CGRect frame = CGRectMake(screenWidth-(targetCenter.y/2), targetCenter.x-(viewHeight/2), viewWidth, viewHeight);

                self.targetInfoView.frame = frame;
            }
        });
        
        //for(int i = 0; i < 12; i++)
        //    planeVertices[i] = planeVertices[i]/distance;
        
    }
    
    if(state.getNumTrackableResults() == 0) {
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (self.targetInfoView.superview != nil) {
                [self.targetInfoView removeFromSuperview];
            }
        });
        
    }
    
    /*glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    glDisableVertexAttribArray(vertexHandle);
    glDisableVertexAttribArray(normalHandle);
    glDisableVertexAttribArray(textureCoordHandle);*/
    
    QCAR::Renderer::getInstance().end();
    [self presentFramebuffer];
}

-(void) loadData:(NSString *)index {
    
    NSString *query = [NSString stringWithFormat:@"select * from targetInfo where targetName = '%@'", index];
    
    // Get the results.
    if (self.arrPeopleInfo != nil) {
        self.arrPeopleInfo = nil;
    }
    
    self.arrPeopleInfo = [[NSArray alloc] initWithArray:[self.dbManager loadDataFromDB:query]];
    
    //[self.title setText:[NSString stringWithFormat:@"%@", [[self.arrPeopleInfo objectAtIndex:0] objectAtIndex:1]]];
    [self.title setText:[NSString stringWithFormat:@"BAR"]];
    [self.subtitle setText:[NSString stringWithFormat:@"%@", [[self.arrPeopleInfo objectAtIndex:0] objectAtIndex:2]]];
    [self.logo setImage:[UIImage imageNamed:[[self.arrPeopleInfo objectAtIndex:0] objectAtIndex:3]]];
    [self.targetInfoView setBackgroundColor:[UIColor grayColor]];
    [self.textV setText:[NSString stringWithFormat:@"%@", [[self.arrPeopleInfo objectAtIndex:0] objectAtIndex:4]]];

}

- (CGPoint) projectCoord:(CGPoint)coord inView:(const QCAR::CameraCalibration&)cameraCalibration andPose:(QCAR::Matrix34F)pose withOffset:(CGPoint)offset andScale:(CGFloat)scale
{
    CGPoint converted;
    QCAR::Vec3F vec(coord.x,coord.y,0);
    QCAR::Vec2F sc = QCAR::Tool::projectPoint(cameraCalibration, pose, vec);
    converted.x = sc.data[0]*scale - offset.x;
    converted.y = sc.data[1]*scale - offset.y;
    return converted;
}
- (CGPoint)calcScreenCoordsOf:(CGSize)target inPose:(QCAR::Matrix34F)pose
{
    // 0,0 is at centre of target so extremities are at w/2,h/2
    // need to account for the orientation on view size
    CGFloat viewWidth = self.frame.size.height; // Portrait
    CGFloat viewHeight = self.frame.size.width; // Portrait
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        viewWidth = self.frame.size.width;
        viewHeight = self.frame.size.height;
    }
    // calculate any mismatch of screen to video size
    QCAR::CameraDevice& cameraDevice = QCAR::CameraDevice::getInstance();
    const QCAR::CameraCalibration& cameraCalibration = cameraDevice.getCameraCalibration();
    QCAR::VideoMode videoMode = cameraDevice.getVideoMode(QCAR::CameraDevice::MODE_DEFAULT);
    CGFloat scale = viewWidth/videoMode.mWidth;
    if (videoMode.mHeight * scale < viewHeight)
        scale = viewHeight/videoMode.mHeight;
    CGFloat scaledWidth = videoMode.mWidth * scale;
    CGFloat scaledHeight = videoMode.mHeight * scale;
    CGPoint margin = {(scaledWidth - viewWidth)/2, (scaledHeight - viewHeight)/2};
    // now project the 4 corners of the target
    
    // CGPoint s0 = [self projectCoord:CGPointMake(-w,h) inView:cameraCalibration andPose:pose withOffset:margin andScale:scale];
    // CGPoint s1 = [self projectCoord:CGPointMake(-w,-h) inView:cameraCalibration andPose:pose withOffset:margin andScale:scale];
    // CGPoint s2 = [self projectCoord:CGPointMake(w,-h) inView:cameraCalibration andPose:pose withOffset:margin andScale:scale];
    // CGPoint s3 = [self projectCoord:CGPointMake(w,h) inView:cameraCalibration andPose:pose withOffset:margin andScale:scale];
    
    CGPoint targetCenter = [self projectCoord:CGPointMake(0,0) inView:cameraCalibration andPose:pose withOffset:margin andScale:scale];
    
    return targetCenter;
}

//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management

- (void)initShaders
{
    shaderProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"Simple.vertsh"
                                                   fragmentShaderFileName:@"Simple.fragsh"];

    if (0 < shaderProgramID) {
        vertexHandle = glGetAttribLocation(shaderProgramID, "vertexPosition");
        normalHandle = glGetAttribLocation(shaderProgramID, "vertexNormal");
        textureCoordHandle = glGetAttribLocation(shaderProgramID, "vertexTexCoord");
        mvpMatrixHandle = glGetUniformLocation(shaderProgramID, "modelViewProjectionMatrix");
        texSampler2DHandle  = glGetUniformLocation(shaderProgramID,"texSampler2D");
    }
    else {
        NSLog(@"Could not initialise augmentation shader");
    }
}


- (void)createFramebuffer
{
    if (context) {
        // Create default framebuffer object
        glGenFramebuffers(1, &defaultFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        // Create colour renderbuffer and allocate backing store
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        
        // Allocate the renderbuffer's storage (shared with the drawable object)
        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        GLint framebufferWidth;
        GLint framebufferHeight;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        // Create the depth render buffer and allocate storage
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, framebufferWidth, framebufferHeight);
        
        // Attach colour and depth render buffers to the frame buffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
        
        // Leave the colour render buffer bound so future rendering operations will act on it
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    }
}


- (void)deleteFramebuffer
{
    if (context) {
        [EAGLContext setCurrentContext:context];
        
        if (defaultFramebuffer) {
            glDeleteFramebuffers(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
        }
        
        if (colorRenderbuffer) {
            glDeleteRenderbuffers(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
        }
        
        if (depthRenderbuffer) {
            glDeleteRenderbuffers(1, &depthRenderbuffer);
            depthRenderbuffer = 0;
        }
    }
}


- (void)setFramebuffer
{
    // The EAGLContext must be set for each thread that wishes to use it.  Set
    // it the first time this method is called (on the render thread)
    if (context != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:context];
    }
    
    if (!defaultFramebuffer) {
        // Perform on the main thread to ensure safe memory allocation for the
        // shared buffer.  Block until the operation is complete to prevent
        // simultaneous access to the OpenGL context
        [self performSelectorOnMainThread:@selector(createFramebuffer) withObject:self waitUntilDone:YES];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
}


- (BOOL)presentFramebuffer
{
    // setFramebuffer must have been called before presentFramebuffer, therefore
    // we know the context is valid and has been set for this (render) thread
    
    // Bind the colour render buffer and present it
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    return [context presentRenderbuffer:GL_RENDERBUFFER];
}



@end
