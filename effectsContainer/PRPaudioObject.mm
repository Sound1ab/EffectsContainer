//
//  PRPaudioObject.m
//  effectsContainer
//
//  Created by Phillip Parker on 29/08/2012.
//  Copyright (c) 2012 Phillip Parker. All rights reserved.
//

#import "PRPaudioObject.h"
#import "smbPitchShift.m"

//************************************************************
//*** Song definitions ***
//************************************************************
#define SONG_TITLE @"beatsMono"
#define SONG_FILE_TYPE @"caf"
#define SONG_TITLE2 @"guitarStereo"
#define SONG_FILE_TYPE2 @"caf"

// Native iphone sample rate of 44.1kHz, same as a CD.
const Float64 kGraphSampleRate = 44100.0;

OSStatus fftPitchShift ( void *inRefCon, UInt32 inNumberFrames, SInt16 *sampleBuffer);

@implementation PRPaudioObject
@synthesize graphSampleRate;
@synthesize playing;
@synthesize fftSetup;			// this is required by fft methods in the callback
@synthesize fftA;
@synthesize fftLog2n;
@synthesize fftN;
@synthesize fftNOver2;		// params for fft setup
@synthesize fftBufferCapacity;	// In samples
@synthesize fftIndex;
@synthesize dataBuffer;			// input buffer from mic
@synthesize outputBuffer;		// for fft conversion
@synthesize analysisBuffer;
@synthesize pitch;
@synthesize frequencyOut;

- (id) init
{
    self = [super init];

    self.graphSampleRate = 44100.0;
    // set up audio session
    CheckError(AudioSessionInitialize(NULL,
                                      kCFRunLoopDefaultMode,
                                      MyInterruptionListener,
                                      (__bridge void*)self),
               "couldn't initialize audio session");
    
	UInt32 category = kAudioSessionCategory_PlayAndRecord;
    CheckError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                                       sizeof(category),
                                       &category),
               "Couldn't set category on audio session");
    
	// is audio input available?
	UInt32 ui32PropertySize = sizeof (UInt32);
	UInt32 inputAvailable;
	CheckError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable,
                                       &ui32PropertySize,
                                       &inputAvailable),
			   "Couldn't get current audio input available prop");
	if (! inputAvailable) {
		UIAlertView *noInputAlert =
		[[UIAlertView alloc] initWithTitle:@"No audio input"
								   message:@"No audio input device is currently attached"
								  delegate:nil
						 cancelButtonTitle:@"OK"
						 otherButtonTitles:nil];
		[noInputAlert show];
        
       

    }
    
    return self;
}

//************************************************************
//*** Generic error handler ***
//************************************************************
static void CheckError(OSStatus error, const char *operation)
{
	if (error == noErr) return;
	
	char str[20];
	// see if it appears to be a 4-char-code
	*(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
		str[0] = str[5] = '\'';
		str[6] = '\0';
	} else
		// no, format it as an integer
		sprintf(str, "%d", (int)error);
	
	fprintf(stderr, "Error: %s (%s)\n", operation, str);
	
	exit(1);
}

//************************************************************
//*** Call when audio streams gets interrupted ***
//************************************************************
static void MyInterruptionListener (void *inUserData,
                                    UInt32 inInterruptionState) {
	
	printf ("Interrupted! inInterruptionState=%ld\n", inInterruptionState);
	PRPaudioObject *appDelegate = (__bridge PRPaudioObject*)inUserData;
	switch (inInterruptionState) {
		case kAudioSessionBeginInterruption:
			break;
		case kAudioSessionEndInterruption:
			[appDelegate initializeAUGraph];
            [appDelegate startAUGraph];
            
			break;
		default:
			break;
	};
}

-(void) playRecordedFile{

    [self readAudioFilesIntoMemory];

}

//************************************************************
//*** ASBD setups ***
//************************************************************
- (void) setupMonoStream864 {
    
    // The AudioUnitSampleType data type is the recommended type for sample data in audio
    //    units. This obtains the byte size of the type for use in filling in the ASBD.
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    
    // Fill the application audio format struct's fields to define a linear PCM,
    //        stereo, noninterleaved stream at the hardware sample rate.
    monoStreamFormat864.mFormatID          = kAudioFormatLinearPCM;
    monoStreamFormat864.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    monoStreamFormat864.mBytesPerPacket    = bytesPerSample;
    monoStreamFormat864.mFramesPerPacket   = 1;
    monoStreamFormat864.mBytesPerFrame     = bytesPerSample;
    monoStreamFormat864.mChannelsPerFrame  = 1;                  // 1 indicates mono
    monoStreamFormat864.mBitsPerChannel    = 8 * bytesPerSample;
    monoStreamFormat864.mSampleRate        = graphSampleRate;

    /*
    audioFormat.mFormatFlags=kAudioFormatFlagsNativeEndian|kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked;
*/
    
    
}

- (void) setupMonoStreamSINT16 {
    
    size_t bytesPerSample = sizeof (AudioSampleType);	// Sint16
    //    NSLog (@"size of AudioSampleType: %lu", bytesPerSample);
	
    // Fill the application audio format struct's fields to define a linear PCM,
    //        stereo, noninterleaved stream at the hardware sample rate.
    monoStreamFormatSINT16.mFormatID          = kAudioFormatLinearPCM;
    monoStreamFormatSINT16.mFormatFlags       = kAudioFormatFlagsCanonical;
    monoStreamFormatSINT16.mBytesPerPacket    = bytesPerSample;
    monoStreamFormatSINT16.mFramesPerPacket   = 1;
    monoStreamFormatSINT16.mBytesPerFrame     = bytesPerSample;
    monoStreamFormatSINT16.mChannelsPerFrame  = 1;                  // 1 indicates mono
    monoStreamFormatSINT16.mBitsPerChannel    = 8 * bytesPerSample;
    monoStreamFormatSINT16.mSampleRate        = graphSampleRate;

    
    
}

- (void) setupStereoStream864 {
    
    // The AudioUnitSampleType data type is the recommended type for sample data in audio
    //    units. This obtains the byte size of the type for use in filling in the ASBD.
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    //     NSLog (@"size of AudioUnitSampleType: %lu", bytesPerSample);
    
    // Fill the application audio format struct's fields to define a linear PCM,
    //        stereo, noninterleaved stream at the hardware sample rate.
    stereoStreamFormat864.mFormatID          = kAudioFormatLinearPCM;
    stereoStreamFormat864.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    stereoStreamFormat864.mBytesPerPacket    = bytesPerSample;
    stereoStreamFormat864.mFramesPerPacket   = 1;
    stereoStreamFormat864.mBytesPerFrame     = bytesPerSample;
    stereoStreamFormat864.mChannelsPerFrame  = 2;                    // 2 indicates stereo
    stereoStreamFormat864.mBitsPerChannel    = 8 * bytesPerSample;
    stereoStreamFormat864.mSampleRate        = graphSampleRate;
}

//************************************************************
//*** Function setups and audio start ***
//************************************************************
- (void)startAudio {
    [self setupMonoStream864];
    [self setupMonoStreamSINT16];
    [self readAudioFilesIntoMemory];
    [self FFTSetup];
    [self initializeAUGraph];
    [self startAUGraph];
    
    NSNumber *zero = [NSNumber numberWithInt:0];
    NSNumber *one = [NSNumber numberWithInt:1];
    NSNumber *two = [NSNumber numberWithInt:2];
    NSNumber *three = [NSNumber numberWithInt:3];
    NSNumber *four = [NSNumber numberWithInt:4];
    NSNumber *five = [NSNumber numberWithInt:5];
    NSNumber *six = [NSNumber numberWithInt:6];
    
    
    NSNumber *floatZero = [NSNumber numberWithFloat:0.0];
    NSNumber *floatOne = [NSNumber numberWithFloat:1.0];
    NSNumber *floatHalf = [NSNumber numberWithFloat:0.5];
    NSNumber *floatten = [NSNumber numberWithFloat:10.0];
    NSNumber *floatthousand = [NSNumber numberWithFloat:20000.0];
    
    /*
    [self volumeControls:zero :floatHalf];
    [self volumeControls:one :floatHalf];
    */
    
    [self reverbControls:zero :floatZero];
    [self reverbControls:one :floatOne];
    [self reverbControls:two :floatOne];
    [self reverbControls:three :floatZero];
    [self reverbControls:four :floatZero];
    [self reverbControls:five :floatZero];
    [self reverbControls:six :floatZero];
    
    [self filterControls:zero :floatthousand];
    [self filterControls:one :floatZero];
    [self filterControls:two :floatten];
    [self filterControls:three :floatZero];
    
    [self varispeedControls:zero :floatOne];
    [self varispeedControls:one :floatOne];
    
    self.playing = YES;
    
    
}

- (void)stopAudio {
    [self stopAUGraph];
    self.playing = NO;
}

//************************************************************
//*** Pitch shift setup ***
//************************************************************

//FFT setup taken from Tom Zicarelli's audioGraph
//http://zerokidz.com/audiograph/Home.html
- (void) FFTSetup {
	
	// I'm going to just convert everything to 1024
	
	
	// on the simulator the callback gets 512 frames even if you set the buffer to 1024, so this is a temp workaround in our efforts
	// to make the fft buffer = the callback buffer,
	
	
	// for smb it doesn't matter if frame size is bigger than callback buffer
	
	UInt32 maxFrames = 1024;    // fft size
	
	
	// setup input and output buffers to equal max frame size
	
	dataBuffer = (void*)malloc(maxFrames * sizeof(SInt16));
	outputBuffer = (float*)malloc(maxFrames *sizeof(float));
	analysisBuffer = (float*)malloc(maxFrames *sizeof(float));
	
	// set the init stuff for fft based on number of frames
	
	fftLog2n = log2f(maxFrames);		// log base2 of max number of frames, eg., 10 for 1024
	fftN = 1 << fftLog2n;					// actual max number of frames, eg., 1024 - what a silly way to compute it
    
    
	fftNOver2 = maxFrames/2;                // half fft size
	fftBufferCapacity = maxFrames;          // yet another way of expressing fft size
	fftIndex = 0;                           // index for reading frame data in callback
	
	// split complex number buffer
	fftA.realp = (float *)malloc(fftNOver2 * sizeof(float));		//
	fftA.imagp = (float *)malloc(fftNOver2 * sizeof(float));		//
	
	
	// zero return indicates an error setting up internal buffers
	
	fftSetup = vDSP_create_fftsetup(fftLog2n, FFT_RADIX2);
    if( fftSetup == (FFTSetup) 0) {
        NSLog(@"Error - unable to allocate FFT setup buffers" );
	}
	
}

//pitch shifter using stft - based on dsp dimension articles and source
// http://www.dspdimension.com/admin/pitch-shifting-using-the-ft/
OSStatus fftPitchShift (
                        void *inRefCon,                // scope (MixerHostAudio)
                        UInt32 inNumberFrames,        // number of frames in this slice
                        SInt16 *sampleBuffer) {      // frames (sample data)
    
    // scope reference that allows access to everything in MixerHostAudio class
    
	PRPaudioObject *THIS = (__bridge PRPaudioObject *)inRefCon;
    
    
  	float *outputBuffer1 = THIS.outputBuffer;        // sample buffers
	float *analysisBuffer1 = THIS.analysisBuffer;
    
    
	
	FFTSetup fftSetup1 = THIS.fftSetup;      // fft setup structures need to support vdsp functions
	
    
	uint32_t stride = 1;                    // interleaving factor for vdsp functions
	int bufferCapacity = THIS.fftBufferCapacity;    // maximum size of fft buffers
    
    float pitchShift = 1.0;                 // pitch shift factor 1=normal, range is .5->2.0
    long osamp = 8;                         // oversampling factor
    long fftSize = 1024;                    // fft size
    
	
	float frequency;                        // analysis frequency result
    
    
    //	ConvertInt16ToFloat
    
    vDSP_vflt16((SInt16 *) sampleBuffer, stride, (float *) analysisBuffer1, stride, bufferCapacity );
    
    // run the pitch shift
    
    // scale the fx control 0->1 to range of pitchShift .5->2.0
    
    pitchShift = (THIS.pitch * 1.5) + .5;
    
    // osamp should be at least 4, but at this time my ipod touch gets very unhappy with
    // anything greater than 2
    
    osamp = 4;
    fftSize = 1024;		// this seems to work in real time since we are actually doing the fft on smaller windows
    
    smb2PitchShift( pitchShift , (long) inNumberFrames,
                   fftSize,  osamp, (float) THIS.graphSampleRate,
                   (float *) analysisBuffer1, (float *) outputBuffer1,
                   fftSetup1, &frequency);
    
    
    // display detected pitch
    
    
    //THIS.displayInputFrequency = (int) frequency;
    
    THIS.frequencyOut = (int) frequency;
    
    // very very cool effect but lets skip it temporarily
    //    THIS.sinFreq = THIS.frequency;   // set synth frequency to the pitch detected by microphone
    
    
    
    // now convert from float to Sint16
    
    vDSP_vfixr16((float *) outputBuffer1, stride, (SInt16 *) sampleBuffer, stride, bufferCapacity );
    
    
    
    return noErr;
    
    
}


//************************************************************
//*** Callback setups ***
//************************************************************
OSStatus micLineInRenderCallback (
                                        void *							inRefCon,
                                        AudioUnitRenderActionFlags *	ioActionFlags,
                                        const AudioTimeStamp *			inTimeStamp,
                                        UInt32							inBusNumber,
                                        UInt32							inNumberFrames,
                                        AudioBufferList *				ioData) {
	
    
    PRPaudioObject *effectState = (__bridge PRPaudioObject*) inRefCon;
    
    OSStatus renderErr;

    
	// Get samples from RIO input bus 1 i.e. the microphone
	UInt32 bus1 = 1;
	renderErr = AudioUnitRender(effectState->mRIO,
                                ioActionFlags,
								inTimeStamp,
                                bus1,
                                inNumberFrames,
                                ioData);
	

    if (renderErr < 0) {
		return renderErr;
	}

    
    
    //SInt16* samples = (SInt16*)(ioData->mBuffers[0].mData); 
    
    //inSamplesLeft = (AudioUnitSampleType *)(ioData->mBuffers[0].mData);
    
    
    
    renderErr = fftPitchShift(inRefCon, inNumberFrames, (SInt16*)(ioData->mBuffers[0].mData));
    

    return noErr;
}

OSStatus connectingRenderCallback(void *inRefCon,
                            AudioUnitRenderActionFlags *actionFlags,
                            const AudioTimeStamp *inTimeStamp,
                            UInt32 inBusNumber,
                            UInt32 inNumberFrames,
                            AudioBufferList *ioData) {
    PRPaudioObject* THIS = (__bridge PRPaudioObject *)inRefCon;

    
    
    OSStatus result;
    
    result = AudioUnitRender(THIS->mDynamic,
                             actionFlags,
                             inTimeStamp,
                             0,
                             inNumberFrames,
                             ioData);
    
    
    if (*actionFlags == kAudioUnitRenderAction_PostRender){
        
        CheckError(ExtAudioFileWriteAsync(THIS->extAudioFile, inNumberFrames, ioData),
                   ("extaudiofilewrite fail"))
                   ;
        
    }
    

    return noErr;

}

static OSStatus fileRenderCallback (
                                     
                                     void                        *inRefCon, 
                                     AudioUnitRenderActionFlags  *ioActionFlags,
                                     const AudioTimeStamp        *inTimeStamp,
                                     UInt32                      inBusNumber,
                                     UInt32                      inNumberFrames,
                                     AudioBufferList             *ioData
                                     ) {
    
    
    
    //soundStructPtr    soundStructPointerArray   = (soundStructPtr) inRefCon;
    PRPaudioObject* THIS = (__bridge PRPaudioObject *)inRefCon;
    //UInt32            frameTotalForSound        = soundStructPointerArray[1].frameCount;
    //BOOL              isStereo                  = soundStructPointerArray[1].isStereo;
    
    
    //BOOL test = NO;

    //if (THIS->soundStructArray[1].fileReady == YES) {
        
    UInt32            frameTotalForSound        = THIS->soundStructArray[1].frameCount;
    BOOL              isStereo                  = NO;//THIS->soundStructArray[1].isStereo;

    
    // Declare variables to point to the audio buffers. Their data type must match the buffer data type.
    AudioUnitSampleType *dataInLeft;
    AudioUnitSampleType *dataInRight;
    
    dataInLeft                 = THIS->soundStructArray[1].audioDataLeft;
    if (isStereo) dataInRight  = THIS->soundStructArray[1].audioDataRight;
    
    // Establish pointers to the memory into which the audio from the buffers should go. This reflects
    //    the fact that each Multichannel Mixer unit input bus has two channels, as specified by this app's
    //    graphStreamFormat variable.
    AudioUnitSampleType *outSamplesChannelLeft;
    AudioUnitSampleType *outSamplesChannelRight;
    
    outSamplesChannelLeft                 = (AudioUnitSampleType *) ioData->mBuffers[0].mData;
    if (isStereo) outSamplesChannelRight  = (AudioUnitSampleType *) ioData->mBuffers[1].mData;
    
    // Get the sample number, as an index into the sound stored in memory,
    //    to start reading data from.
    UInt32 sampleNumber = THIS->soundStructArray[1].sampleNumber;
        
    // Fill the buffer or buffers pointed at by *ioData with the requested number of samples
    //    of audio from the sound stored in memory.
    for (UInt32 frameNumber = 0; frameNumber < inNumberFrames; ++frameNumber) {
        
        outSamplesChannelLeft[frameNumber]             = dataInLeft[sampleNumber];
        
        if (isStereo) outSamplesChannelRight[frameNumber]  = dataInRight[sampleNumber];
        
        sampleNumber++;
        
        // After reaching the end of the sound stored in memory--that is, after
        //    (frameTotalForSound / inNumberFrames) invocations of this callback--loop back to the
        //    start of the sound so playback resumes from there.
        if (sampleNumber >= frameTotalForSound) sampleNumber = 0;
    }
    
    // Update the stored sample number so, the next time this callback is invoked, playback resumes 
    //    at the correct spot.
    THIS->soundStructArray[1].sampleNumber = sampleNumber;
    
    
    
    
    return noErr;
    //}

}

//************************************************************
//*** Audio unit controls ***
//************************************************************
- (void) reverbControls: (NSNumber *) value :(NSNumber *) value2{
    
    switch ([value intValue])
    {
        {case 0:
            Float32 dryWetMix = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mReverb,
                                             kReverb2Param_DryWetMix,
                                             kAudioUnitScope_Global,
                                             0,
                                             dryWetMix,
                                             0),
                       "Coulnd't set kReverb2Param_DryWetMix ");
            break;}
        {case 1:
            Float32 decayTime = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mReverb,
                                             kReverb2Param_DecayTimeAt0Hz,
                                             kAudioUnitScope_Global,
                                             0,
                                             decayTime,
                                             0),
                       "Coulnd't set decaytime ");
            
            break;}
        {case 2:
            Float32 decayTimeNyquist = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mReverb,
                                             kReverb2Param_DecayTimeAtNyquist,
                                             kAudioUnitScope_Global,
                                             0,
                                             decayTimeNyquist,
                                             0),
                       "Coulnd't set decayTimeNyquist ");
            break;}
        {case 3:
            Float32 gain = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mReverb,
                                             kReverb2Param_Gain,
                                             kAudioUnitScope_Global,
                                             0,
                                             gain,
                                             0),
                       "Coulnd't set gain ");
            break;}
        {case 4:
            Float32 maxDelayTime = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mReverb,
                                             kReverb2Param_MaxDelayTime,
                                             kAudioUnitScope_Global,
                                             0,
                                             maxDelayTime,
                                             0),
                       "Coulnd't set maxdelaytime ");
            break;}
        {case 5:
            Float32 minDelayTime = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mReverb,
                                             kReverb2Param_MinDelayTime,
                                             kAudioUnitScope_Global,
                                             0,
                                             minDelayTime,
                                             0),
                       "Coulnd't set minDelayTime ");
            break;}
        {case 6:
            Float32 randomizeReflections = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mReverb,
                                             kReverb2Param_RandomizeReflections,
                                             kAudioUnitScope_Global,
                                             0,
                                             randomizeReflections,
                                             0),
                       "Coulnd't set randomizeReflections ");
            break;}
        default:
            NSLog (@"Reverb Integer out of range");
            break;
    }
    
}

- (void) filterControls: (NSNumber *) value:(NSNumber *) value2{
    
    switch ([value intValue])
    {
        {case 0:
            Float32 lowpassCutoffFrequency = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mLowPass,
                                             kLowPassParam_CutoffFrequency,
                                             kAudioUnitScope_Global,
                                             0,
                                             lowpassCutoffFrequency,
                                             0),
                       "Coulnd't set cutoffFrequency");
            break;}
        {case 1:
            Float32 lowpassResonance = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mLowPass,
                                             kLowPassParam_Resonance,
                                             kAudioUnitScope_Global,
                                             0,
                                             lowpassResonance,
                                             0),
                       "Coulnd't set resonance");
            
            break;}
        {case 2:
            Float32 highpassCutoffFrequency = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mhighPass,
                                             kHipassParam_CutoffFrequency,
                                             kAudioUnitScope_Global,
                                             0,
                                             highpassCutoffFrequency,
                                             0),
                       "Coulnd't set highpassCutoffFrequency");
            
            break;}
        {case 3:
            Float32 highpassResonance = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mhighPass,
                                             kHipassParam_Resonance,
                                             kAudioUnitScope_Global,
                                             0,
                                             highpassResonance,
                                             0),
                       "Coulnd't set highpassResonance");
            
            break;}
        default:
            NSLog (@"Filter Integer out of range");
            break;
    }

}

- (void) distortionControls: (NSNumber *) value{
    
    Float32 distGain = [value floatValue];
	CheckError(AudioUnitSetParameter(mdistortion,
									 kDistortionParam_SoftClipGain,
									 kAudioUnitScope_Global,
									 0,
									 distGain,
									 0),
			   "Coulnd't set kLowPassParam_CutoffFrequency");
}

- (void) varispeedControls: (NSNumber *) value:(NSNumber *) value2{
    
            Float32 varispeedRate = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mVarispeed,
                                             kVarispeedParam_PlaybackRate,
                                             kAudioUnitScope_Global,
                                             0,
                                             varispeedRate,
                                             0),
                       "Coulnd't set kLowPassParam_CutoffFrequency");

    
}

- (void) dynamicControls: (NSNumber *) value:(NSNumber *) value2{
        
    switch ([value intValue])
    {
        {case 0:
            Float32 attack = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mDynamic,
                                             kDynamicsProcessorParam_AttackTime,
                                             kAudioUnitScope_Global,
                                             0,
                                             attack,
                                             0),
                       "Coulnd't set attack");
            break;}
        {case 1:
            Float32 release = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mDynamic,
                                             kDynamicsProcessorParam_ReleaseTime,
                                             kAudioUnitScope_Global,
                                             0,
                                             release,
                                             0),
                       "Coulnd't set release");
            break;}
        {case 2:
            Float32 threshold = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mDynamic,
                                             kDynamicsProcessorParam_Threshold,
                                             kAudioUnitScope_Global,
                                             0,
                                             threshold,
                                             0),
                       "Coulnd't set threshold");
            break;}
        {case 3:
            Float32 gain = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mDynamic,
                                             kDynamicsProcessorParam_MasterGain,
                                             kAudioUnitScope_Global,
                                             0,
                                             gain,
                                             0),
                       "Coulnd't set master gain");
            break;}
        {case 4:
            Float32 expanRatio = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mDynamic,
                                             kDynamicsProcessorParam_ExpansionRatio,
                                             kAudioUnitScope_Global,
                                             0,
                                             expanRatio,
                                             0),
                       "Coulnd't set master gain");
            break;}
        {case 5:
            Float32 expanThresh = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mDynamic,
                                             kDynamicsProcessorParam_ExpansionThreshold,
                                             kAudioUnitScope_Global,
                                             0,
                                             expanThresh,
                                             0),
                       "Coulnd't set master gain");
            break;}
        {case 6:
            Float32 headroom = [value2 floatValue];
            CheckError(AudioUnitSetParameter(mDynamic,
                                             kDynamicsProcessorParam_HeadRoom,
                                             kAudioUnitScope_Global,
                                             0,
                                             headroom,
                                             0),
                       "Coulnd't set master gain");
            break;}
            
        default:
            NSLog (@"Integer out of range");
            break;
    }
    
    
}

- (void) volumeControls: (NSNumber *) value :(NSNumber *) value2{
    
        UInt32 inputNum = [value intValue];
        AudioUnitParameterValue parameterValue = [value2 floatValue];
        
        OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, inputNum, parameterValue, 0);
        if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Volume Input result %ld %08ld %4.4s\n", result, result, (char*)&result); return; }
    
}

- (void) panControls: (NSNumber *) value :(NSNumber *) value2{
    
    UInt32 inputNum = [value intValue];
    AudioUnitParameterValue parameterValue = [value2 floatValue];
    
    OSStatus result = AudioUnitSetParameter(mMixer, kMultiChannelMixerParam_Pan, kAudioUnitScope_Input, inputNum, parameterValue, 0);
    if (result) { printf("AudioUnitSetParameter kMultiChannelMixerParam_Volume Input result %ld %08ld %4.4s\n", result, result, (char*)&result); return; }
}


//************************************************************
//*** Post fader volume outputs of mixer ***
//************************************************************
- (Float32)inputVolume0{
    
    Float32 inputVolume = 0.0;
    CheckError(AudioUnitGetParameter(mMixer,
                                     kMultiChannelMixerParam_PostAveragePower,
                                     kAudioUnitScope_Input,
                                     0,
                                     &inputVolume),
               "Error");
    
    return inputVolume;
    
}
- (Float32)inputVolume1{
    
    Float32 inputVolume1 = 0.0;
    CheckError(AudioUnitGetParameter(mMixer,
                                     kMultiChannelMixerParam_PostAveragePower,
                                     kAudioUnitScope_Input,
                                     1,
                                     &inputVolume1),
               "Error");
    
    return inputVolume1;
}
- (Float32)inputVolume2{
    
    Float32 inputVolume2 = 0.0;
    CheckError(AudioUnitGetParameter(mMixer,
                                     kMultiChannelMixerParam_PostAveragePower,
                                     kAudioUnitScope_Input,
                                     2,
                                     &inputVolume2),
               "Error");
    
    return inputVolume2;
}

/*
-(void)printAudio{
    
    UInt32            frameTotalForSound        = soundStructArray[1].frameCount;


    for(int i = 0; i < 10000; i++) {
        samplesAsFloats[i] = buf[i] / 32768.0f;
        sampleBuffer[i+pAqData->currentPacket] = buf[i] / 32768.0f;
        decibelBuffer[i+pAqData->currentPacket] = buf[i];
        
    }
}
*/

//************************************************************
//*** Stop and stop functions for audio graph ***
//************************************************************
// starts render
- (void)startAUGraph
{
	// Start the AUGraph
	OSStatus result = AUGraphStart(mGraph);
	// Print the result
	if (result) { printf("AUGraphStart result %d %08X %4.4s\n", (int)result, (int)result, (char*)&result); return; }
}

// stops render
- (void)stopAUGraph
{
    Boolean isRunning = false;
    
    // Check to see if the graph is running.
    OSStatus result = AUGraphIsRunning(mGraph, &isRunning);
    // If the graph is running, stop it.
    if (isRunning) {
        result = AUGraphStop(mGraph);
    }
}

//audio unit stop
- (void)stopAU
{
    
    
    // Check to see if the graph is running.
    CheckError(AudioUnitUninitialize(mFilePlayer),
               "audio unit uninit fail");

}

//************************************************************
//*** AUGraph setup ***
//************************************************************
- (void)initializeAUGraph
{
	//************************************************************
	//*** Setup the AUGraph, add AUNodes, and make connections ***
	//************************************************************
	// Error checking result
	OSStatus result = noErr;
    
	// create a new AUGraph
	result = NewAUGraph(&mGraph);
    
    // AUNodes represent AudioUnits on the AUGraph and provide an
	// easy means for connecting audioUnits together.
    AUNode filePlayerNode;
    AUNode filePlayerNode2;
    AUNode outputNode;
    AUNode reverbNode;
    AUNode lowPassNode;
    AUNode highPassNode;
	AUNode mixerNode;
    AUNode dynamicNode;
    AUNode varispeedNode;
    
    // file player component
    AudioComponentDescription filePlayer_desc;
	filePlayer_desc.componentType = kAudioUnitType_Generator;
	filePlayer_desc.componentSubType = kAudioUnitSubType_AudioFilePlayer;
	filePlayer_desc.componentFlags = 0;
	filePlayer_desc.componentFlagsMask = 0;
	filePlayer_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // file player component2
    AudioComponentDescription filePlayer2_desc;
	filePlayer2_desc.componentType = kAudioUnitType_Generator;
	filePlayer2_desc.componentSubType = kAudioUnitSubType_AudioFilePlayer;
	filePlayer2_desc.componentFlags = 0;
	filePlayer2_desc.componentFlagsMask = 0;
	filePlayer2_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Create AudioComponentDescriptions for the AUs we want in the graph
    // mixer component
	AudioComponentDescription mixer_desc;
	mixer_desc.componentType = kAudioUnitType_Mixer;
	mixer_desc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
	mixer_desc.componentFlags = 0;
	mixer_desc.componentFlagsMask = 0;
	mixer_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Create AudioComponentDescriptions for the AUs we want in the graph
    // Reverb component
	AudioComponentDescription reverb_desc;
	reverb_desc.componentType = kAudioUnitType_Effect;
	reverb_desc.componentSubType = kAudioUnitSubType_Reverb2;
	reverb_desc.componentFlags = 0;
	reverb_desc.componentFlagsMask = 0;
	reverb_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Create AudioComponentDescriptions for the AUs we want in the graph
    // lowPass component
	AudioComponentDescription lowPass_desc;
	lowPass_desc.componentType = kAudioUnitType_Effect;
	lowPass_desc.componentSubType = kAudioUnitSubType_LowPassFilter;
	lowPass_desc.componentFlags = 0;
	lowPass_desc.componentFlagsMask = 0;
	lowPass_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Create AudioComponentDescriptions for the AUs we want in the graph
    // highPass component
	AudioComponentDescription highPass_desc;
	highPass_desc.componentType = kAudioUnitType_Effect;
	highPass_desc.componentSubType = kAudioUnitSubType_HighPassFilter;
	highPass_desc.componentFlags = 0;
	highPass_desc.componentFlagsMask = 0;
	highPass_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Create AudioComponentDescriptions for the AUs we want in the graph
    // varispeed component
	AudioComponentDescription varispeed_desc;
	varispeed_desc.componentType = kAudioUnitType_FormatConverter;
	varispeed_desc.componentSubType = kAudioUnitSubType_Varispeed;
	varispeed_desc.componentFlags = 0;
	varispeed_desc.componentFlagsMask = 0;
	varispeed_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Create AudioComponentDescriptions for the AUs we want in the graph
    // varispeed component
	AudioComponentDescription dynamic_desc;
	dynamic_desc.componentType = kAudioUnitType_Effect;
	dynamic_desc.componentSubType = kAudioUnitSubType_DynamicsProcessor;
	dynamic_desc.componentFlags = 0;
	dynamic_desc.componentFlagsMask = 0;
	dynamic_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
	//  output component
	AudioComponentDescription output_desc;
	output_desc.componentType = kAudioUnitType_Output;
	output_desc.componentSubType = kAudioUnitSubType_RemoteIO;
	output_desc.componentFlags = 0;
	output_desc.componentFlagsMask = 0;
	output_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    //************************************************************
	//*** Add nodes to graph ***
	//************************************************************
    
    // Add nodes to the graph to hold our AudioUnits,
	// You pass in a reference to the  AudioComponentDescription
	// and get back an  AudioUnit
    result = AUGraphAddNode(mGraph, &filePlayer_desc, &filePlayerNode );
    result = AUGraphAddNode(mGraph, &filePlayer2_desc, &filePlayerNode2 );
    result = AUGraphAddNode(mGraph, &mixer_desc, &mixerNode );
    result = AUGraphAddNode(mGraph, &reverb_desc, &reverbNode );
    result = AUGraphAddNode(mGraph, &varispeed_desc, &varispeedNode );
    
    result = AUGraphAddNode(mGraph, &lowPass_desc, &lowPassNode );
    result = AUGraphAddNode(mGraph, &highPass_desc, &highPassNode );
    result = AUGraphAddNode(mGraph, &dynamic_desc, &dynamicNode );
    
	result = AUGraphAddNode(mGraph, &output_desc, &outputNode);
    
    //************************************************************
	//*** Open the graph early, initialize late ***
	//************************************************************
    
    // open the graph AudioUnits are open but not initialized (no resource allocation occurs here)
	result = AUGraphOpen(mGraph);
    
    //************************************************************
	//*** Reference to Nodes ***
	//************************************************************
    
    // get the reference to the AudioUnit object for the file player graph node
	result = AUGraphNodeInfo(mGraph, filePlayerNode, NULL, &mFilePlayer);
	result = AUGraphNodeInfo(mGraph, filePlayerNode2, NULL, &mFilePlayer2);
    result = AUGraphNodeInfo(mGraph, reverbNode, NULL, &mReverb);
    result = AUGraphNodeInfo(mGraph, lowPassNode, NULL, &mLowPass);
    result = AUGraphNodeInfo(mGraph, highPassNode, NULL, &mhighPass);
    result = AUGraphNodeInfo(mGraph, mixerNode, NULL, &mMixer);
    result = AUGraphNodeInfo(mGraph, varispeedNode, NULL, &mVarispeed);
    result = AUGraphNodeInfo(mGraph, dynamicNode, NULL, &mDynamic);
    result = AUGraphNodeInfo(mGraph, outputNode, NULL, &mRIO);
    
    
    /*
     AudioComponent rioComponent = AudioComponentFindNext(NULL, &output_desc);
     CheckError(AudioComponentInstanceNew(rioComponent, &mRIO),
     "Couldn't get RIO unit instance");
     */
    
    //************************************************************
	//*** Manage signal chain ***
	//************************************************************
    
    result = AUGraphConnectNodeInput(mGraph, filePlayerNode, 0, mixerNode, 0);
    result = AUGraphConnectNodeInput(mGraph, filePlayerNode2, 0, mixerNode, 1);

    result = AUGraphConnectNodeInput(mGraph, mixerNode, 0, reverbNode, 0);
    result = AUGraphConnectNodeInput(mGraph, reverbNode, 0, varispeedNode, 0);
    result = AUGraphConnectNodeInput(mGraph, varispeedNode, 0, lowPassNode, 0);
    result = AUGraphConnectNodeInput(mGraph, lowPassNode, 0, highPassNode, 0);
    result = AUGraphConnectNodeInput(mGraph, highPassNode, 0, dynamicNode, 0);
    
    //result = AUGraphConnectNodeInput(mGraph, dynamicNode, 0, outputNode, 0);
     
    //************************************************************
	//*** render callback connection between varispeed output and remote io input ***
	//************************************************************
    
    AURenderCallbackStruct callbackStruct = {0};
    callbackStruct.inputProc = connectingRenderCallback;
    callbackStruct.inputProcRefCon = (__bridge void*)self;
    
    
    AudioUnitSetProperty(mRIO,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Input,
                         0,
                         &callbackStruct,
                         sizeof(callbackStruct));
    //************************************************************
	//*** Configure RIO to enable input ***
	//************************************************************
    
    
    UInt32 enableInput = 1;
	AudioUnitElement ioUnitInputBus = 1;
    
    CheckError(AudioUnitSetProperty (
                                     mRIO,
                                     kAudioOutputUnitProperty_EnableIO,
                                     kAudioUnitScope_Input,
                                     ioUnitInputBus,
                                     &enableInput,
                                     sizeof (enableInput)
                                     ),
               "Couldn't enable RIO input");
    
    //************************************************************
	//*** Set RIO input bus's output to mono ***
	//************************************************************
    
    CheckError(AudioUnitSetProperty (
                                     mRIO,
                                     kAudioUnitProperty_StreamFormat,
                                     kAudioUnitScope_Output,
                                     ioUnitInputBus,
                                     &monoStreamFormatSINT16,
                                     sizeof (monoStreamFormatSINT16)
                                     ),
               "Couldn't set RIO unit to mono");
    
    
    
    
    //************************************************************
	//*** Setup mixer inputs ***
	//************************************************************
    
    UInt32 busCount   = 4;    // bus count for mixer unit input
    
    //Setup mixer unit bus count
    CheckError(AudioUnitSetProperty (
                                     mMixer,
                                     kAudioUnitProperty_ElementCount,
                                     kAudioUnitScope_Input,
                                     0,
                                     &busCount,
                                     sizeof (busCount)
                                     ),
               "Couldn't set mixer unit's bus count");
    
    //Enable metering mode to view levels input and output levels of mixer
    UInt32 onValue = 1;
    CheckError(AudioUnitSetProperty(mMixer,
                                    kAudioUnitProperty_MeteringMode,
                                    kAudioUnitScope_Input,
                                    0,
                                    &onValue,
                                    sizeof(onValue)),
               "error");
    
    // Increase the maximum frames per slice allows the mixer unit to accommodate the
    //    larger slice size used when the screen is locked.
    UInt32 maximumFramesPerSlice = 4096;
    
    CheckError(AudioUnitSetProperty (
                                     mMixer,
                                     kAudioUnitProperty_MaximumFramesPerSlice,
                                     kAudioUnitScope_Global,
                                     0,
                                     &maximumFramesPerSlice,
                                     sizeof (maximumFramesPerSlice)
                                     ),
               "Couldn't set mixer units maximum framers per slice");
    
    //************************************************************
	//*** Render callback for mic input into channel 2 of mixer ***
	//************************************************************
    
    
    
    //Set mixer units input 2 asbd to remote input's output asbd
    result = AudioUnitSetProperty (
								   mMixer,
								   kAudioUnitProperty_StreamFormat,
								   kAudioUnitScope_Input,
								   2,
								   &monoStreamFormatSINT16,
								   sizeof (monoStreamFormatSINT16)
								   );
    
    
    UInt16 busNumber = 2;		// mic channel on mixer
	
    // Setup the structure that contains the input render callback
    AURenderCallbackStruct inputCallbackStruct;
    inputCallbackStruct.inputProc        = micLineInRenderCallback;	// 8.24 version
    inputCallbackStruct.inputProcRefCon  = (__bridge void*)self;
	
	
    //NSLog (@"Registering the render callback - mic/lineIn - with mixer unit input bus %u", busNumber);
    // Set a callback for the specified node's specified input
    result = AUGraphSetNodeInputCallback (
										  mGraph,
										  mixerNode,
										  busNumber,
										  &inputCallbackStruct
										  );
    

    
    //************************************************************
	//*** Render callback for file input into channel 3 of mixer ***
	//************************************************************
    
    
    /*
    //Set mixer units input 3 asbd to file players output asbd
    result = AudioUnitSetProperty (
								   mMixer,
								   kAudioUnitProperty_StreamFormat,
								   kAudioUnitScope_Input,
								   3,
								   &recordStreamFormat,
								   sizeof (recordStreamFormat)
								   );
    
    UInt16 busNumber3 = 3;		// mic channel on mixer
	
    // Setup the structure that contains the input render callback
    AURenderCallbackStruct input3CallbackStruct;
    input3CallbackStruct.inputProc        = fileRenderCallback;	// 8.24 version
    input3CallbackStruct.inputProcRefCon  = (__bridge void*)self;
	
	
    //NSLog (@"Registering the render callback - mic/lineIn - with mixer unit input bus %u", busNumber);
    // Set a callback for the specified node's specified input
    result = AUGraphSetNodeInputCallback (
										  mGraph,
										  mixerNode,
										  busNumber3,
										  &input3CallbackStruct
										  );
     
     */
    
    //enable input
/*
    //AudioUnitParameterValue isOn = NO;
    CheckError(AudioUnitSetParameter (
                                      mMixer,
                                      kMultiChannelMixerParam_Enable,
                                      kAudioUnitScope_Input,
                                      3,
                                      0,
                                      0
                                      ),
               "enable input fail");
 */    
    
    

    
    //************************************************************
	//*** Get reverbs input asbd and set to mixers output asbd ***
	//************************************************************
    
    AudioStreamBasicDescription     auEffectStreamFormat;
    UInt32 asbdSize = sizeof (auEffectStreamFormat);
	memset (&auEffectStreamFormat, 0, sizeof (auEffectStreamFormat ));
    
	CheckError(AudioUnitGetProperty(mReverb,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &auEffectStreamFormat,
                                    &asbdSize),
			   "Couldn't get aueffectunit ASBD");
    
    auEffectStreamFormat.mSampleRate = graphSampleRate;
    
    
    CheckError(AudioUnitSetProperty(mMixer,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    0,
                                    &auEffectStreamFormat, sizeof(auEffectStreamFormat)),
			   "Couldn't set ASBD on mixer output");
    
    
    //************************************************************
	//*** Get reverbs output asbd and set to varispeeds input asbd ***
	//************************************************************
    
    
    AudioStreamBasicDescription     auEffectStreamFormat1;
    UInt32 asbdSize1 = sizeof (auEffectStreamFormat1);
	memset (&auEffectStreamFormat1, 0, sizeof (auEffectStreamFormat1 ));
    
	CheckError(AudioUnitGetProperty(mReverb,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    0,
                                    &auEffectStreamFormat1,
                                    &asbdSize1),
			   "Couldn't get reverb ASBD");
    
    
    CheckError(AudioUnitSetProperty(mVarispeed,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    0,
                                    &auEffectStreamFormat1, sizeof(auEffectStreamFormat1)),
			   "Couldn't set ASBD on varispeed output");
    
    //************************************************************
	//*** Get dynamics output asbd and set to remote output's input asbd ***
	//************************************************************
    
    
    AudioStreamBasicDescription     auEffectStreamFormat2;
    UInt32 asbdSize2 = sizeof (auEffectStreamFormat2);
	memset (&auEffectStreamFormat2, 0, sizeof (auEffectStreamFormat2 ));
    
	CheckError(AudioUnitGetProperty(mDynamic,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    0,
                                    &auEffectStreamFormat2,
                                    &asbdSize2),
			   "Couldn't get reverb ASBD");
    
    
    CheckError(AudioUnitSetProperty(mRIO,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &auEffectStreamFormat2, sizeof(auEffectStreamFormat2)),
			   "Couldn't set ASBD on mRIO output");
    
    
    //************************************************************
	//*** Initialize ***
	//************************************************************
    
    
    
    if(result) printf("ExtAudioFileSetProperty %ld \n", result);
    
	result = AUGraphInitialize(mGraph);
    
    [self setUpAUFilePlayer];
    [self setUpAUFilePlayer2];
    
    //CAShow(mGraph);

    
}

//************************************************************
//*** Audio file playback setup ***
//************************************************************
-(OSStatus) setUpAUFilePlayer
{
    
    NSString *songPath = [[NSBundle mainBundle] pathForResource: SONG_TITLE ofType:SONG_FILE_TYPE];
	CFURLRef songURL = (__bridge CFURLRef) [NSURL fileURLWithPath:songPath];
	
	// open the input audio file
	CheckError(AudioFileOpenURL(songURL, kAudioFileReadPermission, 0, &inputFile),
			   "AudioFileOpenURL failed");
    
    AudioStreamBasicDescription fileASBD;
	// get the audio data format from the file
	UInt32 propSize = sizeof(fileASBD);
	CheckError(AudioFileGetProperty(inputFile, kAudioFilePropertyDataFormat,
									&propSize, &fileASBD),
			   "couldn't get file's data format");
    
    // tell the file player unit to load the file we want to play
	CheckError(AudioUnitSetProperty(mFilePlayer, kAudioUnitProperty_ScheduledFileIDs,
									kAudioUnitScope_Global, 0, &inputFile, sizeof(inputFile)),
			   "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFileIDs] failed");
	
	UInt64 nPackets;
	UInt32 propsize = sizeof(nPackets);
	CheckError(AudioFileGetProperty(inputFile, kAudioFilePropertyAudioDataPacketCount,
									&propsize, &nPackets),
			   "AudioFileGetProperty[kAudioFilePropertyAudioDataPacketCount] failed");
	
	// tell the file player AU to play the entire file
	ScheduledAudioFileRegion rgn;
	memset (&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
	rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
	rgn.mTimeStamp.mSampleTime = 0;
	rgn.mCompletionProc = NULL;
	rgn.mCompletionProcUserData = NULL;
	rgn.mAudioFile = inputFile;
	rgn.mLoopCount = -1;
	rgn.mStartFrame = 0;
	rgn.mFramesToPlay = nPackets * fileASBD.mFramesPerPacket;
	
	CheckError(AudioUnitSetProperty(mFilePlayer, kAudioUnitProperty_ScheduledFileRegion,
									kAudioUnitScope_Global, 0,&rgn, sizeof(rgn)),
			   "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFileRegion] failed");
	
	// prime the file player AU with default values
	UInt32 defaultVal = 0;
	CheckError(AudioUnitSetProperty(mFilePlayer, kAudioUnitProperty_ScheduledFilePrime,
									kAudioUnitScope_Global, 0, &defaultVal, sizeof(defaultVal)),
			   "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFilePrime] failed");
	
	// tell the file player AU when to start playing (-1 sample time means next render cycle)
	AudioTimeStamp startTime;
	memset (&startTime, 0, sizeof(startTime));
	startTime.mFlags = kAudioTimeStampSampleTimeValid;
	startTime.mSampleTime = -1;
	CheckError(AudioUnitSetProperty(mFilePlayer, kAudioUnitProperty_ScheduleStartTimeStamp,
									kAudioUnitScope_Global, 0, &startTime, sizeof(startTime)),
			   "AudioUnitSetProperty[kAudioUnitProperty_ScheduleStartTimeStamp]");
    
    return noErr;
    
}

-(OSStatus) setUpAUFilePlayer2
{
    
    NSString *songPath = [[NSBundle mainBundle] pathForResource: SONG_TITLE2 ofType:SONG_FILE_TYPE2];
	CFURLRef songURL = (__bridge CFURLRef) [NSURL fileURLWithPath:songPath];
	
	// open the input audio file
	CheckError(AudioFileOpenURL(songURL, kAudioFileReadPermission, 0, &inputFile2),
			   "AudioFileOpenURL failed");
    
    AudioStreamBasicDescription fileASBD;
	// get the audio data format from the file
	UInt32 propSize = sizeof(fileASBD);
	CheckError(AudioFileGetProperty(inputFile2, kAudioFilePropertyDataFormat,
									&propSize, &fileASBD),
			   "couldn't get file's data format");
    
    // tell the file player unit to load the file we want to play
	CheckError(AudioUnitSetProperty(mFilePlayer2, kAudioUnitProperty_ScheduledFileIDs,
									kAudioUnitScope_Global, 0, &inputFile2, sizeof(inputFile2)),
			   "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFileIDs] failed");
	
	UInt64 nPackets;
	UInt32 propsize = sizeof(nPackets);
	CheckError(AudioFileGetProperty(inputFile2, kAudioFilePropertyAudioDataPacketCount,
									&propsize, &nPackets),
			   "AudioFileGetProperty[kAudioFilePropertyAudioDataPacketCount] failed");
	
	// tell the file player AU to play the entire file
	ScheduledAudioFileRegion rgn;
	memset (&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
	rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
	rgn.mTimeStamp.mSampleTime = 0;
	rgn.mCompletionProc = NULL;
	rgn.mCompletionProcUserData = NULL;
	rgn.mAudioFile = inputFile2;
	rgn.mLoopCount = -1;
	rgn.mStartFrame = 0;
	rgn.mFramesToPlay = nPackets * fileASBD.mFramesPerPacket;
	
	CheckError(AudioUnitSetProperty(mFilePlayer2, kAudioUnitProperty_ScheduledFileRegion,
									kAudioUnitScope_Global, 0,&rgn, sizeof(rgn)),
			   "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFileRegion] failed");
	
	// prime the file player AU with default values
	UInt32 defaultVal = 0;
	CheckError(AudioUnitSetProperty(mFilePlayer2, kAudioUnitProperty_ScheduledFilePrime,
									kAudioUnitScope_Global, 0, &defaultVal, sizeof(defaultVal)),
			   "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFilePrime] failed");
	
	// tell the file player AU when to start playing (-1 sample time means next render cycle)
	AudioTimeStamp startTime;
	memset (&startTime, 0, sizeof(startTime));
	startTime.mFlags = kAudioTimeStampSampleTimeValid;
	startTime.mSampleTime = -1;
	CheckError(AudioUnitSetProperty(mFilePlayer2, kAudioUnitProperty_ScheduleStartTimeStamp,
									kAudioUnitScope_Global, 0, &startTime, sizeof(startTime)),
			   "AudioUnitSetProperty[kAudioUnitProperty_ScheduleStartTimeStamp]");
    
    return noErr;
    
}

- (void) readAudioFilesIntoMemory {
    
    //for (int audioFile = 0; audioFile < NUM_FILES; ++audioFile)  {
    
    //Locate the home directory of the app
    NSString *documentsDirectory = [NSHomeDirectory()
                                    stringByAppendingPathComponent:@"Documents"];
    
    //Create the file name of the sample that is required to play using the variables created
    NSString *fileAtIndex = [documentsDirectory stringByAppendingFormat:@"/output.caf"];
    
    NSLog(@"%@",fileAtIndex);
    
    CFURLRef fileURL =  CFURLCreateFromFileSystemRepresentation (NULL, (const UInt8 *) [fileAtIndex UTF8String], [fileAtIndex length], NO);
    
    
    //NSURL *beatsLoop    = [[NSBundle mainBundle] URLForResource: @"congaloop" withExtension: @"caf"];
    

    /*
    NSString *songPath = [[NSBundle mainBundle] pathForResource: @"beatsMono" ofType: @"caf"];

    CFURLRef songURL = (__bridge CFURLRef) [NSURL fileURLWithPath:songPath];
     */
    
        // Instantiate an extended audio file object.
        ExtAudioFileRef audioFileObject = 0;
        
        // Open an audio file and associate it with the extended audio file object.
        CheckError(ExtAudioFileOpenURL (fileURL, &audioFileObject),
                   ("extaudiofileopenurl fail"));
        
       
        
        // Get the audio file's length in frames.
        UInt64 totalFramesInFile = 0;
        UInt32 frameLengthPropertySize = sizeof (totalFramesInFile);
        
        CheckError(ExtAudioFileGetProperty (
                                             audioFileObject,
                                             kExtAudioFileProperty_FileLengthFrames,
                                             &frameLengthPropertySize,
                                             &totalFramesInFile
                                             ),
                   ("extaudiofilegetproperty fail"));
        
        
        // Assign the frame count to the soundStructArray instance variable
        soundStructArray[1].frameCount = totalFramesInFile;
        
        // Get the audio file's number of channels.
        AudioStreamBasicDescription fileAudioFormat = {0};
        UInt32 formatPropertySize = sizeof (fileAudioFormat);
        
        CheckError(ExtAudioFileGetProperty (
                                             audioFileObject,
                                             kExtAudioFileProperty_FileDataFormat,
                                             &formatPropertySize,
                                             &fileAudioFormat
                                             ),
                   "extaudiofileget property 2 fail");
        
        
    UInt32 channelCount = fileAudioFormat.mChannelsPerFrame;
        
        // Allocate memory in the soundStructArray instance variable to hold the left channel,
        //    or mono, audio data
        soundStructArray[1].audioDataLeft =
        (AudioUnitSampleType *) calloc (totalFramesInFile, sizeof (AudioUnitSampleType));
        
        AudioStreamBasicDescription importFormat = {0};
        if (2 == channelCount) {
            
            NSLog(@"Stereo!");
            soundStructArray[1].isStereo = YES;
            // Sound is stereo, so allocate memory in the soundStructArray instance variable to
            //    hold the right channel audio data
            soundStructArray[1].audioDataRight =
            (AudioUnitSampleType *) calloc (totalFramesInFile, sizeof (AudioUnitSampleType));
            importFormat = stereoStreamFormat864;
            
        } else if (1 == channelCount) {
            
            NSLog(@"Not Stereo!");

            soundStructArray[1].isStereo = NO;
            importFormat = monoStreamFormat864;
            
        } else {
            
            NSLog (@"*** WARNING: File format not supported - wrong number of channels");
            ExtAudioFileDispose (audioFileObject);
            return;
        }
        
        // Assign the appropriate mixer input bus stream data format to the extended audio
        //        file object. This is the format used for the audio data placed into the audio
        //        buffer in the SoundStruct data structure, which is in turn used in the
        //        inputRenderCallback callback function.
        
        CheckError(ExtAudioFileSetProperty (
                                             audioFileObject,
                                             kExtAudioFileProperty_ClientDataFormat,
                                             sizeof (importFormat),
                                             &importFormat
                                             ),
                   "extaudiofilesetproperty fail");
        
        
        // Set up an AudioBufferList struct, which has two roles:
        //
        //        1. It gives the ExtAudioFileRead function the configuration it
        //            needs to correctly provide the data to the buffer.
        //
        //        2. It points to the soundStructArray[audioFile].audioDataLeft buffer, so
        //            that audio data obtained from disk using the ExtAudioFileRead function
        //            goes to that buffer
        
        // Allocate memory for the buffer list struct according to the number of
        //    channels it represents.
        AudioBufferList *bufferList;
        
        bufferList = (AudioBufferList *) malloc (
                                                 sizeof (AudioBufferList) + sizeof (AudioBuffer) * (channelCount - 1)
                                                 );
        
        if (NULL == bufferList) {NSLog (@"*** malloc failure for allocating bufferList memory"); return;}
        
        // initialize the mNumberBuffers member
        bufferList->mNumberBuffers = channelCount;
        
        // initialize the mBuffers member to 0
        AudioBuffer emptyBuffer = {0};
        size_t arrayIndex;
        for (arrayIndex = 0; arrayIndex < channelCount; arrayIndex++) {
            bufferList->mBuffers[arrayIndex] = emptyBuffer;
        }
        
        // set up the AudioBuffer structs in the buffer list
        bufferList->mBuffers[0].mNumberChannels  = 1;
        bufferList->mBuffers[0].mDataByteSize    = totalFramesInFile * sizeof (AudioUnitSampleType);
        bufferList->mBuffers[0].mData            = soundStructArray[1].audioDataLeft;
        
        if (2 == channelCount) {
            bufferList->mBuffers[1].mNumberChannels  = 1;
            bufferList->mBuffers[1].mDataByteSize    = totalFramesInFile * sizeof (AudioUnitSampleType);
            bufferList->mBuffers[1].mData            = soundStructArray[1].audioDataRight;
        }
        
        // Perform a synchronous, sequential read of the audio data out of the file and
        //    into the soundStructArray[audioFile].audioDataLeft and (if stereo) .audioDataRight members.
        UInt32 numberOfPacketsToRead = (UInt32) totalFramesInFile;
        
        CheckError(ExtAudioFileRead (
                                   audioFileObject,
                                   &numberOfPacketsToRead,
                                   bufferList
                                   ),
                   "extaudiofileread fail");
        
        free (bufferList);
    
    /*
                        
            // If reading from the file failed, then free the memory for the sound buffer.
            free (soundStructArray[1].audioDataLeft);
            soundStructArray[1].audioDataLeft = 0;
            
            if (2 == channelCount) {
                free (soundStructArray[1].audioDataRight);
                soundStructarray[1].audioDataRight = 0;
            }
            
            ExtAudioFileDispose (audioFileObject);            
            return;
     
     */
        
        // Set the sample index to zero, so that playback starts at the 
        //    beginning of the sound.
        soundStructArray[1].sampleNumber = 0;
        
        // Dispose of the extended audio file object, which also
        //    closes the associated file.
        ExtAudioFileDispose (audioFileObject);
    //}
     
    soundStructArray[1].fileReady = YES;
}

//************************************************************
//*** Recording setup ***
//************************************************************
- (void)startRecordingAAC
{
    
    OSStatus result;
    
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate= graphSampleRate;
    audioFormat.mFormatID=kAudioFormatLinearPCM;
    audioFormat.mFormatFlags=kAudioFormatFlagsNativeEndian|kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked;
    audioFormat.mBytesPerPacket=bytesPerSample;
    audioFormat.mBytesPerFrame=bytesPerSample;
    audioFormat.mFramesPerPacket=1;
    audioFormat.mChannelsPerFrame=1;
    audioFormat.mBitsPerChannel= 8 * bytesPerSample; 
    audioFormat.mReserved=0;
    
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *destinationFilePath = [[NSString alloc] initWithFormat: @"%@/output.caf", documentsDirectory];
    CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                            (__bridge CFStringRef)destinationFilePath,
                                                            kCFURLPOSIXPathStyle,
                                                            false);
    
    result = ExtAudioFileCreateWithURL(destinationURL,
                                       kAudioFileWAVEType,
                                       &audioFormat,
                                       NULL,
                                       kAudioFileFlags_EraseFile,
                                       &extAudioFile);
    
    CFRelease(destinationURL);
    NSAssert(result == noErr, @"Couldn't create file for writing");
    
    result = ExtAudioFileSetProperty(extAudioFile,
                                     kExtAudioFileProperty_ClientDataFormat,
                                     sizeof(AudioStreamBasicDescription),
                                     &audioFormat);
    
    NSAssert(result == noErr, @"Couldn't create file for format");
    
    result =  ExtAudioFileWriteAsync(extAudioFile, 0, NULL);
    NSAssert(result == noErr, @"Couldn't initialize write buffers for audio file");
    
    result = AudioUnitAddRenderNotify(mRIO, connectingRenderCallback, (__bridge void*)self);


    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(stopRecording:) userInfo:nil repeats:NO];
}

- (void)stopRecording:(NSTimer*)theTimer {
    printf("\nstopRecording\n");

    CheckError(AudioUnitRemoveRenderNotify(mRIO, connectingRenderCallback, (__bridge void*)self),
               "fail");

    OSStatus status = ExtAudioFileDispose(extAudioFile);
    printf("OSStatus(ExtAudioFileDispose): %ld\n", status);
    
    
}

//************************************************************
//*** ASBD print ***
//************************************************************
- (void) printASBD: (AudioStreamBasicDescription) asbd {
    
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    
    NSLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    NSLog (@"  Format ID:           %10s",    formatIDString);
    NSLog (@"  Format Flags:        %10lu",    asbd.mFormatFlags);
    NSLog (@"  Bytes per Packet:    %10lu",    asbd.mBytesPerPacket);
    NSLog (@"  Frames per Packet:   %10lu",    asbd.mFramesPerPacket);
    NSLog (@"  Bytes per Frame:     %10lu",    asbd.mBytesPerFrame);
    NSLog (@"  Channels per Frame:  %10lu",    asbd.mChannelsPerFrame);
    NSLog (@"  Bits per Channel:    %10lu",    asbd.mBitsPerChannel);
}
// Get the shared instance and create it if necessary.

//************************************************************
//*** Singleton setup ***
//************************************************************
static PRPaudioObject *sharedInstance = nil;

+ (PRPaudioObject *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

// We don't want to allocate a new instance, so return the current one.
+ (id)allocWithZone:(NSZone*)zone {
    return [self sharedInstance];
}

// Equally, we don't want to generate multiple copies of the singleton.
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
@end
