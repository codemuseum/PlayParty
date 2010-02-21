//
//  MainViewController.h
//  Test
//
//  Created by Matthew Moore on 2/21/10.
//  Copyright ThriveSmart, LLC 2010. All rights reserved.
//

#import "FlipsideViewController.h"
#import "FBConnect/FBConnect.h"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, FBDialogDelegate, FBSessionDelegate, FBRequestDelegate> {
	IBOutlet UILabel* _label;
	IBOutlet FBLoginButton* _loginButton;
	FBSession* _session;
}

@property(nonatomic,readonly) UILabel* label;

- (IBAction)showInfo;
- (void)askPermission:(id)target;

@end
