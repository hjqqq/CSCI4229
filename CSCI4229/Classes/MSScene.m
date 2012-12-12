/**
 *  MSScene.m
 *  CSCI4229
 *
 *  Created by Devon Tivona on 12/11/12.
 *  Copyright 2012 Monospace Ltd. All rights reserved.
 */

#import "MSScene.h"
#import "CC3PODResourceNode.h"
#import "CC3ActionInterval.h"
#import "CC3MeshNode.h"
#import "CC3Camera.h"
#import "CC3Light.h"
#import "CC3ParametricMeshNodes.h"
#import "CGPointExtension.h"
#import "CCLabelTTF.h"
#import "CC3Billboard.h"
#import "CCActionInstant.h"
#import "CCParticleExamples.h"
#import "CC3ShadowVolumes.h"
#import "CC3VertexArrays.h"

@interface MSScene ()

@property (nonatomic, assign) CC3Vector cameraStartDirection;
@property (nonatomic, strong) CC3Node *boom;

- (void)addGround;
- (void)addRobot;
- (void)addCameraBoom;

@end

@implementation MSScene

#pragma mark - Scene Lifecycle

- (void)dealloc {
	[super dealloc];
}

- (void)initializeScene {
    
    self.ambientLight = CCC4FMake(1.0, 1.0, 1.0, 1.0);

	// Create the camera, place it back a bit, and add it to the scene    
	CC3Camera* camera = [CC3Camera nodeWithName: @"Camera"];
	camera.location = cc3v( 0.0, 0.0, 20.0 );
    [self addChild:camera];
    
	// Create a light, place it back and to the left at a specific
	// position (not just directional lighting), and add it to the scene
	CC3Light* lamp = [CC3Light nodeWithName: @"Lamp"];
	lamp.location = cc3v(0.0, 10.0, 0.0 );
	lamp.isDirectionalOnly = NO;
	[self addChild: lamp];
    
    [self addRobot];
    [self addGround];
    [self addCameraBoom];
	
	// Create OpenGL ES buffers for the vertex arrays to keep things fast and efficient,
	// and to save memory, release the vertex data in main memory because it is now redundant.
    [self retainVertexLocations];
	[self retainVertexIndices];
	[self retainVertexWeights];
	[self retainVertexMatrixIndices];
	[self createGLBuffers];
	[self releaseRedundantData];
	
	// Displays short descriptive text for each node (including class, node name & tag).
	// The text is displayed centered on the pivot point (origin) of the node.
    // self.shouldDrawAllDescriptors = YES;
	
	// Displays bounding boxes around those nodes with local content (eg- meshes).
    // self.shouldDrawAllLocalContentWireframeBoxes = YES;
	
	// Displays bounding boxes around all nodes. The bounding box for each node
	// will encompass its child nodes.
    // self.shouldDrawAllWireframeBoxes = YES;
	
	// If you encounter issues creating and adding nodes, or loading models from
	// files, the following line is used to log the full structure of the scene.
	LogCleanDebug(@"The structure of this scene is: %@", [self structureDescription]);
}

-(void) onOpen {
    self.cameraStartDirection = CC3VectorMake(-1.0, 1.0, 0.0);
    [self.activeCamera moveToShowAllOf:self.robot fromDirection:self.cameraStartDirection withPadding:3.0];
    [self.boom addChild:self.activeCamera];
}

- (void) onClose
{
    
}

#pragma mark - Object Addition Methods

- (void)addGround
{
	self.ground = [CC3PlaneNode nodeWithName:@"Ground"];
	[self.ground populateAsDiskWithRadius:1500 andTessellation: ccg(8, 32)];
    
	self.ground.texture = [CC3Texture textureFromFile:@"Grass.jpg"];
	[self.ground repeatTexture: (ccTex2F){100, 100}];
    
	self.ground.location = cc3v(0.0, 0.0, 0.0);
	self.ground.rotation = cc3v(-90.0, 180.0, 0.0);
	self.ground.shouldCullBackFaces = NO; // Show the ground from below as well.
	self.ground.isTouchEnabled = YES;
	[self.ground retainVertexLocations];
	[self addChild:self.ground];
}

- (void)addRobot
{
    [self addContentFromPODFile: @"Robot.pod" withName:@"RobotMesh"];
    
    self.robotMesh = (CC3MeshNode*)[self getNodeNamed: @"RobotMesh"];
    self.robot = [[CC3Node alloc] initWithName:@"Robot"];
    [self.robot addChild:self.robotMesh];
    
    // Rotate the model to display properly in world
    [self.robotMesh rotateByAngle:97.0 aroundAxis:CC3VectorMake(1.0, 0.0, 0.0)];
    [self.robotMesh rotateByAngle:-90.0 aroundAxis:CC3VectorMake(0.0, 1.0, 0.0)];
    [self.robotMesh translateBy:CC3VectorMake(1.7, 1.0, -0.7)];
    
    [self.robot setIsTouchEnabled:YES];
    [self addChild:self.robot];
}

- (void)addCameraBoom
{
    self.boom = [[CC3Node alloc] initWithName:@"Boom"];
    self.boom.location = CC3VectorAdd(self.robot.globalCenterOfGeometry, CC3VectorMake(0.0, 0.0, 0.0));
    [self addChild:self.boom];
}


#pragma mark - Update Custom Activity

//
// This template method is invoked periodically whenever the 3D nodes are to be updated.
//
// This method provides your app with an opportunity to perform update activities before
// any changes are applied to the transformMatrix of the 3D nodes in the scene.
//
// For more info, read the notes of this method on CC3Node.
//
- (void)updateBeforeTransform:(CC3NodeUpdatingVisitor*)visitor
{
}

//
// This template method is invoked periodically whenever the 3D nodes are to be updated.
//
// This method provides your app with an opportunity to perform update activities after
// the transformMatrix of the 3D nodes in the scen have been recalculated.
//
// For more info, read the notes of this method on CC3Node.
//
- (void)updateAfterTransform:(CC3NodeUpdatingVisitor*)visitor {
	// If you have uncommented the moveWithDuration: invocation in the onOpen: method,
	// you can uncomment the following to track how the camera moves, and where it ends up,
	// in order to determine where to position the camera to see the entire scene.
    // LogDebug(@"Camera location is: %@", NSStringFromCC3Vector(activeCamera.globalLocation));
}


#pragma mark - Touch Event Handlers 

// This callback template method is invoked automatically when a node has been picked
// by the invocation of the pickNodeFromTapAt: or pickNodeFromTouchEvent:at: methods,
// as a result of a touch event or tap gesture.
- (void)nodeSelected:(CC3Node*)node byTouchEvent:(uint)touchType at:(CGPoint)touchPoint
{
    if (node == self.robot) {
        NSLog(@"touched my robot");
    }
    else if (node == self.ground) {
        NSLog(@"touched my ground");
        [self touchGroundAt:touchPoint];
    }
}

- (void)startDraggingAt:(CGPoint)touchPoint
{
    self.cameraStartDirection = self.boom.rotation;
}

- (void)dragBy:(CGPoint)movement atVelocity:(CGPoint)velocity
{    
    CC3Vector cameraDirection = self.cameraStartDirection;
    CGPoint panRotation = ccpMult(movement, 180);
	cameraDirection.y -= panRotation.x;
    cameraDirection.z += panRotation.y;

    // Prevent from viewing the robot upside down
	if (cameraDirection.z < -45.0) {
        cameraDirection.z = -45.0;
    }
    // Prevent from viewing the robot from underground
    else if (cameraDirection.z > 45.0) {
        cameraDirection.z = 45.0;
    }
    
    self.cameraStartDirection = cameraDirection;
    self.boom.rotation = self.cameraStartDirection;
}

- (void)stopDragging
{
    
}

- (void)touchGroundAt:(CGPoint)touchPoint {
	CC3Plane groundPlane = self.ground.plane;
	CC3Vector4 touchLoc = [self.activeCamera unprojectPoint:touchPoint ontoPlane:groundPlane];
    
	// Make sure the projected touch is in front of the camera, not behind it
	if (touchLoc.w > 0.0) {
		[self addExplosionAt:touchLoc];
        [self moveRobotTo:touchLoc];
	}
}

- (void)moveRobotTo:(CC3Vector4)destination
{
    [self.robot stopAllActions];
    [self.boom stopAllActions];
    [self.robotMesh stopAllActions];
    
    CGFloat distance = CC3VectorDistance(self.robot.location, CC3VectorFromTruncatedCC3Vector4(destination));
    CGFloat robotVelocity = 10.0;
    CGFloat walkDuration = ceilf(distance / robotVelocity);
    
    [self.robot runAction:[CC3RotateToLookAt actionWithDuration:0.3 targetLocation:CC3VectorFromTruncatedCC3Vector4(destination)]];
    [self.robot runAction:[CC3MoveTo actionWithDuration:walkDuration moveTo:CC3VectorFromTruncatedCC3Vector4(destination)]];
    [self.boom runAction:[CC3MoveTo actionWithDuration:walkDuration moveTo:CC3VectorFromTruncatedCC3Vector4(destination)]];

    CCActionInterval *walk = [CC3Animate actionWithDuration:0.5];
    [self.robotMesh runAction:[CCRepeat actionWithAction:walk times:walkDuration * 2]];
}

/**
 * Adds a temporary fiery explosion on top of the specified node, using a cocos2d
 * CCParticleSystem. The explosion is set to a short duration, and when the particle
 * system has exhausted, the CC3ParticleSystem node along with the CCParticleSystem
 * billboard it contains are automatically removed from the 3D scene.
 */
- (void)addExplosionAt:(CC3Vector4)explosionLocation {
	// Create the particle emitter with a finite duration, and set it to auto-remove
	// once it is exhausted.
	CCParticleSystem* emitter = [CCParticleFire node];
	emitter.position = ccp(0.0, 0.0);
	emitter.duration = 0.75;
	emitter.autoRemoveOnFinish = YES;
    
	// Create the 3D billboard node to hold the 2D particle emitter.
	// The bounding volume is removed so that the flames will not be culled as the
	// camera pans away from the flames. This is suitable since the particle system
	// only exists for a short duration.
	CC3ParticleSystemBillboard* bb = [CC3ParticleSystemBillboard nodeWithName:@"EXPLOSION" withBillboard: emitter];
	
	// A billboard can be drawn either as part of the 3D scene, or as an overlay
	// above the 3D scene. By commenting out one of the following sections of code,
	// you can choose which method to use.
	
	// 1) In the 3D scene.
	// The following lines wrap the emitter billboard in a wrapper that will find
	// and track the camera in 3D. The flames can be occluded by other nodes between
	// the explosion and the camera.
    
	bb.uniformScale = 0.03;	// Find a suitable scale
	bb.shouldUseLighting = NO;								// Solid coloring
	bb.shouldInheritTouchability = NO;						// Don't allow flames to be touched
    
	// If the 2D particle system uses point particles instead of quads, attenuate the
	// particle sizes with distance realistically. This is not needed if the particle
	// system will always use quads, but it doesn't hurt to set it.
	bb.particleSizeAttenuationCoefficients = CC3AttenuationCoefficientsMake(0.05, 0.02, 0.0001);
	
	// 2D particle systems do not have a real contentSize and boundingBox, so we need to
	// calculate it dynamically on each update pass, or assign one that will cover the
	// area that will be used by this particular particle system. This bounding rectangle
	// is specified in terms of the local coordinate system of the particle system and
	// will be scaled and transformed as the node is transformed. By setting this once,
	// we don't need to calculate it while running the particle system.
	// To calculate it dynamically on each update instead, comment out the following line,
	// and uncomment the line after. And also uncomment the third line to see the bounding
	// box drawn and updated on each frame.
	bb.billboardBoundingRect = CGRectMake(-90.0, -50.0, 190.0, 340.0);
    //	bb.shouldAlwaysMeasureBillboardBoundingRect = YES;
    //	bb.shouldDrawLocalContentWireframeBox = YES;
    
	// How did we determine the billboardBoundingRect? This can be done by trial and
	// error, by uncommenting culling logging in the CC3Billboard doesIntersectBoundingVolume:
	// method. Or it is better done by changing LogTrace to LogDebug in the CC3Billboard
	// billboardBoundingRect property accessor method, commenting out the line above this
	// comment, and uncommenting the following line. Doing so will cause an ever expanding
	// bounding box to be logged, the maximum size of which can be used as the value to
	// set in the billboardBoundingRect property.
    //	bb.shouldMaximizeBillboardBoundingRect = YES;
    
	// We want to locate the explosion between the node and the camera, so that it
	// appears to engulf the node. To do this, wrap the billboard in an orientating
	// wrapper, give the explosion a location offset, and make the wrapper track
	// the camera. This will keep the explosion between the node and the camera,
	// regardless of where they are.
	// If we didn't need the locational offset to place the explosion in front
	// of the camera, we could have the billboard itself track the camera
	// using the shouldAutotargetCamera property of the billboard itself.
	bb.location = CC3VectorFromTruncatedCC3Vector4(explosionLocation);
    bb.shouldAutotargetCamera = YES;
	[self addChild:bb];

    
	// 2) Overlaid above the 3D scene.
	// The following lines add the emitter billboard as a 2D overlay that draws above
	// the 3D scene. The flames will not be occluded by any other 3D nodes.
	// Comment out the lines in section (1) just above, and uncomment the following lines:
    //	emitter.positionType = kCCPositionTypeGrouped;
    //	bb.shouldDrawAs2DOverlay = YES;
    //	bb.unityScaleDistance = 180.0;
    //	[aNode addChild: bb];
}

@end