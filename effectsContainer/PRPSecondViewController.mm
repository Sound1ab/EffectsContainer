//
//  PRPSecondViewController.m
//  effectsContainer
//
//  Created by Phillip Parker on 29/08/2012.
//  Copyright (c) 2012 Phillip Parker. All rights reserved.
//

#import "PRPSecondViewController.h"
#import "MHRotaryKnob.h"

@interface PRPSecondViewController ()

@end

@implementation PRPSecondViewController
@synthesize audioObject;
@synthesize rotaryWetDry;
@synthesize rotaryDecayTime;
@synthesize rotaryDecayTimeAtNyquist;
@synthesize rotaryGain;
@synthesize rotaryMaxDelayTime;
@synthesize rotaryRandomiseReflections;
@synthesize rotaryMinDelayTime;

- (void)viewDidLoad
{
    [super viewDidLoad];

    PRPaudioObject* sharedSingleton = [PRPaudioObject sharedInstance];
    audioObject = sharedSingleton;
    
    NSArray *startData = [[NSMutableArray alloc] initWithObjects:rotaryWetDry,rotaryDecayTime,rotaryDecayTimeAtNyquist, rotaryGain, rotaryMaxDelayTime, rotaryRandomiseReflections, rotaryMinDelayTime, nil];
    
    
    rotaryWetDry.maximumValue = 100.0f;
	rotaryWetDry.minimumValue = 0.0f;
	rotaryWetDry.value = 0.0f;
    rotaryWetDry.tag = 0;
    
    rotaryDecayTime.maximumValue = 20.0f;
	rotaryDecayTime.minimumValue = 0.0001f;
	rotaryDecayTime.value = 0.0001f;
    rotaryDecayTime.tag = 1;
    
    rotaryDecayTimeAtNyquist.maximumValue = 20.0f;
	rotaryDecayTimeAtNyquist.minimumValue = 0.0001f;
	rotaryDecayTimeAtNyquist.value = 0.0001f;
    rotaryDecayTimeAtNyquist.tag = 2;
    
    rotaryGain.maximumValue = 20.0f;
	rotaryGain.minimumValue = -20.0f;
	rotaryGain.value = 0.0f;
    rotaryGain.tag = 3;
    
    rotaryMaxDelayTime.maximumValue = 1.0f;
	rotaryMaxDelayTime.minimumValue = 0.0001f;
	rotaryMaxDelayTime.value = 0.0001f;
    rotaryMaxDelayTime.tag = 4;
    
    rotaryMinDelayTime.maximumValue = 1.0f;
	rotaryMinDelayTime.minimumValue = 0.0001f;
	rotaryMinDelayTime.value = 0.0001f;
    rotaryMinDelayTime.tag = 5;
    
    rotaryRandomiseReflections.maximumValue = 1000.0f;
	rotaryRandomiseReflections.minimumValue = 0.0f;
	rotaryRandomiseReflections.value = 0.0f;
    rotaryRandomiseReflections.tag = 6;
    
    for (int i = 0; i < [startData count]; i++) {
        
        MHRotaryKnob *placeHolder = [startData objectAtIndex:i];
        placeHolder.interactionStyle = MHRotaryKnobInteractionStyleRotating;
        placeHolder.interactionStyle = MHRotaryKnobInteractionStyleRotating;
        placeHolder.scalingFactor = 1.5f;
        placeHolder.defaultValue = placeHolder.value;
        placeHolder.resetsToDefault = YES;
        placeHolder.backgroundColor = [UIColor clearColor];
        placeHolder.backgroundImage = [UIImage imageNamed:@"Knob Background_New.png"];
        [placeHolder setKnobImage:[UIImage imageNamed:@"Knob_New.png"] forState:UIControlStateNormal];
        [placeHolder setKnobImage:[UIImage imageNamed:@"Knob Highlighted.png"] forState:UIControlStateHighlighted];
        [placeHolder setKnobImage:[UIImage imageNamed:@"Knob Disabled.png"] forState:UIControlStateDisabled];
        placeHolder.knobImageCenter = CGPointMake(50.0f, 50.0f);
        
    }
}

- (void)viewDidUnload
{
    [self setRotaryWetDry:nil];
    [self setRotaryDecayTime:nil];
    [self setRotaryDecayTimeAtNyquist:nil];
    [self setRotaryGain:nil];
    [self setRotaryMaxDelayTime:nil];
    [self setRotaryRandomiseReflections:nil];
    [self setRotaryMinDelayTime:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)rotaryKnobDidMove:(MHRotaryKnob *)sender {
    
    UInt32 inputNum = sender.tag;
    NSNumber *tag = [NSNumber numberWithInt:inputNum];
    
    Float32 sliderValue = sender.value;
    NSNumber *senderValue = [NSNumber numberWithFloat:sliderValue];
    
    if (audioObject.playing == YES) {
            [audioObject reverbControls:tag :senderValue];
    }


}
@end
