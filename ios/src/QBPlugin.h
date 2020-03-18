//
//  WeemoPlugin.h
//  WeemoPhonegap
//
//  Created by Charles Thierry on 10/31/13.
//
//

/**
 * This class is the interface between the Javascript and the WeemoSDK and does nothing more than controlling said driver and most of the CallView (the UIView displayed on top of the WebView of this app).
 */

#import <Cordova/CDVPlugin.h>
#import "CallViewController.h"
#import <Quickblox/Quickblox.h>
#import <QuickbloxWebRTC/QuickbloxWebRTC.h>

@class CallViewController;


@protocol WeemoControlDelegate <NSObject>

- (void)WCD:(CDVPlugin *)wdController AddController:(UIViewController *) cvc;
- (void)WCD:(CDVPlugin *)wdController RemoveController:(UIViewController *) cvc;

@end

//@interface WeemoPlugin : CDVPlugin <RtccDelegate, RtccCallDelegate, RtccAttendeeDelegate, HomeDelegate>
@interface QBPlugin : CDVPlugin <QBRTCClientDelegate>
{
	
	CallViewController *cvc_active;
	NSString *cb_authent;
	NSString *cb_getStatus;
	QBRTCSession *currentSession;
	QBRTCVideoTrack *remoteVideoTrack;
	UIViewController *rootController;
	UIView *rootView;
	BOOL isProvider;
	NSString *dialogID;
	NSMutableSet *matchedDialogIDs;
	int currentPatientID;
	BOOL camInitialized;

}
+ (id)instance;
- (void)registerQBUser:(NSString *) username;
- (void) endCallJS;
-(void) createChatDialog:(NSString *) dialogName;
-(void) deleteChatDialog:(NSMutableSet *)mydialogIDs;
- (BOOL) getProviderStatus;
-(void)clearCVC;
- (void) goBackToWaitJS;



@end
