//
//  CallViewController.h
//  QBRTCChatSemple
//
//  Created by Andrey Ivanov on 11.12.14.
//  Copyright (c) 2014 QuickBlox Team. All rights reserved.
//

#import "QBPlugin.h"
#import <Quickblox/Quickblox.h>
#import <QuickbloxWebRTC/QuickbloxWebRTC.h>

@class QBRTCSession;
@class QBPlugin;

@interface CallViewController : UIViewController <QBRTCClientDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate>
{
	
	QBRTCSession *currentSession;
	QBRTCVideoTrack *remoteVideoTrack;
	QBRTCCameraCapture *cameraCapture;
	AVCaptureVideoPreviewLayer *myVideoLayer;
	NSTimer *callMenuHide;
	QBPlugin *myQBPlugin;
	UIView *coverView;
	BOOL camInitialized;
	BOOL isProvider;
	NSArray *patientsToCall;
	NSString *callStatus;
	
}

@property (weak, nonatomic) IBOutlet UICollectionView *opponentsCollectionView;
//@property (weak, nonatomic) IBOutlet QBToolBar *toolbar;
@property (strong, nonatomic) NSIndexPath *selectedItemIndexPath;
@property (assign, nonatomic) NSTimeInterval timeDuration;
@property (strong, nonatomic) NSTimer *callTimer;
@property (assign, nonatomic) NSTimer *beepTimer;
@property (strong, nonatomic) QBRTCCameraCapture *cameraCapture;
@property (strong, nonatomic) NSMutableDictionary *videoViews;
@property (assign, nonatomic, readonly) BOOL isOffer;
@property (weak, nonatomic) UIView *zoomedView;


@property (strong, nonatomic) QBRTCSession *session;
@property (strong, nonatomic) IBOutlet UIView *v_mainview;
@property (weak, nonatomic) IBOutlet UIView *v_videoout;
@property (weak, nonatomic) IBOutlet QBRTCRemoteVideoView *v_videoin;
@property (weak, nonatomic) IBOutlet UIView *v_menu;
@property (weak, nonatomic) IBOutlet UIButton *b_switch;
@property (weak, nonatomic) IBOutlet UIButton *b_video;
@property (weak, nonatomic) IBOutlet UIButton *b_mic;
@property (weak, nonatomic) IBOutlet UIButton *b_hangup;
@property (weak, nonatomic) IBOutlet UIView *v_menubar;
@property (weak, nonatomic) IBOutlet UIView *v_callingview;
@property (weak, nonatomic) IBOutlet UILabel *l_callinglabel;
@property (weak, nonatomic) IBOutlet UIButton *b_callinghangup;
@property (weak, nonatomic) IBOutlet UILabel *l_callTimer;




- (IBAction)switchCam:(id)sender;
- (IBAction)toggleVideo:(id)sender;
- (IBAction)toggleMic:(id)sender;
- (IBAction)hangup:(id)sender;
- (IBAction)callinghangup:(id)sender;

- (void) setCurrentSession: (QBRTCSession *)session;
- (void) setRemoteVideo: (QBRTCVideoTrack *)remoteVideoTrack;
- (void) initCameraCapture;
- (void) setMyQBPlugin:(QBPlugin *)thePlugin;
- (void)startCall:(NSArray *)patientArray;
- (void) setIsProvider: (BOOL)providerStatus;
- (void) setPatientsToCall: (NSArray *)patientArray;

@end
