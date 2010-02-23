//
//  MainViewController.h
//  Test
//
//  Created by Matthew Moore on 2/21/10.
//  Copyright ThriveSmart, LLC 2010. All rights reserved.
//

#import "FlipsideViewController.h"
#import "FBConnect/FBConnect.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface MainViewController : UIViewController 
	<FlipsideViewControllerDelegate, FBDialogDelegate, FBSessionDelegate, FBRequestDelegate, AVAudioRecorderDelegate> {
	IBOutlet UILabel* _label;
	IBOutlet FBLoginButton* _loginButton;
	IBOutlet UIButton* _recordButton;
	FBSession* _session;
	AVAudioRecorder *recorder;
	AVAudioPlayer *player;
	NSString* _recordingFile;
	BOOL _recording;
	NSMutableDictionary* _recordingSettings;
}

@property(nonatomic,readonly) UILabel* label;
@property(nonatomic,readonly) UIButton* recordButton;
@property(nonatomic) BOOL recording;

- (IBAction)showInfo;
- (IBAction)recordButtonClicked;
- (void)askPermission:(id)target;
- (void)resetRecordButton;
- (void)startRecording;
- (void)stopRecording;
- (void)handleRecordingStopped;
- (void)playRecording;

@end
