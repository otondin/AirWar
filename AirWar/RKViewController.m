//
//  RKViewController.m
//  AirWar
//
//  Created by Rodrigo K on 4/15/14.
//  Copyright (c) 2014 Rodrigo Krummenauer. All rights reserved.
//

#import "RKViewController.h"
#import "RKMyScene.h"

@implementation RKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)startGAme:(id)sender {
    
    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    skView.showsPhysics = YES;
    
    // Create and configure the scene.
    SKScene * scene = [RKMyScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
    
    _AWLogo.hidden = YES;
    _insertCoin.hidden = YES;
    
}
@end
