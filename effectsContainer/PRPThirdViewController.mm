//
//  PRPThirdViewController.m
//  effectsContainer
//
//  Created by Phillip Parker on 29/08/2012.
//  Copyright (c) 2012 Phillip Parker. All rights reserved.
//

#import "PRPThirdViewController.h"
#import "MHRotaryKnob.h"

@interface PRPThirdViewController ()

@end

@implementation PRPThirdViewController
@synthesize lowPassCutFreg;
@synthesize lowPassRes;
@synthesize hiPassCutFreg;
@synthesize hiPassRes;
@synthesize audioObject;

- (void)viewDidLoad
{
    [super viewDidLoad];
    PRPaudioObject* sharedSingleton = [PRPaudioObject sharedInstance];
    audioObject = sharedSingleton;
    
    NSArray *startData = [[NSMutableArray alloc] initWithObjects:lowPassCutFreg,lowPassRes,hiPassCutFreg, hiPassRes, nil];
    
    
    lowPassCutFreg.maximumValue = 20000.0f;
	lowPassCutFreg.minimumValue = 10.0f;
	lowPassCutFreg.value = 20000.0f;
    lowPassCutFreg.tag = 0;
    
    lowPassRes.maximumValue = 40.0f;
	lowPassRes.minimumValue = -20.0f;
	lowPassRes.value = 0.0f;
    lowPassRes.tag = 1;
    
    hiPassCutFreg.maximumValue = 20000.0f;
	hiPassCutFreg.minimumValue = 10.0f;
	hiPassCutFreg.value = 10.0f;
    hiPassCutFreg.tag = 2;
    
    hiPassRes.maximumValue = 40.0f;
	hiPassRes.minimumValue = -20.0f;
	hiPassRes.value = 0.0f;
    hiPassRes.tag = 3;
    
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
    [self setLowPassCutFreg:nil];
    [self setLowPassRes:nil];
    [self setHiPassCutFreg:nil];
    [self setHiPassRes:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)knobDidMove:(MHRotaryKnob *)sender {
    
    //NSLog(@"tag: %d value:%f",sender.tag,sender.value);
    
    UInt32 inputNum = [sender tag];
    NSNumber *tag = [NSNumber numberWithInt:inputNum];
    
    Float32 sliderValue = sender.value;
    NSNumber *senderValue = [NSNumber numberWithFloat:sliderValue];
    
    if (audioObject.playing == YES)
    [audioObject filterControls:tag :senderValue];
    
}
@end
