//
//  RKMyScene.m
//  AirWar
//
//  Created by Rodrigo K on 4/15/14.
//  Copyright (c) 2014 Rodrigo Krummenauer. All rights reserved.
//

#import "RKMyScene.h"

@interface RKMyScene ()

@property (nonatomic, strong) SKSpriteNode *plane;
@property (strong) NSMutableArray* tapQueue;

@end

#define kAirPlaneFiredBulletName @"airPlaneFiredBullet"
#define kBulletSize CGSizeMake(4, 8)


@implementation RKMyScene {
    CGFloat teilWidth;
    CGFloat teilHeight;
    double currentMaxAccelX;
    double currentMaxAccelY;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
        self.physicsWorld.contactDelegate = self;
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        self.physicsBody.linearDamping = 0;
        self.physicsBody.categoryBitMask = WORLD;
        self.physicsBody.collisionBitMask = AIRPLANE;
        
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
        
        
        if (self.plane) {
            [self addChild:self.plane];
        }
    
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

- (void)didMoveToView:(SKView *)view
{
    self.tapQueue = [[NSMutableArray alloc] init];
    self.userInteractionEnabled = YES;
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
    tile.color = [UIColor greenColor];
    tile.name = [NSString stringWithFormat:@"%d", row];
    tile.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:tile.size];
    tile.physicsBody.dynamic = NO;
    tile.physicsBody.linearDamping = 0;
    tile.physicsBody.restitution = 0;
    tile.physicsBody.categoryBitMask = OBSTACLE;
    tile.physicsBody.collisionBitMask = AIRPLANE;
    
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

#pragma mark - Scene Update Helpers

- (void)processUserTapsForUpdate:(NSTimeInterval)currentTime
{
    //    NSArray *tapQueue = [self.tapQueue copy];
    
    for (NSNumber* tapCount in self.tapQueue) {
        [self fireShipBullets];
        [self.tapQueue removeObject:tapCount];
    }
}

#pragma mark - User touch helpers

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.tapQueue addObject:@1];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Intentional no-op
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Intentional no-op
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Intentional no-op
}


#pragma mark - Bullet Helpers

- (void)fireBullet:(SKSpriteNode *)bullet toDestination:(CGPoint)destination withDuration:(NSTimeInterval)duration soundFileName:(NSString*)soundFileName
{
    SKAction* bulletAction = [SKAction sequence:@[[SKAction moveTo:destination duration:duration],
                                                  [SKAction waitForDuration:3.0/60.0],
                                                  [SKAction removeFromParent]]];
    
    SKAction* soundAction  = [SKAction playSoundFileNamed:soundFileName waitForCompletion:YES];
    [bullet runAction:[SKAction group:@[bulletAction, soundAction]]];
    [self addChild:bullet];
}

- (void)fireShipBullets
{
    SKSpriteNode *bullet = [self makeBullet];
    CGPoint bulletDestination = CGPointMake(self.plane.position.x, self.frame.size.height + bullet.frame.size.height / 2);
    [self fireBullet:bullet toDestination:bulletDestination withDuration:1.0 soundFileName:@"AirPlaneBullet.wav"];
}

#pragma mark - Sprites

- (SKSpriteNode *)plane
{
    if(!_plane) {
        _plane = [SKSpriteNode spriteNodeWithImageNamed:@"airplane.png"];
        _plane.size = CGSizeMake(teilHeight*2, teilWidth*2);
        _plane.position = CGPointMake(self.size.width/2, 100);
        _plane.color = [UIColor blackColor];
        _plane.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_plane.size];
        _plane.physicsBody.affectedByGravity = NO;
        _plane.physicsBody.allowsRotation = NO;
        _plane.physicsBody.categoryBitMask = AIRPLANE;
        _plane.physicsBody.collisionBitMask = OBSTACLE;
        _plane.physicsBody.contactTestBitMask = ENEMY;
    }
    
    return _plane;
}

- (SKSpriteNode *)makeBullet
{
    SKSpriteNode *bullet = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:kBulletSize];
    
    bullet.position = CGPointMake(self.plane.position.x, self.plane.position.y + self.plane.frame.size.height - bullet.frame.size.height / 2);
    bullet.name = kAirPlaneFiredBulletName;
    bullet.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:bullet.size];
    bullet.physicsBody.affectedByGravity = NO;
    bullet.physicsBody.categoryBitMask = BULLET;
    bullet.physicsBody.contactTestBitMask = ENEMY;
    
    return bullet;
}

#pragma mark - Core Motion

-(void)update:(NSTimeInterval)currentTime{
    
    float maxY = self.size.width - self.plane.size.width/2;
    float minY = self.plane.size.width/2;
    
    float newX = 0;
    
    if(currentMaxAccelX > 0.05){
        newX = currentMaxAccelX * 10;
        
    }
    else if(currentMaxAccelX < -0.05){
        newX = currentMaxAccelX*10;
        
    }
    else{
        newX = currentMaxAccelX*10;
        
    }
    
    newX = MIN(MAX(newX+self.plane.position.x,minY),maxY);
    
    self.plane.position = CGPointMake(newX, self.plane.position.y);
    
    [self processUserTapsForUpdate:currentTime];
}

-(void)outputAccelertionData:(CMAcceleration)acceleration
{
    currentMaxAccelX = 0;
    currentMaxAccelY = 0;
    
    if(fabs(acceleration.x) > fabs(currentMaxAccelX))
    {
        currentMaxAccelX = acceleration.x;
    }
    if(fabs(acceleration.y) > fabs(currentMaxAccelY))
    {
        currentMaxAccelY = acceleration.y;
    }
}
@end
