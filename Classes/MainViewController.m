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

// Facebook Statics
static NSString* kApiKey = @"9f0083af27bff83ce5d4841716f5ec2f";
static NSString* kApiSecret = @"c28af43643516490f1fb95ceb4aefb42";
static NSString* kGetSessionProxy = nil; // @"<YOUR SESSION CALLBACK)>"; 
// Enter either your API secret or a callback URL above (as described in documentation)


// Upload Statics
static NSString* kServerUploadURL	= @"http://partyplay.heroku.com/uploads"; // @"http://localhost:3000/uploads";
static NSString* kDefaultUploadMessage	= @"Watch our latest party.";
static NSString* kTwitterSource	= @"playparty";
static NSString* kUploadFilename	= @"playparty.caf";
static NSString* kUploadFiletype	= @"audio/x-caf";


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
	
	_label.text = @"Checking audio data...";
	NSData *audioData = [NSData dataWithContentsOfFile:[url path] options: 0 error:&err];
	if(!audioData) {
		NSLog(@"audio data: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
	}
	
	//[editedObject setValue:[NSData dataWithContentsOfURL:url] forKey:editedFieldKey];       
	////[recorder deleteRecording];
	
	
	//NSFileManager *fm = [NSFileManager defaultManager];
	//err = nil;
	//[fm removeItemAtPath:[url path] error:&err];
	//if(err) {
	//	NSLog(@"File Manager: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
	//}

	
	_label.text = @"Playing recording...";
	[self playRecording];
	[self resetRecordButton];
	
	_label.text = @"Uploading audio...";
	[self uploadAudio:_recordingFile withMessage:nil fuid:[NSString stringWithFormat:@"%lld", _session.uid] apiKey:kApiKey];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *) aRecorder successfully:(BOOL)flag {
	[self handleRecordingStopped];
}




///////////////////////////////////////////////////////////////////////////////////////////////////
// Upload Actions

- (void)uploadingDataWithURLRequest:(NSURLRequest *)urlRequest {
	// Called on a separate thread; upload and handle server response
	NSHTTPURLResponse *urlResponse;
	NSError			  *error;
	NSString		  *responseString;
	NSData			  *responseData;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];		// Each thread must have its own NSAutoreleasePool
	
	[urlRequest retain];  // Retain since we autoreleased it before
	
	// Send the request
	urlResponse = nil;  
	responseData = [NSURLConnection sendSynchronousRequest:urlRequest
																			 returningResponse:&urlResponse   
																									 error:&error];  
	responseString = [[NSString alloc] initWithData:responseData
																				 encoding:NSUTF8StringEncoding];
	
	// Handle the error or success
	// If error, create error message and throw up UIAlertView
	NSLog(@"Response Code: %d", [urlResponse statusCode]);
	if ([urlResponse statusCode] >= 200 && [urlResponse statusCode] < 300) {
		NSLog(@"urlResultString: %@", responseString);
		
		//NSString *match = [responseString stringByMatching:@"http[a-zA-Z0-9.:/]*"];  // Match the URL for the post
		//NSLog(@"match: %@", match);
		
		// Notice back to self
		[self performSelectorOnMainThread:@selector(didUploadWithResponse:) withObject:responseString waitUntilDone:NO];
	}
	else {
		NSLog(@"Error while uploading, got 400 error back or no response at all: %d", [urlResponse statusCode]);
		[self performSelectorOnMainThread:@selector(didUploadWithResponse:) withObject:nil waitUntilDone:NO]; // Nil should mean "upload failed" to this method
	}
	
	[pool release];	 // Release everything except responseData and urlResponse–they're autoreleased on creation
	[responseString release];  
	[urlRequest release];
}


- (BOOL)uploadAudio:(NSString *)audioFile withMessage:(NSString *)theMessage fuid:(NSString *)fuid apiKey:(NSString *)apiKey {
	NSString			*stringBoundary, *contentType, *message;
	NSData				*audioData;
	NSURL				*url;
	NSMutableURLRequest *urlRequest;
	NSMutableData		*postBody;
	
	// Create POST request from message, imageData, fuid and apiKey
	url				= [NSURL URLWithString:kServerUploadURL];
	urlRequest		= [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
	[urlRequest setHTTPMethod:@"POST"];	
	
	// Set the params
	message		  = ([theMessage length] > 1) ? theMessage : kDefaultUploadMessage;
	audioData	  = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath: audioFile]];
	
	// Setup POST body
	stringBoundary = [NSString stringWithString:@"0xKhTmLbOuNdArY"];
	contentType    = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];
	[urlRequest addValue:contentType forHTTPHeaderField:@"Content-Type"]; 
	
	// Setting up the POST request's multipart/form-data body
	postBody = [NSMutableData data];
	
	// Fix for Rails requests: http://www.wetware.co.nz/blog/2009/03/upload-a-photo-from-iphone-64-encoding-multi-part-form-data/
	//[postBody appendData:[[NSString stringWithFormat:@"\r\n\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"source\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:kTwitterSource] dataUsingEncoding:NSUTF8StringEncoding]];  // To show up as source in Twitter post
	
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"credentials[facebook_id]\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:fuid] dataUsingEncoding:NSUTF8StringEncoding]];  // facebook_id
	
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"credentials[key]\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:apiKey] dataUsingEncoding:NSUTF8StringEncoding]];  // api_key
	
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"upload[message]\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:message] dataUsingEncoding:NSUTF8StringEncoding]];  // message
	
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"upload[attachment]\"; filename=\"%@\"\r\n", kUploadFilename ] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", kUploadFiletype] dataUsingEncoding:NSUTF8StringEncoding]];  // file as data
	[postBody appendData:[[NSString stringWithString:@"Content-Transfer-Encoding: binary\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:audioData];  // Tack on the audioData to the end
	
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[urlRequest setHTTPBody:postBody];
	
	// Spawn a new thread so the UI isn't blocked while we're uploading the audio
	[NSThread detachNewThreadSelector:@selector(uploadingDataWithURLRequest:) toTarget:self withObject:urlRequest];	
	
	return YES;  // TODO: Should raise exception on error
}

- (void)didUploadWithResponse:(NSString *)responseString {
	_label.text = @"Upload complete (or errored).";
	if (responseString) {
		UIAlertView *uploadCompleteAlert =
		[[UIAlertView alloc] initWithTitle: @"Recording Uploaded!"
															 message: responseString
															delegate: nil
										 cancelButtonTitle:@"OK"
										 otherButtonTitles:nil];
		[uploadCompleteAlert show];
		[uploadCompleteAlert release];
		
	}
	else {
		UIAlertView *cantUploadAlert =
		[[UIAlertView alloc] initWithTitle: @"Can't Upload Recording :("
															 message: @"Damn, check the server logs"
															delegate: nil
										 cancelButtonTitle:@"OK"
										 otherButtonTitles:nil];
		[cantUploadAlert show];
		[cantUploadAlert release];
	}
}

@end
