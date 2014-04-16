//
//  RKMyScene.h
//  AirWar
//

//  Copyright (c) 2014 Rodrigo Krummenauer. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <CoreMotion/CoreMotion.h>

typedef enum: uint32_t
{
    WORLD = 0x1 << 0,
    AIRPLANE = 0x1 << 1,
    ENEMY = 0x1 << 2,
    OBSTACLE = 0x1 << 3,
    PATH = 0x1 << 4,
    BULLET = 0x1 << 5
} bitMasks;

@interface RKMyScene : SKScene <UIAccelerometerDelegate, SKPhysicsContactDelegate>

@property int removedLines;

@property (strong, nonatomic) CMMotionManager *motionManager;

@end
