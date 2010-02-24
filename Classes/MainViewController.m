//
//  MainViewController.m
//  Test
//
//  Created by Matthew Moore on 2/21/10.
//  Copyright ThriveSmart, LLC 2010. All rights reserved.
//

#define AUDIO_SAVE_DIR [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

#import "MainViewController.h"
#import "MainView.h"

static NSString* kApiKey = @"9f0083af27bff83ce5d4841716f5ec2f";
// Enter either your API secret or a callback URL (as described in documentation):
static NSString* kApiSecret = @"c28af43643516490f1fb95ceb4aefb42";
static NSString* kGetSessionProxy = nil; // @"<YOUR SESSION CALLBACK)>";



@implementation MainViewController

// Facebook Properties
@synthesize label = _label;

// Sound Record & Play Properties
@synthesize recording = _recording;
@synthesize recordButton = _recordButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		if (kGetSessionProxy) {
			_session = [[FBSession sessionForApplication:kApiKey getSessionProxy:kGetSessionProxy delegate:self] retain];
		}
		else {
			_session = [[FBSession sessionForApplication:kApiKey secret:kApiSecret delegate:self] retain];
		}
	}
	return self;
}


- (void)dealloc {
	// Facebook dealloc
  [_session release];
	
	// AVAudioRecorder dealloc
	[recorder release];
	[_recordingFile release];
	[_recordingSettings release];
	[player	release];
	
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIViewController


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Facebook Initialize Code
	[_session resume];
	_loginButton.style = FBLoginButtonStyleWide;
	
	// AVAudioRecorder Initialize Code
	
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}




/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */


///////////////////////////////////////////////////////////////////////////////////////////////////
// FlipsideViewControllerDelegate

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
	
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction)showInfo {    
	
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}


- (IBAction)recordButtonClicked {
	if (_recording) {
		[self stopRecording];
	}
	else {
		[self startRecording];
	}
	
}


///////////////////////////////////////////////////////////////////////////////////////////////////
// FBDialogDelegate

- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError*)error {
  _label.text = [NSString stringWithFormat:@"Error(%d) %@", error.code, error.localizedDescription];
}

- (void)dialogDidSucceed:(FBDialog*)dialog { 
	_label.text = @"Permission Set Succeeded";
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// FBSessionDelegate

- (void)session:(FBSession*)session didLogin:(FBUID)uid {
	NSString* fql = [NSString stringWithFormat:@"select uid,name from user where uid == %lld", session.uid];
	
	NSDictionary* params = [NSDictionary dictionaryWithObject:fql forKey:@"query"];
	[[FBRequest requestWithDelegate:self] call:@"facebook.fql.query" params:params];
}

- (void)sessionDidLogout:(FBSession*)session {
  _label.text = @"Logged Out.";
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// FBRequestDelegate

- (void)request:(FBRequest*)request didLoad:(id)result {
  NSArray* users = result;
  NSDictionary* user = [users objectAtIndex:0];
  NSString* name = [user objectForKey:@"name"];
  _label.text = [NSString stringWithFormat:@"Logged in as %@", name];
	
	[self askPermission:result];
}

- (void)request:(FBRequest*)request didFailWithError:(NSError*)error {
  _label.text = [NSString stringWithFormat:@"Error(%d) %@", error.code, error.localizedDescription];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
// Facebook connection actions

- (void)askPermission:(id)target {
  FBPermissionDialog* dialog = [[[FBPermissionDialog alloc] init] autorelease];
  dialog.delegate = self;
  dialog.permission = @"status_update";
  [dialog show];
}



///////////////////////////////////////////////////////////////////////////////////////////////////
// Audio Video & Recording Actions


- (void) resetRecordButton {
	[_recordButton setTitle:@"Record" forState:UIControlStateNormal];
	_recording = NO;
}

- (void) startRecording {
	[_recordButton setTitle:@"Stop" forState:UIControlStateNormal];
	
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	NSError *err = nil;
	[audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
	if(err){
		NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
		return;
	}
	[audioSession setActive:YES error:&err];
	err = nil;
	if(err){
		NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
		return;
	}
	
	if (!_recordingSettings) {
		_recordingSettings = [[NSMutableDictionary alloc] init];
		[_recordingSettings setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
		[_recordingSettings setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey]; 
		[_recordingSettings setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
		[_recordingSettings setValue :[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
		[_recordingSettings setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
		[_recordingSettings setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
	}
	
	// Create a new dated file
	NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
	NSString *caldate = [now description];
	_recordingFile = [[NSString stringWithFormat:@"%@/%@.caf", AUDIO_SAVE_DIR, caldate] retain];
	
	NSURL *url = [NSURL fileURLWithPath:_recordingFile];
	err = nil;
	recorder = [[ AVAudioRecorder alloc] initWithURL:url settings:_recordingSettings error:&err];
	if (!recorder) {
		NSLog(@"recorder: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
		UIAlertView *alert =
		[[UIAlertView alloc] initWithTitle: @"Warning"
															 message: [err localizedDescription]
															delegate: nil
										 cancelButtonTitle: @"OK"
										 otherButtonTitles: nil];
		[alert show];
		[alert release];
		[self resetRecordButton];
		return;
	}
	
	//prepare to record
	[recorder setDelegate:self];
	[recorder prepareToRecord];
	recorder.meteringEnabled = YES;
	
	BOOL audioHWAvailable = audioSession.inputIsAvailable;
	if (! audioHWAvailable) {
		UIAlertView *cantRecordAlert =
		[[UIAlertView alloc] initWithTitle: @"Warning"
															 message: @"Audio input hardware not available"
															delegate: nil
										 cancelButtonTitle:@"OK"
										 otherButtonTitles:nil];
		[cantRecordAlert show];
		[cantRecordAlert release]; 
		return;
	}
	
	// start recording
	[recorder recordForDuration:(NSTimeInterval) 120];
	_recording = YES;
}

- (void) stopRecording {
	[recorder stop];
	[self handleRecordingStopped];
}

- (void) playRecording {
	NSURL *url = [NSURL fileURLWithPath: _recordingFile];
	NSError *err;
	if (player) {
		[player release];
		player = nil;
	}
	player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
	player.numberOfLoops = 0;
	
	if (player == nil) {
		UIAlertView *cantPlayAlert =
		[[UIAlertView alloc] initWithTitle: @"Can't Play Recording"
															 message: [err localizedDescription]
															delegate: nil
										 cancelButtonTitle:@"OK"
										 otherButtonTitles:nil];
		[cantPlayAlert show];
		[cantPlayAlert release];
	}
	else {
		[player play];
	}
}

- (void) handleRecordingStopped {
	NSURL *url = [NSURL fileURLWithPath: _recordingFile];
	NSError *err = nil;
	NSData *audioData = [NSData dataWithContentsOfFile:[url path] options: 0 error:&err];
	if(!audioData) {
		NSLog(@"audio data: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
	}
	
	//[editedObject setValue:[NSData dataWithContentsOfURL:url] forKey:editedFieldKey];       
	//[recorder deleteRecording];
	
	
	//NSFileManager *fm = [NSFileManager defaultManager];
	//err = nil;
	//[fm removeItemAtPath:[url path] error:&err];
	//if(err) {
	//	NSLog(@"File Manager: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
	//}

	[self playRecording];
	
	[self resetRecordButton];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *) aRecorder successfully:(BOOL)flag {
	[self handleRecordingStopped];
	
	NSLog (@"audioRecorderDidFinishRecording:successfully:");
	// your actions here
}



@end
