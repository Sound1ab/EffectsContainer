//
//  PRPFirstViewController.h
//  effectsContainer
//
//  Created by Phillip Parker on 29/08/2012.
//  Copyright (c) 2012 Phillip Parker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PRPaudioObject.h"

@class MHRotaryKnob;

typedef struct
{
    bool                         playing;
} PlayState;

@interface PRPFirstViewController : UIViewController{

    PRPaudioObject *audioObject;
    NSTimer *packetTimer;
    PlayState   playState;

}

@property (nonatomic, retain) PRPaudioObject   *audioObject;
@property (strong, nonatomic) IBOutlet UISlider *channelOneSlider;
@property (strong, nonatomic) IBOutlet UISlider *channelTwoSlider;
@property (strong, nonatomic) IBOutlet UISlider *channelThreeSlider;
@property (strong, nonatomic) IBOutlet UIProgressView *channel0;
@property (strong, nonatomic) IBOutlet UIProgressView *channel1;
@property (strong, nonatomic) IBOutlet UIProgressView *channel2;
@property (strong, nonatomic) IBOutlet UIButton *startButton;
@property (strong, nonatomic) IBOutlet UIButton *stopButton;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryPanOne;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryPanTwo;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *rotaryPanThree;
- (IBAction)knonDidMove:(MHRotaryKnob *)sender;
- (IBAction)test:(id)sender;

- (IBAction)start:(id)sender;
- (IBAction)volumeControl:(UISlider *)sender;
- (IBAction)stop:(id)sender;
- (IBAction)record:(id)sender;


@end
