//
//  WeemoPlugin.m
//  WeemoPhonegap
//
//  Created by Charles Thierry on 10/31/13.
//
//

#import "QBPlugin.h"
//#import "CallViewController.h"
//#import "RtccDelegate.h"

//#define KEY_MOBILEAPPID	@"appid"
//#define KEY_CALLCONTACT @"callContact"

static BOOL isProvider=false;
static BOOL isDataAvailable=false;

@implementation QBPlugin{
    

}


//dispatch_group_t mygroup = dispatch_group_create();
dispatch_queue_t backgroundQueue = dispatch_queue_create("com.synsormed.findQBID", 0);


#pragma mark - QBSetup




- (void) initQB:(CDVInvokedUrlCommand *)command
{
	
	NSLog(@"I am going to initQB");
	
	[QBSettings setApplicationID:41633];
	
	[QBSettings setAuthKey:@"YKQGUMXRvwtK9kf"];
	
	[QBSettings setAuthSecret:@"ND-eQkQxAYAUYpM"];
	
	[QBSettings setAccountKey:@"Ky2eW7fR2tqfoDzxgZB1"];
	
	[QBRTCClient initializeRTC];
	
	[QBRTCConfig setStatsReportTimeInterval:10];
	

	
	[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"OK"]
								 callbackId:command.callbackId];
	
}

- (void) authent:(CDVInvokedUrlCommand *)command
{
	NSString *loginID;
	
	cb_authent = command.callbackId;
	
	loginID = [command argumentAtIndex:0] != nil ? [command argumentAtIndex:0] : nil;
	
	NSLog(@"I am going to authenticate in QB with %@", loginID);
	
	//Determine if this is a provider or not by looking for an email address
	NSString *string = loginID;
	if ([string rangeOfString:@"@"].location == NSNotFound) {
		NSLog(@"I have determined this is a patient");
		isProvider = NO;
	} else {
		NSLog(@"I have determined this is a provider");
		isProvider = YES;
	}
	
	//Try to login with user. If failed, register user and try again
	
	[self loginQBUser:loginID];
	
}

- (void) disconnect:(CDVInvokedUrlCommand *)command
{
	
	[[QBChat instance] disconnectWithCompletionBlock:^(NSError * _Nullable error) {
		
		if(!error){
			NSLog(@"I was able to disconnect from QBChat without error");
		}else{
			NSLog(@"Error disconnecting from QBChat: %@",error);
		}
		
	}];
	
	[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Disconnected"]
								 callbackId:command.callbackId];
	
}

- (void) loginQBUser:(NSString *) loginID
{
	
	[QBRequest logInWithUserLogin:loginID password:[loginID stringByAppendingString:@"password"] successBlock:^(QBResponse *response, QBUUser *user) {
		
		NSLog(@"The user was found and successfully Logged in");
		
		//Now that user logged into QB, try QBChat
		
		user.password = [user.login stringByAppendingString:@"password"];
		
		[[QBChat instance] connectWithUser:user completion:^(NSError * _Nullable error) {
			
			if(!error){
				NSLog(@"QBChat login was successful");
			}else{
				NSLog(@"Couldn't log into QBChat. Error: %@", error);
			}
			
			
		}];
		//After successful login,have patient (not provider) create a chat dialog to denote presence on the system
		//[self createChatDialog:loginID];
		if(!cvc_active){
			
			NSLog(@"CVC Active does NOT exist. Have to create");
			//After successfull login, instantiate the cvc_active
			rootController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
			rootView = [[[[[UIApplication sharedApplication] delegate] window] rootViewController] view];
			NSString *storyboardname = @"VideoCall";
			UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:storyboardname bundle:[NSBundle mainBundle]];
			cvc_active = [storyBoard instantiateViewControllerWithIdentifier:@"CallViewController"];
			
		}
			
		NSLog(@"CVC Active exists already");
		
		[cvc_active setMyQBPlugin:self];
		[cvc_active setIsProvider:isProvider];
		//[cvc_active initCameraCapture];
		
		//After successfull login, make this class and cvc_active the delegates for the QBRTCCClinet
		[QBRTCClient.instance addDelegate:self];
		[QBRTCClient.instance addDelegate:cvc_active];
		
		[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"OK"]
									 callbackId:cb_authent];
		
		
		
		
		
	} errorBlock:^(QBResponse *response) {
		// error handling
		NSLog(@"The user was NOT found and cannot Log in");
		
		//Try registering user since login failed
		
		[self registerQBUser:loginID];
		
		NSLog(@"error: %@", response.error.reasons);
		
	}];
	
}

- (void) registerQBUser:(NSString *) username
{
	
	
	QBUUser *user = [QBUUser user];
	user.login = username;
	user.password = [username stringByAppendingString:@"password"]	;
	
	[QBRequest signUp:user successBlock:^(QBResponse *response, QBUUser *user) {
		
		NSLog(@"I successfully signed up a new user: %@", user.login);
		//Try Logging in again
		[self loginQBUser:username];
		
		
	} errorBlock:^(QBResponse *response) {
		// error handling
		NSLog(@" I couldn't sign up new user, error: %@", response.error);
		
		[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Auth Failure"]
									 callbackId:cb_authent];
		
	}];
	
	
}

- (void)findQBIDFor:(NSString *)patientCode
{
	
	
	NSMutableArray *patientArray = [[NSMutableArray alloc] init];
	
	[patientArray addObject:patientCode];
	
	//Use Semaphore to make the background queue wait until the success or error blocks return.
	//Those blocks automatically run in the main queue.
	
	dispatch_semaphore_t mysem = dispatch_semaphore_create(0);
	[QBRequest usersWithLogins:patientArray
				  successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *users){
					  
					  NSLog(@"Found matching user: %@", users);
					  QBUUser *foundUser = [users objectAtIndex:0];
					  currentPatientID = (int)foundUser.ID;
					  dispatch_semaphore_signal(mysem);
					  
				  }errorBlock:^(QBResponse *response){
					  NSLog(@"Error looking for user: %@", response.error.reasons);
					  currentPatientID = 0;
					  dispatch_semaphore_signal(mysem);
				  }
	 ];
	
	dispatch_semaphore_wait(mysem, DISPATCH_TIME_FOREVER);
	NSLog(@"I waited until the completion blocks were done");
	
}

-(void) createChatDialog:(NSString *) dialogName
{
	NSLog(@"Trying to create chat dialog");
	// Get the global background priority queue
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
 
	// Create a dispatch group
	dispatch_group_t group = dispatch_group_create();
 
	// Add a task to the group
	//dispatch_group_async(group, queue, ^{
	//dispatch_group_enter(group);
		// Some asynchronous work to do
		//before creating a new dialog, find and erase all old ones
		[self findChatDialogsWithName:dialogName];
	//});
	//dispatch_group_leave(group);
 
	// Do some other work while the tasks execute.
 
	// When you cannot make any more forward progress,
	// wait on the group to block the current thread.
	//dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	
	
	if(!isProvider){
		QBChatDialog *chatDialog = [[QBChatDialog alloc] initWithDialogID:nil type:QBChatDialogTypePublicGroup];
		chatDialog.name = dialogName;
		[QBRequest createDialog:chatDialog successBlock:^(QBResponse *response, QBChatDialog *createdDialog) {
			
			NSLog(@"I successfully created chat dialog with and id of: %@",createdDialog.ID);
			dialogID = createdDialog.ID;
			
		} errorBlock:^(QBResponse *response) {
			
			
			NSLog(@"I failed to create a chat dialog. Error: %@",response.error.reasons);
			
		}];
	}
	
}

-(void) deleteChatDialog:(NSMutableSet *)mydialogIDs
{
	
	NSLog(@"I want to delete dialogs. Here are the IDs I have to delete: %@", mydialogIDs);
	
		[QBRequest deleteDialogsWithIDs:mydialogIDs forAllUsers:YES
						   successBlock:^(QBResponse *response, NSArray *deletedObjectsIDs, NSArray *notFoundObjectsIDs, NSArray *wrongPermissionsObjectsIDs) {
							   
							   NSLog(@"I successfully deleted chat dialog");
							   
						   } errorBlock:^(QBResponse *response) {
							   
							   NSLog(@"I failed to delete a chat dialog. Error: %@",response.error.reasons);
							   
							   
						   }];
		
	
	
}

//-(NSMutableSet *) findChatDialogsWithName:(NSString *)dName
-(void) findChatDialogsWithName:(NSString *)dName
{
	NSLog(@"Trying to find chat dialog");
	QBResponsePage *page = [QBResponsePage responsePageWithLimit:100 skip:0];
	NSDictionary *eRequest = @{@"name" : dName};
	NSMutableSet *foundDialogIDs = [NSMutableSet set];
	

	dispatch_group_t group = dispatch_group_create();
	dispatch_group_enter(group);
	[QBRequest dialogsForPage:page extendedRequest:eRequest successBlock:^(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, QBResponsePage *page) {
		
		NSLog(@"I found a dialog: %@", dialogObjects);
		for(QBChatDialog *theDialog in dialogObjects){
			
			NSLog(@"The individual found dialog is %@", theDialog);
			NSLog(@"The ID is %@", theDialog.ID);
			[foundDialogIDs addObject:theDialog.ID];
		}
		NSLog(@"The found dialogIDs are: %@",foundDialogIDs);
		dispatch_group_leave(group);
		matchedDialogIDs = foundDialogIDs;
		if(matchedDialogIDs != nil)[self deleteChatDialog:matchedDialogIDs];
		
	} errorBlock:^(QBResponse *response) {
		
		NSLog(@" I had trouble getting the dialogs: %@", response.error);
		dispatch_group_leave(group);
		
	}];
	
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	NSLog(@"This is amin proof that I am skipping along to creaate");
	
	//return foundDialogIDs;
	
}




#pragma mark - Session Mgt

- (void) createCall:(CDVInvokedUrlCommand *)command
{
	//Get the values passed by plugin
	NSString *recipient = [command argumentAtIndex:0];
	NSString *isProvider = [command argumentAtIndex:1];
	NSString *allowSwitch = [command argumentAtIndex:2];
	
	NSLog(@"I am in native and going to createCall to: %@", recipient);
	
	//Put this in background queue because looking for QBID has blocks that must
	//run in main queue. By running this in background queue, we can make it wait
	//until the success/error blocks are done
	dispatch_async(backgroundQueue, ^{
		
		[self findQBIDFor:recipient];
		NSLog(@"I looked for and ID and got: %d", currentPatientID);
		NSArray *patientIDs = [NSArray arrayWithObjects:[NSNumber numberWithInt:currentPatientID], nil];
		[cvc_active setPatientsToCall:patientIDs];
		dispatch_async(dispatch_get_main_queue(), ^{
			//Do GUI update in main queue to avoid delay
			[self displayCallView];
		});
		//[cvc_active startCall:patientIDs];

		/*Commented out to test different call route 6/17/16
		 
		//NSArray *patientIDs = @[@13543193];
		
		
		
		QBRTCSession *newSession = [QBRTCClient.instance createNewSessionWithOpponents:patientIDs
																	withConferenceType:QBRTCConferenceTypeVideo];
		
		currentSession = newSession;
		[newSession startCall:nil];
		 
		 */

		//AH: If the call was created incoming, let JS know
		[[self commandDelegate]evalJs:[NSString stringWithFormat:@"videoPlugin.internal.callCreated(%d, \"%@\");", 0, @"PROCEEDING"]];
		
		[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Call made"]
									 callbackId:command.callbackId];
		 
		 
		
	});
}

- (void)displayCallView
{
	
	
	[rootController addChildViewController:cvc_active];
	[rootView addSubview:[cvc_active view]];
	[[cvc_active view] setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin |
	 UIViewAutoresizingFlexibleRightMargin |
	 UIViewAutoresizingFlexibleTopMargin |
	 UIViewAutoresizingFlexibleLeftMargin];
	
	
}

- (void) acceptCall:(CDVInvokedUrlCommand *)command
{
	
	if(currentSession){
		
		[self displayCallView];
		
		
		//[currentSession acceptCall:nil];
		
	}
	
	
	
	[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Call accepted"]
								 callbackId:command.callbackId];
	
}

- (void) hangUp:(CDVInvokedUrlCommand *)command
{
	
	[currentSession hangUp:nil];
	
	[self endCallJS];
	
	[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Call hungup"]
								 callbackId:command.callbackId];
	
}

- (void) endCallJS
{
	
	[[self commandDelegate]evalJs:[NSString stringWithFormat:@"videoPlugin.internal.callStatusChanged(%d, \"%@\");", 0, @"ENDED"]];
	
}

- (void) goBackToWaitJS
{
	
	[[self commandDelegate]evalJs:[NSString stringWithFormat:@"videoPlugin.internal.callStatusChanged(%d, \"%@\");", 0, @"NONE"]];
	
}

- (BOOL) getProviderStatus
{
	
	return isProvider;
	
}

- (void) clearCVC
{
	
	cvc_active = nil;
	
}

//Gets the QB status of the patient
- (void) getStatus:(CDVInvokedUrlCommand *)command{
	
	cb_getStatus = command.callbackId;
	BOOL canBeCalled = NO;
	
	NSString *patientID = [command argumentAtIndex:0];
	
	QBResponsePage *page = [QBResponsePage responsePageWithLimit:100 skip:0];
	NSDictionary *eRequest = @{@"name" : @"HNCYB23"};
 
	[QBRequest dialogsForPage:page extendedRequest:eRequest successBlock:^(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, QBResponsePage *page) {
		
		NSLog(@"I found a dialog: %@", dialogObjects);
		
	} errorBlock:^(QBResponse *response) {
		
		NSLog(@" I had trouble getting the dialogs: %@", response.error);
		
	}];
	
	
	 [[self commandDelegate] sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:canBeCalled?1:0] callbackId:cb_getStatus];
	
}


#pragma mark - Delegate Methods

//This is for incoming calls
- (void)didReceiveNewSession:(QBRTCSession *)session userInfo:(NSDictionary *)userInfo
{
	
	currentSession = session;
	
	//AH: If the call was created incoming, let JS know
	[[self commandDelegate]evalJs:[NSString stringWithFormat:@"videoPlugin.internal.callCreated(%d, \"%@\");", 0, @"RINGING"]];
	
}


//This is to know if the person accepted the call
- (void)session:(QBRTCSession *)session acceptedByUser:(NSNumber *)userID userInfo:(NSDictionary *)userInfo
{
	NSLog(@"Call was accepted by: %@", userID);
	//NSLog(@"Call was accepted by %@ so I'm going to display call view", userID);
	//[self displayCallView];
	
}

/**
 *  Called when connection is established with user
 *
 *  @param session QBRTCSession instance
 *  @param userID  ID of user
 */
- (void)session:(QBRTCSession *)session connectedToUser:(NSNumber *)userID
{
	NSLog(@"I am now connected to this user in the session: %@", userID);
	
	//AH: If the call was created incoming, let JS know
	[[self commandDelegate]evalJs:[NSString stringWithFormat:@"videoPlugin.internal.callStatusChanged(%d, \"%@\");", 0, @"ACTIVE"]];
	//[self displayCallView];

	
	
}


- (void)session:(QBRTCSession *)session receivedRemoteVideoTrack:(QBRTCVideoTrack *)videoTrack fromUser:(NSNumber *)userID {
 
	// we suppose you have created UIView and set it's class to QBRTCRemoteVideoView class
	// also we suggest you to set view mode to UIViewContentModeScaleAspectFit or
	// UIViewContentModeScaleAspectFill
	
	
	NSLog(@"I received remote Video track inside of the plugin, not the callviewcontroller");
	
	//store the video track in the class variable for use later
	remoteVideoTrack = videoTrack;
	
	
}


- (void)session:(QBRTCSession *)session hungUpByUser:(NSNumber *)userID userInfo:(NSDictionary *)userInfo
{
	
	NSLog(@"The other user hung up first, so I need to exit. I'm in the plugin");
	

	
}

- (void)session:(QBRTCSession *)session initializedLocalMediaStream:(QBRTCMediaStream *)mediaStream
{
	
	camInitialized = YES;
	
}




@end
