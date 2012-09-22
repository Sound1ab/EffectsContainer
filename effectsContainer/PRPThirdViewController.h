//
//  PRPThirdViewController.h
//  effectsContainer
//
//  Created by Phillip Parker on 29/08/2012.
//  Copyright (c) 2012 Phillip Parker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PRPaudioObject.h"

@class MHRotaryKnob;

@interface PRPThirdViewController : UIViewController{
    
    PRPaudioObject *audioObject;
}

@property (nonatomic, retain) PRPaudioObject   *audioObject;

@property (strong, nonatomic) IBOutlet MHRotaryKnob *lowPassCutFreg;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *lowPassRes;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *hiPassCutFreg;
@property (strong, nonatomic) IBOutlet MHRotaryKnob *hiPassRes;

- (IBAction)knobDidMove:(MHRotaryKnob *)sender;

@end
