//
//  PRPSecondViewController.h
//  effectsContainer
//
//  Created by Phillip Parker on 29/08/2012.
//  Copyright (c) 2012 Phillip Parker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PRPaudioObject.h"

@class MHRotaryKnob;

@interface PRPSecondViewController : UIViewController{
    
    PRPaudioObject *audioObject;
}

@property (nonatomic, retain) PRPaudioObject   *audioObject;

@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryWetDry;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryDecayTime;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryDecayTimeAtNyquist;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryGain;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryMaxDelayTime;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryRandomiseReflections;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryMinDelayTime;

- (IBAction)rotaryKnobDidMove:(MHRotaryKnob *)sender;

@end
