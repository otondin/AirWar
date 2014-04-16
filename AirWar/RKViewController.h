//
//  RKViewController.h
//  AirWar
//

//  Copyright (c) 2014 Rodrigo Krummenauer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>

@interface RKViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIImageView *AWLogo;
@property (strong, nonatomic) IBOutlet UIButton *insertCoin;

- (IBAction)startGAme:(id)sender;


@end
