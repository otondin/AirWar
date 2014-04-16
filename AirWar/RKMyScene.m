//
//  RKMyScene.m
//  AirWar
//
//  Created by Rodrigo K on 4/15/14.
//  Copyright (c) 2014 Rodrigo Krummenauer. All rights reserved.
//

#import "RKMyScene.h"

@implementation RKMyScene {
    CGFloat teilWidth;
    CGFloat teilHeight;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        SKSpriteNode *world = [SKSpriteNode node];
        world.name = @"world";
        [self addChild:world];
        
        NSString* path = [[NSBundle mainBundle] pathForResource:@"map" ofType:@"txt"];
        
        NSString* content = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];
        // first, separate by new line
        NSArray* lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        teilWidth = self.size.width / [[lines firstObject] length];
        teilHeight = teilWidth;
        
        
        NSMutableArray *map = [[NSMutableArray alloc] init];
        
        for (NSString *item in lines) {
            NSMutableArray *cols = [[NSMutableArray alloc] init];
            for (int i = 0; i < item.length; i++) {
                [cols addObject: [NSString stringWithFormat:@"%c", [item characterAtIndex:i]]];
            }
            [map addObject:cols];
        }
        
        for (int rowIndex = 0; rowIndex < map.count; rowIndex++) {
            
            NSMutableArray *row = [map objectAtIndex:rowIndex];
            
            for (int colIndex = 0; colIndex < row.count; colIndex++) {
                [self buildTile:[row objectAtIndex:colIndex]
                            row:rowIndex
                            col:colIndex];
            }
        }
        
        self.removedLines = 0;
        
        SKAction *worldMove = [SKAction sequence:@[
                                                   [SKAction moveByX:0 y:-teilHeight duration:.2],
                                                   [SKAction runBlock:^{
            
            NSString *name = [NSString stringWithFormat:@"%d", self.removedLines];
            [world enumerateChildNodesWithName:name usingBlock:^(SKNode *node, BOOL *stop) {
                [node removeFromParent];
            }];
            
            int rowIndex = (self.removedLines % map.count);
            NSArray *row = [map objectAtIndex:rowIndex];
            
            for (int colIndex = 0; colIndex < row.count; colIndex++) {
                [self buildTile:[row objectAtIndex:colIndex]
                            row:self.removedLines + map.count
                            col:colIndex];
            }
            
            self.removedLines++;
            
        }]
                                                   ]];
        
        
        [world runAction:[SKAction repeatActionForever:worldMove]];
        
        
        SKSpriteNode *plane = [SKSpriteNode spriteNodeWithImageNamed:@"airplane.png"];
        plane.size = CGSizeMake(teilHeight*2, teilWidth*2);
        plane.position = CGPointMake(self.size.width/2, 100);
        plane.color = [UIColor blackColor];
        [self addChild:plane];
        plane.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:plane.size];
        plane.physicsBody.affectedByGravity = NO;
        plane.physicsBody.allowsRotation = NO;
        plane.physicsBody.categoryBitMask = AIRPLANE;
        plane.physicsBody.collisionBitMask = WORLD;
        plane.physicsBody.contactTestBitMask = ENEMY | OBSTACLE;
        
        self.motionManager = [[CMMotionManager alloc] init];
        self.motionManager.accelerometerUpdateInterval = .1;
        
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
            [self outputAccelertionData:accelerometerData.acceleration];
            
            if (error) {
                NSLog(@"%@", error);
            }
        }];
        
        
    }
    
    return self;
}


- (void)buildTile:(NSString *)item row:(int)row col:(int)col
{
    if ([item isEqualToString:@"-"]) {
        [self buildGrassAtRow:row andCol: col];
        return;
    }
    if ([item isEqualToString:@"O"]) {
        [self buildDelimiterAtRow:row andCol: col];
        return;
    }
    if ([item isEqualToString:@"r"]) {
        [self buildRiverAtRow:row andCol: col];
        return;
    }
    
}


- (void)buildGrassAtRow:(int)row andCol:(int)col
{
    SKNode *world = [self childNodeWithName:@"world"];
    
    SKSpriteNode *tile = [SKSpriteNode node];
    
    tile.position = CGPointMake(col * teilHeight + teilHeight/2, row * teilWidth + teilWidth/2);
    tile.size = CGSizeMake(teilWidth, teilHeight);
    tile.color = [UIColor greenColor];
    tile.name = [NSString stringWithFormat:@"%d", row];
    
    [world addChild:tile];
}


- (void)buildDelimiterAtRow:(int)row andCol:(int)col
{
    SKNode *world = [self childNodeWithName:@"world"];
    
    SKSpriteNode *tile = [SKSpriteNode node];
    
    tile.position = CGPointMake(col * teilHeight + teilHeight/2, row * teilWidth + teilWidth/2);
    tile.size = CGSizeMake(teilWidth, teilHeight);
    tile.color = [UIColor whiteColor];
    tile.name = [NSString stringWithFormat:@"%d", row];
    tile.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:tile.size];
    tile.physicsBody.dynamic = NO;
    
    [world addChild:tile];
}


- (void)buildRiverAtRow:(int)row andCol:(int)col
{
    SKNode *world = [self childNodeWithName:@"world"];
    
    SKSpriteNode *tile = [SKSpriteNode node];
    
    tile.position = CGPointMake(col * teilHeight + teilHeight/2, row * teilWidth + teilWidth/2);
    tile.size = CGSizeMake(teilWidth, teilHeight);
    tile.color = [UIColor blueColor];
    tile.name = [NSString stringWithFormat:@"%d", row];
    
    [world addChild:tile];
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
//    for (UITouch *touch in touches) {
//        CGPoint location = [touch locationInNode:self];
//        
//        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
//        
//        sprite.position = location;
//        
//        SKAction *action = [SKAction rotateByAngle:M_PI duration:1];
//        
//        [sprite runAction:[SKAction repeatActionForever:action]];
//        
//        [self addChild:sprite];
//    }
}

#pragma mark - Core Motion

- (void)outputAccelertionData:(CMAcceleration)acceleration
{
    double maxAccelerationX = 0.1;
    double accelerationAdjusted = acceleration.x;
    
    if (fabs(acceleration.x) > maxAccelerationX) {
        if (acceleration.x < 0) {
            accelerationAdjusted = - maxAccelerationX;
        } else {
            accelerationAdjusted = maxAccelerationX;
        }
    }
    
    self.physicsWorld.gravity = CGVectorMake(accelerationAdjusted * 20, 0.0);
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
