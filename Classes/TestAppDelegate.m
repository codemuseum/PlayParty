//
//  TestAppDelegate.m
//  Test
//
//  Created by Matthew Moore on 2/21/10.
//  Copyright ThriveSmart, LLC 2010. All rights reserved.
//

#import "TestAppDelegate.h"
#import "MainViewController.h"

@implementation TestAppDelegate


@synthesize window;
@synthesize mainViewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
	MainViewController *aController = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
	self.mainViewController = aController;
	[aController release];
	
    mainViewController.view.frame = [UIScreen mainScreen].applicationFrame;
	[window addSubview:[mainViewController view]];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [mainViewController release];
    [window release];
    [super dealloc];
}

@end
