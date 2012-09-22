//
//  PRPFifthViewController.m
//  effectsContainer
//
//  Created by Phillip Parker on 29/08/2012.
//  Copyright (c) 2012 Phillip Parker. All rights reserved.
//

#import "PRPFifthViewController.h"
#import "MHRotaryKnob.h"

@interface PRPFifthViewController ()

@end

@implementation PRPFifthViewController
@synthesize rotaryAttack;
@synthesize rotaryRelease;
@synthesize rotaryThreshold;
@synthesize rotaryGain;
@synthesize rotaryExpanRatio;
@synthesize rotaryExpanThresh;
@synthesize rotaryHeadroom;
@synthesize audioObject;

- (void)viewDidLoad
{
    [super viewDidLoad];
	PRPaudioObject* sharedSingleton = [PRPaudioObject sharedInstance];
    audioObject = sharedSingleton;
    
    NSArray *startData = [[NSMutableArray alloc] initWithObjects:rotaryAttack,rotaryRelease,rotaryThreshold, rotaryGain,rotaryExpanRatio,rotaryExpanThresh,rotaryHeadroom, nil];
    
    
    rotaryAttack.maximumValue = 0.2f;
	rotaryAttack.minimumValue = 0.0001f;
	rotaryAttack.value = 0.0001f;
    rotaryAttack.tag = 0;
    
    rotaryRelease.maximumValue = 3.0f;
	rotaryRelease.minimumValue = 0.01f;
	rotaryRelease.value = 0.01f;
    rotaryRelease.tag = 1;
    
    rotaryThreshold.maximumValue = 20.0f;
	rotaryThreshold.minimumValue = -40.0f;
	rotaryThreshold.value = 0.0f;
    rotaryThreshold.tag = 2;
    
    rotaryGain.maximumValue = 40.0f;
	rotaryGain.minimumValue = -40.0f;
	rotaryGain.value = 0.0f;
    rotaryGain.tag = 3;
    
    rotaryExpanRatio.maximumValue = 50.0f;
	rotaryExpanRatio.minimumValue = 1.0f;
	rotaryExpanRatio.value = 1.0f;
    rotaryExpanRatio.tag = 4;
    
    rotaryExpanThresh.maximumValue = 20.0f;
	rotaryExpanThresh.minimumValue = -40.0f;
	rotaryExpanThresh.value = 0.0f;
    rotaryExpanThresh.tag = 5;
    
    rotaryHeadroom.maximumValue = 40.0f;
	rotaryHeadroom.minimumValue = 0.1f;
	rotaryHeadroom.value = 0.1f;
    rotaryHeadroom.tag = 6;
    
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
    [self setRotaryAttack:nil];
    [self setRotaryRelease:nil];
    [self setRotaryThreshold:nil];
    [self setRotaryGain:nil];
    [self setRotaryExpanRatio:nil];
    [self setRotaryExpanThresh:nil];
    [self setRotaryHeadroom:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)didMoveKnob:(MHRotaryKnob *)sender {
    
    //NSLog(@"tag: %d value:%f",sender.tag,sender.value);
    
    UInt32 inputNum = [sender tag];
    NSNumber *tag = [NSNumber numberWithInt:inputNum];
    
    Float32 sliderValue = sender.value;
    NSNumber *senderValue = [NSNumber numberWithFloat:sliderValue];
    
    if (audioObject.playing == YES)
    [audioObject dynamicControls:tag :senderValue];

}
@end
