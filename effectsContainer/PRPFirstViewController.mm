//
//  PRPFirstViewController.m
//  effectsContainer
//
//  Created by Phillip Parker on 29/08/2012.
//  Copyright (c) 2012 Phillip Parker. All rights reserved.
//

#import "PRPFirstViewController.h"
#import "MHRotaryKnob.h"


@interface PRPFirstViewController ()

@end

@implementation PRPFirstViewController
@synthesize audioObject;
@synthesize channelOneSlider;
@synthesize channelTwoSlider;
@synthesize channelThreeSlider;
@synthesize channel0;
@synthesize channel1;
@synthesize channel2;
@synthesize startButton;
@synthesize stopButton;
@synthesize recordButton;
@synthesize rotaryPanOne;
@synthesize rotaryPanTwo;
@synthesize rotaryPanThree;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    PRPaudioObject* sharedSingleton = [PRPaudioObject sharedInstance];
    audioObject = sharedSingleton;
    
    //Slider images
    UIImage *minImage               = [UIImage imageNamed:@"sliderBarLeft.png"];
    UIImage *maxImage               = [UIImage imageNamed:@"sliderBarRight.png"];
    UIImage *Depressed     = [UIImage imageNamed:@"sliderButtonDepressed_New.png"];
    UIImage *Pressed       = [UIImage imageNamed:@"sliderButtonPressed_New.png"];

    
    //Set the min and maximum stretchable area for the bar images
    minImage = [minImage stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
    maxImage = [maxImage stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
    
    //Set slider images for threshold slider
    [channelOneSlider setMinimumTrackImage:minImage forState:UIControlStateNormal];
    [channelOneSlider setMaximumTrackImage:maxImage forState:UIControlStateNormal];
    [channelOneSlider setThumbImage:Depressed forState:UIControlStateNormal];
    [channelOneSlider setThumbImage:Pressed forState:UIControlStateHighlighted];
    
    //Set slider images for note frequency slider
    [channelTwoSlider setMinimumTrackImage:minImage forState:UIControlStateNormal];
    [channelTwoSlider setMaximumTrackImage:maxImage forState:UIControlStateNormal];
    [channelTwoSlider setThumbImage:Depressed forState:UIControlStateNormal];
    [channelTwoSlider setThumbImage:Pressed forState:UIControlStateHighlighted];
    
    //Set slider images for note frequency slider
    [channelThreeSlider setMinimumTrackImage:minImage forState:UIControlStateNormal];
    [channelThreeSlider setMaximumTrackImage:maxImage forState:UIControlStateNormal];
    [channelThreeSlider setThumbImage:Depressed forState:UIControlStateNormal];
    [channelThreeSlider setThumbImage:Pressed forState:UIControlStateHighlighted];
    

    
    //Deallocate the images
    minImage                = nil;
    maxImage                = nil;
    Depressed      = nil;
    Pressed        = nil;
    
    NSArray *startData = [[NSMutableArray alloc] initWithObjects:rotaryPanOne,rotaryPanTwo,rotaryPanThree, nil];
    
    rotaryPanOne.maximumValue = 1.0f;
	rotaryPanOne.minimumValue = -1.0f;
	rotaryPanOne.value = 0.0f;
    rotaryPanOne.tag = 0;
    
    rotaryPanTwo.maximumValue = 1.0f;
	rotaryPanTwo.minimumValue = -1.0f;
	rotaryPanTwo.value = 0.0f;
    rotaryPanTwo.tag = 1;
    
    rotaryPanThree.maximumValue = 1.0f;
	rotaryPanThree.minimumValue = -1.0f;
	rotaryPanThree.value = 0.0f;
    rotaryPanThree.tag = 2;
    
    
    for (int i = 0; i < [startData count]; i++) {
        
        MHRotaryKnob *placeHolder = [startData objectAtIndex:i];
        placeHolder.interactionStyle = MHRotaryKnobInteractionStyleRotating;
        placeHolder.interactionStyle = MHRotaryKnobInteractionStyleRotating;
        placeHolder.scalingFactor = 1.5f;
        placeHolder.defaultValue = placeHolder.value;
        placeHolder.resetsToDefault = YES;
        placeHolder.backgroundColor = [UIColor clearColor];
        placeHolder.backgroundImage = [UIImage imageNamed:@"Knob Background_Mini.png"];
        [placeHolder setKnobImage:[UIImage imageNamed:@"Knob_Mini.png"] forState:UIControlStateNormal];
        [placeHolder setKnobImage:[UIImage imageNamed:@"Knob Highlighted.png"] forState:UIControlStateHighlighted];
        [placeHolder setKnobImage:[UIImage imageNamed:@"Knob Background_Disabled_Small.png"] forState:UIControlStateDisabled];
        placeHolder.knobImageCenter = CGPointMake(35.0f, 35.0f);
        
    }
    
    
    stopButton.enabled = NO;
    recordButton.enabled = NO;


}

- (void)viewDidUnload
{
    [self setChannelOneSlider:nil];
    [self setChannelTwoSlider:nil];
    [self setChannel0:nil];
    [self setChannel1:nil];
    [self setStartButton:nil];
    [self setRotaryPanOne:nil];
    [self setRotaryPanTwo:nil];
    [self setRotaryPanThree:nil];
    [self setChannelThreeSlider:nil];
    [self setChannel2:nil];
    [self setStopButton:nil];
    [self setRecordButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)knonDidMove:(MHRotaryKnob *)sender {
    
    //NSLog(@"tag: %d value:%f",sender.tag,sender.value);
    
    UInt32 inputNum = [sender tag];
    NSNumber *tag = [NSNumber numberWithInt:inputNum];
    
    Float32 sliderValue = sender.value;
    NSNumber *senderValue = [NSNumber numberWithFloat:sliderValue];
    
    if (audioObject.playing == YES)
    [audioObject panControls:tag :senderValue];

}

- (IBAction)test:(id)sender {
    
    [audioObject stopAU];
}

- (IBAction)start:(id)sender {

    [audioObject startAudio];
    [self startTimer];
    startButton.enabled = NO;
    stopButton.enabled = YES;
    recordButton.enabled = YES;

    playState.playing = true;
    
    
    
}
- (IBAction)stop:(id)sender {
    
    [audioObject stopAudio];
    startButton.enabled = YES;
    stopButton.enabled = NO;
    recordButton.enabled = NO;
    
    playState.playing = false;


}

- (IBAction)record:(id)sender {
    
    [audioObject startRecordingAAC];
    
    //recordButton.alpha = 0;
    
    NSLog(@"record pressed");
}

- (IBAction)volumeControl:(UISlider *)sender {
    
    UInt32 inputNum = [sender tag];
    NSNumber *tag = [NSNumber numberWithInt:inputNum];
    
    Float32 sliderValue = sender.value;
    NSNumber *senderValue = [NSNumber numberWithFloat:sliderValue];
    
    if (audioObject.playing == YES)
    [audioObject volumeControls:tag :senderValue];

}



-(void)startTimer {
    self->packetTimer = [NSTimer timerWithTimeInterval:0.01 target:self selector:@selector(onTick:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:packetTimer forMode:NSDefaultRunLoopMode];
}
- (void)onTick:(NSTimer *)aTimer{
    
    
    Float32 adder = 70;
    Float32 volume0 = audioObject.inputVolume0;
    Float32 volume1 = audioObject.inputVolume1;
    Float32 volume2 = audioObject.inputVolume2;

    channel0.progress = (volume0 + adder)/100;
    channel1.progress = (volume1 + adder)/100;
    channel2.progress = (volume2 + adder)/100;
        
     if (playState.playing == false) {
     [aTimer invalidate];
     aTimer = nil;
         
         channel0.progress = 0;
         channel1.progress = 0;
         channel2.progress = 0;

     }
     
}




@end
