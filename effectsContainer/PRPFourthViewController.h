//
//  PRPFourthViewController.h
//  effectsContainer
//
//  Created by Phillip Parker on 29/08/2012.
//  Copyright (c) 2012 Phillip Parker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PRPaudioObject.h"

@class MHRotaryKnob;

@interface PRPFourthViewController : UIViewController{
    
    PRPaudioObject *audioObject;
    NSTimer *packetTimer;

    
}

@property (nonatomic, retain) PRPaudioObject   *audioObject;

@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryVarispeed;
@property (strong, nonatomic) IBOutlet UISlider *pitchShifter;
@property (strong, nonatomic) IBOutlet UILabel *frequency;
- (IBAction)rotaryKnobDidMove:(MHRotaryKnob *)sender;
- (IBAction)pitchShift:(UISlider *)sender;

@end
