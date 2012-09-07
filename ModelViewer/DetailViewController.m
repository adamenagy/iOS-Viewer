//
//  DetailViewController.m
//  ModelViewer
//
//  Created by Adam Nagy on 24/05/2012.
//  Copyright (c) 2012 Autodek. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
{
    GLuint vertexBuffer;
    GLuint normalBuffer;
    GLuint colorBuffer;
}

@property (strong, nonatomic) UIPopoverController * masterPopoverController;
@property double viewScale;
@property (strong, nonatomic) Point3d * viewRotation; 
@property (strong, nonatomic) Point3d * viewTranslation; 
@property (strong, nonatomic) GLKBaseEffect * baseEffect;
- (void)configureView;
- (void)updateGLView;
@end

@implementation DetailViewController

@synthesize statusButton = _statusButton;
@synthesize detailItem = _detailItem;
@synthesize masterPopoverController = _masterPopoverController;
@synthesize bodies = _bodies;

@synthesize minPt = _minPt;
@synthesize maxPt = _maxPt;

@synthesize viewScale = _viewScale;
@synthesize viewRotation = _viewRotation;
@synthesize viewTranslation = _viewTranslation;

@synthesize baseEffect = _baseEffect;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    // Needed for iPad portrait view
    if (self.masterPopoverController != nil) 
    {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
    
    // If view is already loaded (in cae of iPad should be true)
    if ([self isViewLoaded])
    {
        [_statusButton setTitle:@"Loading model ..."];
        
        _bodies = [ServerConnection getFacets:newDetailItem];
        
        [_statusButton setTitle:@"Done"];
        
        if (_detailItem != newDetailItem) 
        {
            _detailItem = newDetailItem;
            
            // Update the view.
            [self configureView];
        }   
    }
    
    if (_detailItem != newDetailItem) 
    {
        _detailItem = newDetailItem;
    }
}

- (void)initViewDirection
{
    _viewRotation = [[Point3d alloc] initWith:0 y:0 z:0];
    _viewTranslation = [[Point3d alloc] initWith:0 y:0 z:0]; 
    _viewScale = .5;
}

- (void)configureView
{    
    if (_bodies)
    {
        [self initViewDirection];    
        
        // Store the coordinates
        
        _minPt = [[Point3d alloc] initWith:MAXFLOAT y:MAXFLOAT z:MAXFLOAT];
        _maxPt = [[Point3d alloc] initWith:-MAXFLOAT y:-MAXFLOAT z:-MAXFLOAT];
        
        // Facet count for the whole model
        long facetCount = 0;
        for (FaceData * data in _bodies)
            facetCount += data.facets.count;
        
        // Each facet has 3 points, and each point has 3 float values
        GLfloat * vertices = (GLfloat *)malloc(sizeof(GLfloat) * facetCount * 3 * 3);
        GLfloat * normals = (GLfloat *)malloc(sizeof(GLfloat) * facetCount * 3 * 3);
        
        long vertexIndex = 0;
        for (FaceData * body in _bodies)
        {
            for (FacetData * facet in body.facets)
            {
                Point3d * pt1 = [facet.pts objectAtIndex:0];
                Point3d * n1 = [facet.normals objectAtIndex:0];
                [self adjustMinMax:pt1 minPt:_minPt maxPt:_maxPt];
                normals[vertexIndex] = [n1 x];
                vertices[vertexIndex++] = [pt1 x];
                normals[vertexIndex] = [n1 y];
                vertices[vertexIndex++] = [pt1 y];
                normals[vertexIndex] = [n1 z];
                vertices[vertexIndex++] = [pt1 z];
                Point3d * pt2 = [facet.pts objectAtIndex:1];
                Point3d * n2 = [facet.normals objectAtIndex:1];
                [self adjustMinMax:pt2 minPt:_minPt maxPt:_maxPt];
                normals[vertexIndex] = [n2 x];
                vertices[vertexIndex++] = [pt2 x];
                normals[vertexIndex] = [n2 y];
                vertices[vertexIndex++] = [pt2 y];
                normals[vertexIndex] = [n2 z];
                vertices[vertexIndex++] = [pt2 z];
                Point3d * pt3 = [facet.pts objectAtIndex:2];
                Point3d * n3 = [facet.normals objectAtIndex:2];
                [self adjustMinMax:pt3 minPt:_minPt maxPt:_maxPt];
                normals[vertexIndex] = [n3 x];
                vertices[vertexIndex++] = [pt3 x];
                normals[vertexIndex] = [n3 y];
                vertices[vertexIndex++] = [pt3 y];
                normals[vertexIndex] = [n3 z];
                vertices[vertexIndex++] = [pt3 z];
            }
        }
        glGenBuffers(1, &vertexBuffer);
        //NSLog(@"%d", glGetError());
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        //NSLog(@"%d", glGetError());
        
        ///////////////////////////////////////////////////////////////////////////////
        // buffer data is in bytes =                                                 //
        // size of float * number of facets * vertices per facet * values per vertex //
        ///////////////////////////////////////////////////////////////////////////////
        glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * facetCount * 3 * 3, vertices, GL_STATIC_DRAW);    
        //NSLog(@"%d", glGetError());
        
        glGenBuffers(1, &normalBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, normalBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * facetCount * 3 * 3, normals, GL_STATIC_DRAW);    
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        
        free(normals);
        free(vertices);
    }
    
    // Let's update the view using the new data
    
    [self updateGLView];
}

- (void)updateGLView
{
    [self.view setNeedsDisplay];
}

- (void)viewDidAppear:(BOOL)animated
{
    // If we already have a detail item (true for iPhone)
    if (_detailItem != nil)
    {
        [_statusButton setTitle:@"Loading model ..."];
        
        _bodies = [ServerConnection getFacets:_detailItem];
        
        [_statusButton setTitle:@"Done"];
        
        [self configureView];
    }    
}

- (void)viewDidLoad
{
    [_statusButton setTitle:@"Done"];    
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // VERY IMPORTANT !!!
    GLKView * glView = (GLKView *)self.view;
    
    EAGLContext * context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]; 
    glView.context = context; 
    
    glView.drawableColorFormat = GLKViewDrawableColorFormatRGB565;
    glView.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    glView.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    
    _baseEffect = [[GLKBaseEffect alloc] init];     
}

- (void)viewDidUnload
{
    [self setStatusButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Models", @"Models");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark - GLKView

#define M_TAU (2*M_PI)

- (void)adjustMinMax:(Point3d *)pt minPt:(Point3d *)minPt maxPt:(Point3d *)maxPt
{
    if (pt.x < minPt.x)
        minPt.x = pt.x;
    if (pt.y < minPt.y)
        minPt.y = pt.y;
    if (pt.z < minPt.z)
        minPt.z = pt.z;
    if (pt.x > maxPt.x)
        maxPt.x = pt.x;
    if (pt.y > maxPt.y)
        maxPt.y = pt.y;
    if (pt.z > maxPt.z)
        maxPt.z = pt.z;
}

- (void)updateTransformation
{
    // (1) Transform
    // Calculate the view direction
    GLKVector3 viewDir = GLKVector3Make(0, 1, 0);
    
    GLKMatrix3 zRotationMatrix = GLKMatrix3MakeZRotation(-_viewRotation.x);
    viewDir = GLKMatrix3MultiplyVector3(zRotationMatrix, viewDir);
    
    GLKMatrix3 xRotationMatrix = GLKMatrix3MakeXRotation(-_viewRotation.y);
    viewDir = GLKMatrix3MultiplyVector3(xRotationMatrix, viewDir);
    
    // Calculate the up vector
    GLKVector3 upDir = GLKVector3Make(0, 0, 1);
    
    GLKMatrix3 yRotationMatrix = GLKMatrix3MakeRotation(-_viewRotation.z, viewDir.x, viewDir.y, viewDir.z);
    upDir = GLKMatrix3MultiplyVector3(yRotationMatrix, upDir);
    
    // Calculate the distance / scale
    GLKVector3 center = GLKVector3Make(_minPt.x + (_maxPt.x - _minPt.x) / 2, _minPt.y + (_maxPt.y - _minPt.y) / 2, _minPt.z + (_maxPt.z - _minPt.z) / 2);
    
    GLfloat extents = GLKVector3Distance(GLKVector3Make(_minPt.x, _minPt.y, _minPt.z), GLKVector3Make(_maxPt.x, _maxPt.y, _maxPt.z));
    extents /= _viewScale;
    
    // Turn the viewdir around so that it points at the eye from the center
    viewDir = GLKVector3MultiplyScalar(viewDir, -extents);
    
    GLKVector3 eye = GLKVector3Add(center, viewDir);
    
    // float eyeX, float eyeY, float eyeZ,
    // float centerX, float centerY, float centerZ,
    // float upX, float upY, float upZ
    _baseEffect.transform.modelviewMatrix = GLKMatrix4MakeLookAt(
                                                                 eye.x, eye.y, eye.z,
                                                                 center.x, center.y, center.z,
                                                                 upDir.x, upDir.y, upDir.z);
    
    // float fovyRadians, float aspect, float nearZ, float farZ
    _baseEffect.transform.projectionMatrix = GLKMatrix4MakePerspective(0.1 * M_TAU, 1.0, 2, -1);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    NSLog(@"drawInRect\n");
    
    if (_bodies == nil)
    {
        glClearColor(1.0, 0.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        return;
    }
    
    // (2) Prepare to draw
    
    // colorMaterialEnabled = GL_FALSE uses the material color I set here
    // colorMaterialEnabled = GL_TRUE uses the material color that comes from the array
    _baseEffect.colorMaterialEnabled = GL_FALSE;
    _baseEffect.light0.enabled = GL_TRUE;  
    
    _baseEffect.material.shininess = 50; 
    //_baseEffect.material.diffuseColor = GLKVector4Make(1, 0, 0, 1);
    _baseEffect.lightingType = GLKLightingTypePerPixel;
    
    // GLKit does not seem to have these
    glEnable(GL_DEPTH_TEST);
    NSLog(@"%d", glGetError());
    glEnable(GL_CULL_FACE);
    NSLog(@"%d", glGetError());
    glDepthFunc(GL_LEQUAL);
    NSLog(@"%d", glGetError());
    
    //[_baseEffect prepareToDraw]; 
    
    NSLog(@"prepareToDraw");
    
    // (3) Do other adjustments
    
    glClearColor(0.0f, 0.5f, 0.0f, 1.0f);
    NSLog(@"%d", glGetError());
    glClear(GL_COLOR_BUFFER_BIT);
    NSLog(@"%d", glGetError());
    glClear(GL_DEPTH_BUFFER_BIT);
    NSLog(@"%d", glGetError());
    glClear(GL_STENCIL_BUFFER_BIT);
    NSLog(@"%d", glGetError());
    
    [self updateTransformation];
    
    // (4) Do the drawing
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    //////////////////////////////////////////////////////////////////////////////////
    // array type, number of values per vertex, value type, normalize,              //
    // offset between values (0 unless using an interleaved array, pointer to array //
    //////////////////////////////////////////////////////////////////////////////////
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    
    glBindBuffer(GL_ARRAY_BUFFER, normalBuffer);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    
    //glBindBuffer(GL_ARRAY_BUFFER, colorBuffer);
    //glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, 0);
    //glEnableVertexAttribArray(GLKVertexAttribColor);        
    
    ///////////////////////////////////////////////////////
    // passed i number is the number of float values =   // 
    // facets * vartices per facet                       // 
    // mode, first, vertex count                         //
    ///////////////////////////////////////////////////////
    
    long facetCount = 0;
    for (FaceData * body in _bodies)
    {        
        _baseEffect.material.diffuseColor = 
        GLKVector4Make(body.red / 255, body.green / 255, body.blue / 255, 1);
        
        [_baseEffect prepareToDraw]; 
        
        glDrawArrays(GL_TRIANGLES, facetCount * 3, body.facets.count * 3);  
        
        facetCount += body.facets.count;
    }
    
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribNormal);
    //glDisableVertexAttribArray(GLKVertexAttribColor);  
}

#pragma mark - Gestures

- (IBAction)onPinch:(UIPinchGestureRecognizer *)sender
{
    static double _origScale;
    
    if ([sender state] == UIGestureRecognizerStateBegan)
    {
        _origScale = _viewScale; 
    }
    else if ([sender state] == UIGestureRecognizerStateChanged)
    {
        NSLog(@"onPinch, scale = %f, viewScale = %f\n", sender.scale, _viewScale);
        
        _viewScale = _origScale * sender.scale;
        
        [self updateGLView];
    }    
}

- (IBAction)onPan:(UIPanGestureRecognizer *)sender 
{
    static CGPoint _prevPoint;
    
    if ([sender state] == UIGestureRecognizerStateBegan)
    {
        _prevPoint = [sender locationInView:self.view];
    }
    else if ([sender state] == UIGestureRecognizerStateChanged)
    {
        CGPoint pt = [sender locationInView:self.view];
        
        // Two touches is panning
        if (sender.numberOfTouches == 2)
        {
            _viewTranslation.x += (pt.x - _prevPoint.x);
            _viewTranslation.y += (pt.y - _prevPoint.y);
            
            NSLog(@"onPan, translation.x = %f, translation.y = %f\n", _viewTranslation.x, _viewTranslation.y);
        }
        // One touch is rotation
        else 
        {
            _viewRotation.x += (pt.x - _prevPoint.x) / 180;
            if (_viewRotation.x > M_TAU)
                _viewRotation.x -= M_TAU;
            else if (_viewRotation.x < -M_TAU)
                _viewRotation.x += M_TAU;
            
            _viewRotation.y += (pt.y - _prevPoint.y) / 180;
            if (_viewRotation.y > M_TAU)
                _viewRotation.y -= M_TAU;
            else if (_viewRotation.y < -M_TAU)
                _viewRotation.y += M_TAU;
            
            NSLog(@"onPan, rotation.x = %f, rotation.y = %f\n", _viewRotation.x, _viewRotation.y);
        }
        
        _prevPoint = pt;
        
        [self updateGLView];
    }
}
- (IBAction)onRotate:(UIRotationGestureRecognizer *)sender 
{
    static double _origRotation;
    
    if ([sender state] == UIGestureRecognizerStateBegan)
    {
        _origRotation = _viewRotation.z;
    }
    else if ([sender state] == UIGestureRecognizerStateChanged)
    {
        _viewRotation.z = _origRotation + [sender rotation];
        
        NSLog(@"onRotate, _viewRotation.z = %f, rotation = %f\n", _viewRotation.z, sender.rotation); 
        
        [self updateGLView];
    }
}
- (IBAction)onExtents:(UIBarButtonItem *)sender 
{
    [self initViewDirection];
    
    [self updateGLView];
}

@end
