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
	
	// Facebook Items
	IBOutlet UILabel* _label;
	IBOutlet FBLoginButton* _loginButton;
	FBSession* _session;
	
	// Audio Record & Play Buttons
	IBOutlet UIButton* _recordButton;
	AVAudioRecorder *recorder;
	AVAudioPlayer *player;
	NSString* _recordingFile;
	BOOL _recording;
	NSMutableDictionary* _recordingSettings;
}

// Facebook Properties
@property(nonatomic,readonly) UILabel* label;

// Audio Record & Play Properties
@property(nonatomic,readonly) UIButton* recordButton;
@property(nonatomic) BOOL recording;

- (IBAction)showInfo;

// Facebook Actions
- (void)askPermission:(id)target;
- (void)askVideoUploadPermission;

// Audio Record & Play Actions
- (IBAction)recordButtonClicked;
- (void)resetRecordButton;
- (void)startRecording;
- (void)stopRecording;
- (void)handleRecordingStopped;
- (void)playRecording;

// Upload Actions
- (BOOL)uploadAudio:(NSString *)audioFile withPic:(NSString *)picCoords withGameType:(NSString *)theGameType withPrompt:(NSString *)thePrompt withHint:(NSString *)theHint gameWon:(BOOL)gameWon gameTimeMillisecs:(NSInteger)gameTime fuid:(NSString *)fuid apiKey:(NSString *)apiKey facebookSessionKey:(NSString *)facebookSessionKey;
- (void)uploadingDataWithURLRequest:(NSURLRequest *)urlRequest;
- (void)didUploadWithResponse:(NSString *)responseString;

@end
