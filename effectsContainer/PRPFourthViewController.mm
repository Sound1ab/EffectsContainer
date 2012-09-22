//
//  PRPFourthViewController.m
//  effectsContainer
//
//  Created by Phillip Parker on 29/08/2012.
//  Copyright (c) 2012 Phillip Parker. All rights reserved.
//

#import "PRPFourthViewController.h"
#import "MHRotaryKnob.h"

@interface PRPFourthViewController ()


@end

@implementation PRPFourthViewController
@synthesize rotaryVarispeed;
@synthesize pitchShifter;
@synthesize frequency;
@synthesize audioObject;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    PRPaudioObject* sharedSingleton = [PRPaudioObject sharedInstance];
    audioObject = sharedSingleton;
    
    rotaryVarispeed.maximumValue = 2.0f;
	rotaryVarispeed.minimumValue = 0.0f;
	rotaryVarispeed.value = 1.0f;
    rotaryVarispeed.tag = 0;
    
    //Slider images
    UIImage *minImage               = [UIImage imageNamed:@"sliderBarLeft.png"];
    UIImage *maxImage               = [UIImage imageNamed:@"sliderBarRight.png"];
    UIImage *Depressed     = [UIImage imageNamed:@"sliderButtonDepressed_New.png"];
    UIImage *Pressed       = [UIImage imageNamed:@"sliderButtonPressed_New.png"];
    
    
    //Set the min and maximum stretchable area for the bar images
    minImage = [minImage stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
    maxImage = [maxImage stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
    
    //MHRotaryKnob *placeHolder = [startData objectAtIndex:i];
    rotaryVarispeed.interactionStyle = MHRotaryKnobInteractionStyleRotating;
    rotaryVarispeed.interactionStyle = MHRotaryKnobInteractionStyleRotating;
    rotaryVarispeed.scalingFactor = 1.5f;
    rotaryVarispeed.defaultValue = rotaryVarispeed.value;
    rotaryVarispeed.resetsToDefault = YES;
    rotaryVarispeed.backgroundColor = [UIColor clearColor];
    rotaryVarispeed.backgroundImage = [UIImage imageNamed:@"Knob Background_New.png"];
    [rotaryVarispeed setKnobImage:[UIImage imageNamed:@"Knob_New.png"] forState:UIControlStateNormal];
    [rotaryVarispeed setKnobImage:[UIImage imageNamed:@"Knob Highlighted.png"] forState:UIControlStateHighlighted];
    [rotaryVarispeed setKnobImage:[UIImage imageNamed:@"Knob Disabled.png"] forState:UIControlStateDisabled];
    rotaryVarispeed.knobImageCenter = CGPointMake(50.0f, 50.0f);
    
    //Set slider images for note frequency slider
    [pitchShifter setMinimumTrackImage:minImage forState:UIControlStateNormal];
    [pitchShifter setMaximumTrackImage:maxImage forState:UIControlStateNormal];
    [pitchShifter setThumbImage:Depressed forState:UIControlStateNormal];
    [pitchShifter setThumbImage:Pressed forState:UIControlStateHighlighted];
    
    self->packetTimer = [NSTimer timerWithTimeInterval:0.01 target:self selector:@selector(onTick:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:packetTimer forMode:NSDefaultRunLoopMode];
}

- (void)viewDidUnload
{
    [self setRotaryVarispeed:nil];
    [self setPitchShifter:nil];
    [self setFrequency:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (IBAction)rotaryKnobDidMove:(MHRotaryKnob *)sender {
    
    UInt32 inputNum = [sender tag];
    NSNumber *tag = [NSNumber numberWithInt:inputNum];
    
    Float32 sliderValue = sender.value;
    NSNumber *senderValue = [NSNumber numberWithFloat:sliderValue];
    
    if (audioObject.playing == YES)
    [audioObject varispeedControls:tag :senderValue];
}

- (IBAction)pitchShift:(UISlider *)sender {
    
    
    float sliderValue = sender.value;
    //NSNumber *senderValue = [NSNumber numberWithFloat:sliderValue];
    
    if (audioObject.playing == YES)
        audioObject.pitch = *(&(sliderValue));
    
}


- (void)onTick:(NSTimer *)aTimer{
    
    frequency.text = [NSString stringWithFormat:@"%f", audioObject.frequencyOut];

    
}
@end
