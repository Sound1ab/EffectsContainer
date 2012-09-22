//
//  PRPaudioObject.h
//  effectsContainer
//
//  Created by Phillip Parker on 29/08/2012.
//  Copyright (c) 2012 Phillip Parker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CAStreamBasicDescription.h"
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>			// for vdsp functions

typedef struct {
    
    BOOL                 isStereo;           // set to true if there is data in the audioDataRight member
    UInt32               frameCount;         // the total number of frames in the audio data
    UInt32               sampleNumber;       // the next audio sample to play
    AudioUnitSampleType  *audioDataLeft;     // the complete left (or mono) channel of audio data read from an audio file
    AudioUnitSampleType  *audioDataRight;    // the complete right channel of audio data read from an audio file
    BOOL                 fileReady;

    
} soundStruct, *soundStructPtr;
@interface PRPaudioObject : NSObject{
    
    // Audio Unit References
	AUGraph   mGraph;
	AudioUnit mFilePlayer;
    AudioUnit mFilePlayer2;
    AudioUnit mReverb;
    AudioUnit mLowPass;
    AudioUnit mhighPass;
    AudioUnit mdistortion;
    AudioUnit mMixer;
    AudioUnit mVarispeed;
    AudioUnit mDynamic;
    AudioUnit mRIO;
    
	// Audio Stream Descriptions
	CAStreamBasicDescription outputCASBD;
    
    // Audio File Location
    AudioFileID inputFile;
    AudioFileID inputFile2;
    
    //Audio file refereces for saving
    ExtAudioFileRef                extAudioFile;

    //Standard sample rate
    Float64                         graphSampleRate;

    //ASBD
    AudioStreamBasicDescription     monoStreamFormat864;
    AudioStreamBasicDescription     monoStreamFormatSINT16;
    AudioStreamBasicDescription     recordStreamFormat;
    AudioStreamBasicDescription     stereoStreamFormat864;

    
    //FFT Requirements
    FFTSetup fftSetup;			// fft predefined structure required by vdsp fft functions
	COMPLEX_SPLIT fftA;			// complex variable for fft
	int fftLog2n;               // base 2 log of fft size
    int fftN;                   // fft size
    int fftNOver2;              // half fft size
	size_t fftBufferCapacity;	// fft buffer size (in samples)
	size_t fftIndex;            // read index pointer in fft buffer
    
    //Buffers
    void *dataBuffer;               //  input buffer from mic/line
	float *outputBuffer;            //  fft conversion buffer
	float *analysisBuffer;          //  fft analysis buffer

    SInt16 *conversionBuffer;
    
    float pitch;
    
    float frequencyOut;

     soundStruct                     soundStructArray[1];
    
}
@property float pitch;
@property float frequencyOut;

@property (readwrite)           Float64                     graphSampleRate;
@property (getter = isPlaying)  BOOL                        playing;

@property FFTSetup fftSetup;
@property COMPLEX_SPLIT fftA;
@property int fftLog2n;
@property int fftN;
@property int fftNOver2;
@property size_t fftBufferCapacity;
@property size_t fftIndex;

@property void *dataBuffer;
@property float *outputBuffer;
@property float *analysisBuffer;

//@property (strong, nonatomic) NSNumber *pitch;

- (void)startAudio;
- (void)stopAudio;

- (void) reverbControls: (NSNumber *) value :(NSNumber *) value2;
- (void) filterControls: (NSNumber *) value:(NSNumber *) value2;
- (void) distortionControls: (NSNumber *) value;
- (void) varispeedControls: (NSNumber *) value:(NSNumber *) value2;
- (void) volumeControls: (NSNumber *) value :(NSNumber *) value2;
- (void) dynamicControls: (NSNumber *) value:(NSNumber *) value2;
- (void) panControls: (NSNumber *) value :(NSNumber *) value2;

- (void)startRecordingAAC;

- (void) readAudioFilesIntoMemory;

- (Float32)inputVolume0;
- (Float32)inputVolume1;
- (Float32)inputVolume2;

- (void) printASBD: (AudioStreamBasicDescription) asbd;

- (void)initializeAUGraph;
- (void)startAUGraph;
- (void)stopAUGraph;
-(OSStatus) setUpAUFilePlayer;
-(OSStatus) setUpAUFilePlayer2;

- (void) setupMonoStream864;
- (void) setupMonoStreamSINT16;

- (void) FFTSetup;

-(void)playRecordedFile;

- (void)stopAU;

+ (id)sharedInstance;

@end
