//
//  PRPFifthViewController.h
//  effectsContainer
//
//  Created by Phillip Parker on 29/08/2012.
//  Copyright (c) 2012 Phillip Parker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PRPaudioObject.h"

@class MHRotaryKnob;

@interface PRPFifthViewController : UIViewController{
    
    PRPaudioObject *audioObject;
    
}

@property (nonatomic, retain) PRPaudioObject   *audioObject;

@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryAttack;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryRelease;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryThreshold;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryGain;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryExpanRatio;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryExpanThresh;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryHeadroom;
- (IBAction)didMoveKnob:(MHRotaryKnob *)sender;
@end
