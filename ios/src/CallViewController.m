//
//  CallViewController.m
//  QBRTCChatSemple
//
//  Created by Andrey Ivanov on 11.12.14.
//  Copyright (c) 2014 QuickBlox Team. All rights reserved.
//

#import "CallViewController.h"
/*
#import "ChatManager.h"
#import "CornerView.h"
#import "LocalVideoView.h"
#import "OpponentCollectionViewCell.h"
#import "OpponentsFlowLayout.h"
#import "QBButton.h"
#import "QBButtonsFactory.h"
#import "QBToolBar.h"
#import "QMSoundManager.h"
#import "Settings.h"
#import "SharingViewController.h"
#import "SVProgressHUD.h"
#import "UsersDataSource.h"
#import <mach/mach.h>
*/

NSString *const kOpponentCollectionViewCellIdentifier = @"OpponentCollectionViewCellIdentifier";
NSString *const kSharingViewControllerIdentifier = @"SharingViewController";

const NSTimeInterval kRefreshTimeInterval = 1.f;



@implementation CallViewController
{
	
	
	
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	
	
		return self;
}

- (void)dealloc {
	
	NSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (NSNumber *)currentUserID {
	
//	return @(UsersDataSource.instance.currentUser.ID);
}

- (void) initCameraCapture
{
	QBRTCVideoFormat *videoFormat = [[QBRTCVideoFormat alloc] init];
	videoFormat.frameRate = 30;
	videoFormat.pixelFormat = QBRTCPixelFormat420f;
	videoFormat.width = 640;
	videoFormat.height = 480;
	
	if(!cameraCapture){
		
		cameraCapture = [[QBRTCCameraCapture alloc] initWithVideoFormat:videoFormat
															   position:AVCaptureDevicePositionFront];
		//cameraCapture = [[QBRTCCameraCapture alloc] initWithVideoFormat:[QBRTCVideoFormat defaultFormat]
		//															position:AVCaptureDevicePositionFront];
		
	}
	
	cameraCapture.previewLayer.frame = _v_videoout.bounds;
	
	myVideoLayer = cameraCapture.previewLayer;
	
	[cameraCapture startSession];
	
	
	
	
	// QBRTCCameraCapture class used to capture frames using AVFoundation APIs
	/*QBRTCVideoFormat *videoFormat = [[QBRTCVideoFormat alloc] init];
	videoFormat.frameRate = 30;
	videoFormat.pixelFormat = QBRTCPixelFormat420f;
	videoFormat.width = 640;
	videoFormat.height = 480;
	cameraCapture = [[QBRTCCameraCapture alloc] initWithVideoFormat:videoFormat position:AVCaptureDevicePositionFront]; // or AVCaptureDevicePositionBack
 
	self.cameraCapture.previewLayer.frame = _v_videoout.bounds;
	[self.cameraCapture startSession];
 
	[_v_videoout.layer insertSublayer:self.cameraCapture.previewLayer atIndex:0];
	*/
}

- (void)viewDidLoad {
	[super viewDidLoad];
	NSLog(@">>>> Inside ViewDidLoad");
	
	//[self initCameraCapture];
	
	
	
	//NSLog(@"I am about to try to put the local view in the previewlayer");
	//[_v_videoout.layer insertSublayer:cameraCapture.previewLayer atIndex:0];
	
	/*
	 QBUUser *initiator = [UsersDataSource.instance userWithID:self.session.initiatorID];
	 _isOffer = [UsersDataSource.instance.currentUser isEqual:initiator];
	 
	 self.view.backgroundColor = self.opponentsCollectionView.backgroundColor = [UIColor colorWithRed:0.1465 green:0.1465 blue:0.1465 alpha:1.0];
	 */
	
	/*
	 NSMutableArray *users = [NSMutableArray arrayWithCapacity:self.session.opponentsIDs.count + 1];
	 [users insertObject:UsersDataSource.instance.currentUser atIndex:0];
	 
	 NSMutableArray *opponents = [UsersDataSource.instance usersWithIDSWithoutMe:self.session.opponentsIDs].mutableCopy;
	 
	 if (!self.isOffer) {
		
		[opponents addObject:initiator];
	 }
	 
	 [users addObjectsFromArray:opponents];
	 
	 self.users = users.copy;
	 */
	
	/*
	 [self updateDynamicImage];
	 
	 self.isOffer ? [self startCall] : [self acceptCall];
	 
	 if (self.session.conferenceType == QBRTCConferenceTypeAudio) {
		[QBRTCSoundRouter instance].currentSoundRoute = QBRTCSoundRouteReceiver;
	 }
	 */
}


- (void)viewWillAppear:(BOOL)animated{
	
	[super viewWillAppear:animated];
	
	NSLog(@">>>> Inside View will appear");
	
	
	[self initCameraCapture];
	
	//Position cover screeen until call is ready
	coverView = [[UIView alloc] initWithFrame:self.view.bounds];
	[coverView setBackgroundColor:[UIColor colorWithRed:0.024 green:0.671 blue:0.643 alpha:1]];
	coverView.tag = 86;
	[self.view insertSubview:coverView atIndex:80];
	[self.view bringSubviewToFront:coverView];
 
	
	
	
	//currentSession.localMediaStream.videoTrack.enabled = true;
	
	[QBRTCSoundRouter.instance initialize];
	
	
	
}
- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	NSLog(@">>>> Inside View Did Appear");
	_timeDuration = 0;
	[self configureGUI];
	
	
	if(isProvider){//This is a provider, so we must have clicked to call someone
		
		NSLog(@"This is provider in CVC, going to make call");
		[self startCall:patientsToCall];
		callStatus = @"RINGING";
		
		
	}else{
		
		[currentSession acceptCall:nil];
		
	}
	
	

	
	
	[QBRTCSoundRouter.instance addObserver:self forKeyPath:@"currentSoundRoute" options:NSKeyValueObservingOptionNew context:nil];
	
	self.title = @"Connecting...";
	
	//[_v_videoout setBackgroundColor:[UIColor clearColor]];
	//[_v_videoout.layer insertSublayer:myVideoLayer atIndex:0];


	
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[QBRTCSoundRouter.instance removeObserver:self forKeyPath:@"currentSoundRoute"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
	[self updateDynamicImage];
}

- (void)updateDynamicImage {
	QBRTCSoundRouter *router = QBRTCSoundRouter.instance;
	
	BOOL pressed = NO;
	
	if (router.currentSoundRoute == QBRTCSoundRouteSpeaker) {
		pressed = YES;
	} else if (router.currentSoundRoute == QBRTCSoundRouteReceiver) {
		pressed = NO;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		//		self.dynamicEnable.pressed = pressed;
	});
}

- (UIView *)videoViewWithOpponentID:(NSNumber *)opponentID {
/*
	if (self.session.conferenceType == QBRTCConferenceTypeAudio) {
		return nil;
	}
	
	if (!self.videoViews) {
		self.videoViews = [NSMutableDictionary dictionary];
	}
	
	id result = self.videoViews[opponentID];
	
	if (UsersDataSource.instance.currentUser.ID == opponentID.integerValue) {//Local preview
		
		if (!result) {
			
			LocalVideoView *localVideoView = [[LocalVideoView alloc] initWithPreviewlayer:self.cameraCapture.previewLayer];
			self.videoViews[opponentID] = localVideoView;
			localVideoView.delegate = self;
			self.localVideoView = localVideoView;
			return localVideoView;
		}
	}
	else {//Opponents
		
		QBRTCRemoteVideoView *remoteVideoView = nil;
		
		QBRTCVideoTrack *remoteVideoTrak = [self.session remoteVideoTrackWithUserID:opponentID];
		
		if (!result && remoteVideoTrak) {
			
			remoteVideoView = [[QBRTCRemoteVideoView alloc] initWithFrame:self.view.bounds];
			self.videoViews[opponentID] = remoteVideoView;
			result = remoteVideoView;
		}
		
		[remoteVideoView setVideoTrack:remoteVideoTrak];
		
		return result;
	}
	
	return result;
 */
}


- (void) setCurrentSession: (QBRTCSession *)session
{
	
	currentSession = session;
	
}

- (void) setRemoteVideo: (QBRTCVideoTrack *)VideoTrack
{
	NSLog(@"I am in setremote video in CVC");
	remoteVideoTrack = VideoTrack;
	
	
}

- (void)startCall: (NSArray *)patientArray {
	
	
	QBRTCSession *newSession = [QBRTCClient.instance createNewSessionWithOpponents:patientArray
																withConferenceType:QBRTCConferenceTypeVideo];
	
	currentSession = newSession;
	[newSession startCall:nil];
	
	[self showCallingScreen];
	
	
	
	//Begin play calling sound
	/*self.beepTimer = [NSTimer scheduledTimerWithTimeInterval:[QBRTCConfig dialingTimeInterval]
													  target:self
													selector:@selector(playCallingSound:)
													userInfo:nil
													 repeats:YES];
	[self playCallingSound:nil];
	//Start call
	NSDictionary *userInfo = @{@"startCall" : @"userInfo"};
	[self.session startCall:userInfo];
	 */
	
}

- (void)acceptCall {
/*
	[QMSysPlayer stopAllSounds];
	//Accept call
	NSDictionary *userInfo = @{@"acceptCall" : @"userInfo"};
	[self.session acceptCall:userInfo];
 */
}

- (void)showCallingScreen {
	/*
	//Add label and button to coverview
	UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(50.0, 50.0, 200.0, 100.0)];
	[statusLabel setText:@"Ringing Patient"];
	[statusLabel setTextAlignment:NSTextAlignmentCenter];
	[statusLabel setTextColor:[UIColor redColor]];
	[coverView addSubview:statusLabel];
	 */
	_v_callingview.layer.cornerRadius = 10;
	_v_callingview.layer.masksToBounds = YES;
	[_v_callingview setHidden:NO];
	[self.view bringSubviewToFront:_v_callingview];
}

- (void)configureGUI {
	
	__weak __typeof(self)weakSelf = self;
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	self.view.autoresizesSubviews = NO;
	
	float reductionFactor = 0.8;
	
	//Find out if this is an Ipad
	BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
	
	//Hide the menubar
	[_v_menubar setAlpha:0.];
	
	//Position menubar
	[_v_menubar setFrame:CGRectMake(0.0, [UIScreen mainScreen].bounds.size.height-120.0,
									[UIScreen mainScreen].bounds.size.width, 120.0)];
	
	//Position buttons
	[_b_switch setCenter:CGPointMake([UIScreen mainScreen].bounds.size.width/8, 60.0)];
	[_b_video setCenter:CGPointMake(3*([UIScreen mainScreen].bounds.size.width)/8, 60.0)];
	[_b_mic setCenter:CGPointMake(5*([UIScreen mainScreen].bounds.size.width)/8, 60.0)];
	[_b_hangup setCenter:CGPointMake(7*([UIScreen mainScreen].bounds.size.width)/8, 60.0)];
	
	//Clear button backgrounds
	[_b_switch setBackgroundColor:[UIColor clearColor]];
	[_b_video setBackgroundColor:[UIColor clearColor]];
	[_b_mic setBackgroundColor:[UIColor clearColor]];
	[_b_hangup setBackgroundColor:[UIColor clearColor]];
	
	//Position Self View
	
	[_v_videoout setCenter:CGPointMake([UIScreen mainScreen].bounds.size.width - 85.0, [UIScreen mainScreen].bounds.size.height-200.0)];
	
	//Paint encryption img
	UIImageView *encryptionImage=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"encryption.png"]];
	encryptionImage.frame=CGRectMake(20, 20, 20, 20);
	//[self.view addSubview:encryptionImage];
	[self.view insertSubview:encryptionImage atIndex:9];
	
	//Position Calling screen
	[_v_callingview setCenter:CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2)];
	
	
	
	//Change the layout if iphone
	if(!isPad){
		
		NSLog(@"The height of the Iphone screen is: %f", [UIScreen mainScreen].nativeBounds.size.height);
		NSLog(@"The width of the Iphone screen is: %f", [UIScreen mainScreen].nativeBounds.size.width);
		
		//Shrink the self view by 50 pixels
		[_v_videoout setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 120.0,
										 [UIScreen mainScreen].bounds.size.height- 220.0,
										  100.0, 100.0)];
	
		
		
	}
	
	
	
	
	/*
	UIViewController *rootController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
	UIView *rootView = [[[[[UIApplication sharedApplication] delegate] window] rootViewController] view];
	
	CGRect videoInFrame = CGRectMake(100.0,
									 100.0,
									 300.0,
									 600.00);
	
	NSLog(@"The numbers for size are: %f, %f, %f, %f", rootView.bounds.origin.x, rootView.bounds.origin.y, _v_videoin.bounds.size.width, _v_videoin.bounds.size.height);
	*/
	
	//[[self v_mainview] setFrame:CGRectIntegral(videoInFrame)];
	//[self.view setTranslatesAutoresizingMaskIntoConstraints:YES];
	//[[self v_videoin] setFrame:CGRectIntegral(videoInFrame)];
	
	
	//[_v_videoin setFrame:videoInFrame];
	
	
	/*
	if (self.session.conferenceType == QBRTCConferenceTypeVideo) {
		
		self.videoEnabled = [QBButtonsFactory videoEnable];
		[self.toolbar addButton:self.videoEnabled action: ^(UIButton *sender) {
			
			weakSelf.session.localMediaStream.videoTrack.enabled ^=1;
			weakSelf.localVideoView.hidden = !weakSelf.session.localMediaStream.videoTrack.enabled;
		}];
	}
	
	[self.toolbar addButton:[QBButtonsFactory auidoEnable] action: ^(UIButton *sender) {
		
		weakSelf.session.localMediaStream.audioTrack.enabled ^=1;
	}];
	
	self.dynamicEnable = [QBButtonsFactory dynamicEnable];
	
	[self.toolbar addButton:self.dynamicEnable action:^(UIButton *sender) {
		
		QBRTCSoundRouter *router = [QBRTCSoundRouter instance];
		
		QBRTCSoundRoute route = router.currentSoundRoute;
		
		router.currentSoundRoute =
		route == QBRTCSoundRouteSpeaker ? QBRTCSoundRouteReceiver : QBRTCSoundRouteSpeaker;
	}];
	
	if (self.session.conferenceType == QBRTCConferenceTypeVideo) {
		
		[self.toolbar addButton:[QBButtonsFactory screenShare] action: ^(UIButton *sender) {
			
			SharingViewController *sharingVC =
			[weakSelf.storyboard instantiateViewControllerWithIdentifier:kSharingViewControllerIdentifier];
			sharingVC.session = weakSelf.session;
			
			[weakSelf.navigationController pushViewController:sharingVC animated:YES];
		}];
	}
	
	[self.toolbar addButton:[QBButtonsFactory decline] action: ^(UIButton *sender) {
		
		[weakSelf.callTimer invalidate];
		weakSelf.callTimer = nil;
		
		[weakSelf.session hangUp:@{@"hangup" : @"hang up"}];
	}];
	
	[self.toolbar updateItems];
	 */
}


- (void) setMyQBPlugin:(QBPlugin *)thePlugin
{
	
	myQBPlugin = thePlugin;
	
}

- (void) setIsProvider: (BOOL)providerStatus
{
	
	isProvider = providerStatus;
	
}

- (void) setPatientsToCall: (NSArray *)patientArray
{
	
	patientsToCall = patientArray;
	
}

- (void) cleanUP
{
	NSLog(@"The call is complete, going to cleanup");
	
	currentSession = nil;
	callStatus = @"ENDED";
	
	//Tell JS side the call has ended
	[myQBPlugin endCallJS];
	
	//Delete the chat dialog if not a provider
	//if(![myQBPlugin getProviderStatus])[myQBPlugin deleteChatDialog:nil];
	
	//remove the cover view that always has a tag of 86
	[[self.view viewWithTag:86] removeFromSuperview];
	
	//remove the remote view that always has a tag of 76
	[[self.view viewWithTag:76] removeFromSuperview];
	
	//Remove the call view from superview
	[[self view] removeFromSuperview];
	
	//Turn off camera capture
	[cameraCapture stopSession];
	cameraCapture = nil;
	camInitialized = NO;
	
	//Clear the call timer
	[self.callTimer invalidate];
	self.callTimer = nil;
	
	
	//if the user is a patient, totally disable QB on exit
	if(![myQBPlugin getProviderStatus]){
		
		//set the CVC to nil
		//[myQBPlugin clearCVC];
		
		//Disable QBRTC
		[QBRTCClient deinitializeRTC];
		
		//log out of QB
		[[QBChat instance] disconnectWithCompletionBlock:nil];
		
		
		
	}
	
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	
	//return self.users.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	/*
	OpponentCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kOpponentCollectionViewCellIdentifier
																				 forIndexPath:indexPath];
	QBUUser *user = self.users[indexPath.row];
	
	[cell setVideoView:[self videoViewWithOpponentID:@(user.ID)]];
	NSString *markerText = [NSString stringWithFormat:@"%lu", (unsigned long)user.index + 1];
	[cell setColorMarkerText:markerText andColor:user.color];
	
	return cell;
	 */
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self.opponentsCollectionView performBatchUpdates:nil completion:nil];// Calling -performBatchUpdates:completion: will invalidate the layout and resize the cells with animation
}

- (CGSize)collectionView:(UICollectionView *)collectionView
				  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
/*
	CGRect frame = [OpponentsFlowLayout frameForWithNumberOfItems:self.users.count
															  row:indexPath.row
													  contentSize:self.opponentsCollectionView.frame.size];
	return frame.size;
 */
}

#pragma mark - Transition to size

- (NSIndexPath *)indexPathAtUserID:(NSNumber *)userID {
	/*
	QBUUser *user = [UsersDataSource.instance userWithID:userID];
	NSUInteger idx = [self.users indexOfObject:user];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
	
	return indexPath;
	 */
}
/*
- (void)performUpdateUserID:(NSNumber *)userID block:(void(^)(OpponentCollectionViewCell *cell))block {
	
	NSIndexPath *indexPath = [self indexPathAtUserID:userID];
	OpponentCollectionViewCell *cell = (id)[self.opponentsCollectionView cellForItemAtIndexPath:indexPath];
	block(cell);
}
 */

#pragma Statistic

NSInteger QBRTCGetCpuUsagePercentage() {
	// Create an array of thread ports for the current task.
	/*
	const task_t task = mach_task_self();
	thread_act_array_t thread_array;
	mach_msg_type_number_t thread_count;
	if (task_threads(task, &thread_array, &thread_count) != KERN_SUCCESS) {
		return -1;
	}
	
	// Sum cpu usage from all threads.
	float cpu_usage_percentage = 0;
	thread_basic_info_data_t thread_info_data = {};
	mach_msg_type_number_t thread_info_count;
	for (size_t i = 0; i < thread_count; ++i) {
		thread_info_count = THREAD_BASIC_INFO_COUNT;
		kern_return_t ret = thread_info(thread_array[i],
										THREAD_BASIC_INFO,
										(thread_info_t)&thread_info_data,
										&thread_info_count);
		if (ret == KERN_SUCCESS) {
			cpu_usage_percentage +=
			100.f * (float)thread_info_data.cpu_usage / TH_USAGE_SCALE;
		}
	}
	
	// Dealloc the created array.
	vm_deallocate(task, (vm_address_t)thread_array,
				  sizeof(thread_act_t) * thread_count);
	return lroundf(cpu_usage_percentage);
	 */
}

#pragma mark - QBRTCClientDelegate

- (void)session:(QBRTCSession *)session updatedStatsReport:(QBRTCStatsReport *)report forUserID:(NSNumber *)userID {
	
	NSMutableString *result = [NSMutableString string];
	NSString *systemStatsFormat = @"(cpu)%ld%%\n";
	[result appendString:[NSString stringWithFormat:systemStatsFormat,
						  (long)QBRTCGetCpuUsagePercentage()]];
	
	// Connection stats.
	NSString *connStatsFormat = @"CN %@ms | %@->%@/%@ | (s)%@ | (r)%@\n";
	[result appendString:[NSString stringWithFormat:connStatsFormat,
						  report.connectionRoundTripTime,
						  report.localCandidateType, report.remoteCandidateType, report.transportType,
						  report.connectionSendBitrate, report.connectionReceivedBitrate]];
	
	if (session.conferenceType == QBRTCConferenceTypeVideo) {
		
		// Video send stats.
		NSString *videoSendFormat = @"VS (input) %@x%@@%@fps | (sent) %@x%@@%@fps\n"
		"VS (enc) %@/%@ | (sent) %@/%@ | %@ms | %@\n";
		[result appendString:[NSString stringWithFormat:videoSendFormat,
							  report.videoSendInputWidth, report.videoSendInputHeight, report.videoSendInputFps,
							  report.videoSendWidth, report.videoSendHeight, report.videoSendFps,
							  report.actualEncodingBitrate, report.targetEncodingBitrate,
							  report.videoSendBitrate, report.availableSendBandwidth,
							  report.videoSendEncodeMs,
							  report.videoSendCodec]];
		
		// Video receive stats.
		NSString *videoReceiveFormat =
		@"VR (recv) %@x%@@%@fps | (decoded)%@ | (output)%@fps | %@/%@ | %@ms\n";
		[result appendString:[NSString stringWithFormat:videoReceiveFormat,
							  report.videoReceivedWidth, report.videoReceivedHeight, report.videoReceivedFps,
							  report.videoReceivedDecodedFps,
							  report.videoReceivedOutputFps,
							  report.videoReceivedBitrate, report.availableReceiveBandwidth,
							  report.videoReceivedDecodeMs]];
	}
	// Audio send stats.
	NSString *audioSendFormat = @"AS %@ | %@\n";
	[result appendString:[NSString stringWithFormat:audioSendFormat,
						  report.audioSendBitrate, report.audioSendCodec]];
	
	// Audio receive stats.
	NSString *audioReceiveFormat = @"AR %@ | %@ | %@ms | (expandrate)%@";
	[result appendString:[NSString stringWithFormat:audioReceiveFormat,
						  report.audioReceivedBitrate, report.audioReceivedCodec, report.audioReceivedCurrentDelay,
						  report.audioReceivedExpandRate]];
	
	NSLog(@"Amins stats: %@", result);
}

- (void)session:(QBRTCSession *)session initializedLocalMediaStream:(QBRTCMediaStream *)mediaStream {
	
	currentSession = session == currentSession ? currentSession : session;
	
	NSLog(@"I just started initializing the Local Media Stream");
	
	camInitialized = YES;
	
	myVideoLayer = cameraCapture.previewLayer;
	
	mediaStream.videoTrack.videoCapture = cameraCapture;
	
	[_v_videoout.layer insertSublayer:myVideoLayer atIndex:0];
	[_v_videoout.layer.sublayers objectAtIndex:0].frame = _v_videoout.bounds;
	
}
/**
 * Called in case when you are calling to user, but he hasn't answered
 */
/*
- (void)session:(QBRTCSession *)session userDoesNotRespond:(NSNumber *)userID {
	
	if (session == self.session) {
		
		[self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {
			cell.connectionState = [self.session connectionStateForUser:userID];
		}];
	}
}
 */

/*
- (void)session:(QBRTCSession *)session acceptedByUser:(NSNumber *)userID userInfo:(NSDictionary *)userInfo {
	
	if (session == self.session) {
		
		[self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {
			cell.connectionState = [self.session connectionStateForUser:userID];
		}];
	}
}
*/
/**
 * Called in case when opponent has rejected you call
 */

/*
- (void)session:(QBRTCSession *)session rejectedByUser:(NSNumber *)userID userInfo:(NSDictionary *)userInfo {
	
	if (session == self.session) {
		
		[self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {
			cell.connectionState = [self.session connectionStateForUser:userID];
		}];
	}
}
 
 */

/**
 *  Called in case when opponent hung up
 */

/*
- (void)session:(QBRTCSession *)session hungUpByUser:(NSNumber *)userID userInfo:(NSDictionary *)userInfo {
	
	if (session == self.session) {
		
		[self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {
			
			cell.connectionState = [self.session connectionStateForUser:userID];
		}];
	}
}
 */


- (void)didReceiveNewSession:(QBRTCSession *)session userInfo:(NSDictionary *)userInfo
{
	
	callStatus = @"PROCEEDING";
	currentSession = session;
	
}

/**
 *  Called in case when receive remote video track from opponent
 */

- (void)session:(QBRTCSession *)session receivedRemoteVideoTrack:(QBRTCVideoTrack *)videoTrack fromUser:(NSNumber *)userID {
	
	currentSession = session == currentSession ? currentSession : session;
	
	/*
	if (session == self.session) {
		
		[self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {
			
			QBRTCRemoteVideoView *opponentVideoView = (id)[self videoViewWithOpponentID:userID];
			[cell setVideoView:opponentVideoView];
		}];
	}
	 */
	
	NSLog(@"I am now receiving Remote video Track inside CVC from user: %@", userID);
	NSLog(@"My screen height is: %f , and my screen width is: %f", [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
	
	remoteVideoTrack = videoTrack;
	
	QBRTCRemoteVideoView *remoteVideoView = nil;
	remoteVideoView = [[QBRTCRemoteVideoView alloc] initWithFrame:self.view.bounds];
	[remoteVideoView setBackgroundColor:[UIColor blackColor]];
	NSLog(@"The default content mode is: %ld", (long)remoteVideoView.contentMode);
	remoteVideoView.contentMode = UIViewContentModeTop; //UIViewContentModeScaleAspectFill;
	NSLog(@"The changed content mode is: %ld", (long)remoteVideoView.contentMode);
	[remoteVideoView setVideoTrack:videoTrack];
	remoteVideoView.tag = 76;
	[self.view insertSubview:remoteVideoView aboveSubview:_v_videoin];
	[self.view insertSubview:_l_callTimer aboveSubview:remoteVideoView];

	//_v_videoin.contentMode = UIViewContentModeScaleAspectFit;
	//[_v_videoin setFrame:self.view.bounds];
	//[_v_videoin setVideoTrack:videoTrack];
	
}

/**
 *  Called in case when connection initiated
 */
- (void)session:(QBRTCSession *)session startedConnectionToUser:(NSNumber *)userID {
	/*
	if (session == self.session) {
		
		[self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {
			cell.connectionState = [self.session connectionStateForUser:userID];
		}];
	}
	 */
	
	NSLog(@"I'm in the call controller and noticed connection to: %@", userID);
	
	

}

/**
 *  Called in case when connection is established with opponent
 */
- (void)session:(QBRTCSession *)session connectedToUser:(NSNumber *)userID {
	
	NSLog(@">>> I am now connected to user");
	
	callStatus = @"ACTIVE";
	
	currentSession = session == currentSession ? currentSession : session;
	
	
	//Once connection finalized, make sure and put the camera captuere in the media stream
	
	currentSession.localMediaStream.videoTrack.videoCapture = cameraCapture;
	
	
	//Temporarily mute call for testing:
	//currentSession.localMediaStream.audioTrack.enabled = NO;
	
	//Now that call is ready, remove the coverview
	[coverView setHidden:YES];
	[coverView removeFromSuperview];
	[_v_callingview setHidden:YES];
	
	//Now that the call is connected, make sure sound route is correct
	if([QBRTCSoundRouter.instance isHeadsetPluggedIn] || [QBRTCSoundRouter.instance isBluetoothPluggedIn]){
		NSLog(@"Going to route sound through receiver");
		[QBRTCSoundRouter instance].currentSoundRoute = QBRTCSoundRouteReceiver;
		
	}else{
		NSLog(@"Going to route sound through speaker");
		[QBRTCSoundRouter instance].currentSoundRoute = QBRTCSoundRouteSpeaker;
	}
	
	//Forces audio to go through speaker at beginning of the call
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error: nil];
	
	//Start the CallTimer
	
	if (!self.callTimer) {
		
		self.callTimer = [NSTimer scheduledTimerWithTimeInterval:kRefreshTimeInterval
														  target:self
														selector:@selector(refreshCallTime:)
														userInfo:nil
														 repeats:YES];
	}
	
	
	
	/*
	NSParameterAssert(self.session == session);
	
	if (self.beepTimer) {
		
		[self.beepTimer invalidate];
		self.beepTimer = nil;
		[QMSysPlayer stopAllSounds];
	}
	
	if (!self.callTimer) {
		
		self.callTimer = [NSTimer scheduledTimerWithTimeInterval:kRefreshTimeInterval
														  target:self
														selector:@selector(refreshCallTime:)
														userInfo:nil
														 repeats:YES];
	}
	
	[self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {
		cell.connectionState = [self.session connectionStateForUser:userID];
	}];
	 */
}

- (void)session:(QBRTCSession *)session hungUpByUser:(NSNumber *)userID userInfo:(NSDictionary *)userInfo
{
	
	NSLog(@"The other user hung up first, so I need to exit. I'm in CVC");
	
	if(currentSession == session && [callStatus isEqualToString:@"ACTIVE"]){
		callStatus = @"ENDED";
		//[self cleanUP];
		
		
	}
	
}

/**
 *  Called in case when disconnected from opponent
 */
- (void)session:(QBRTCSession *)session disconnectedFromUser:(NSNumber *)userID {
	
	NSLog(@"Temporarily Disconnected. Waiting for reconnect");
	/*
	if (session == self.session) {
		
		[self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {
			cell.connectionState = [self.session connectionStateForUser:userID];
		}];
	}
	 */
}

/**
 *  Called in case when disconnected by timeout
 */
- (void)session:(QBRTCSession *)session disconnectedByTimeoutFromUser:(NSNumber *)userID {
	
	NSLog(@"Disconnected too long. Timeout reached");
	
	callStatus = @"ENDED";
	/*
	if (session == self.session) {
		
		[self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {
			cell.connectionState = [self.session connectionStateForUser:userID];
		}];
	}
	 */
	

	

}

/**
 *  Called in case when connection failed with user
 */
- (void)session:(QBRTCSession *)session connectionFailedWithUser:(NSNumber *)userID {
	/*
	if (session == self.session) {
		
		[self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {
			cell.connectionState = [self.session connectionStateForUser:userID];
		}];
	}
	 */
}


/**
 *  Called in case when connection state changed
 */
- (void)session:(QBRTCSession *)session connectionClosedForUser:(NSNumber *)userID {
	
	NSLog(@"Connection status changed either up or down");
		
		/*
		 [self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {
			cell.connectionState = [self.session connectionStateForUser:userID];
			[self.videoViews removeObjectForKey:userID];
			[cell setVideoView:nil];
		 }];
		 */
	
}


/**
 *  Called in case when session will close
 */
- (void)sessionDidClose:(QBRTCSession *)session {
	
	NSLog(@"Inside %s",__FUNCTION__);
	
	//Only do a full cleanup if the caller was already in an active call or was ended on purpose
	if (session == currentSession && ([callStatus isEqualToString:@"ACTIVE"] || [callStatus isEqualToString:@"ENDED"]) ) {
		
		[self cleanUP];

	}else{
		
		//The call did not go active, so just tell JS to got back to waiting room
		[myQBPlugin goBackToWaitJS];
		
	}
	
	//Turn off sound router
	[QBRTCSoundRouter.instance deinitialize];
	
	/*
	if (session == self.session) {
		
		[QBRTCSoundRouter.instance deinitialize];
		
		if (self.beepTimer) {
			
			[self.beepTimer invalidate];
			self.beepTimer = nil;
			[QMSysPlayer stopAllSounds];
		}
		
		[self.callTimer invalidate];
		self.callTimer = nil;
		
		self.toolbar.userInteractionEnabled = NO;
		//        self.localVideoView.hidden = YES;
		[UIView animateWithDuration:0.5 animations:^{
			
			self.toolbar.alpha = 0.4;
		}];
		
		self.title = [NSString stringWithFormat:@"End - %@", [self stringWithTimeDuration:self.timeDuration]];
	}
	 */
	
	
}


#pragma mark - Timers actions

- (void)playCallingSound:(id)sender {
	
	//    [QMSoundManager playCallingSound];
}

- (void)refreshCallTime:(NSTimer *)sender {
	
	self.timeDuration += kRefreshTimeInterval;
	_l_callTimer.text = [NSString stringWithFormat:@"Call Duration: %@", [self stringWithTimeDuration:self.timeDuration]];

}

- (NSString *)stringWithTimeDuration:(NSTimeInterval )timeDuration {
	
	NSInteger minutes = timeDuration / 60;
	NSInteger seconds = (NSInteger)timeDuration % 60;
	NSString *timeStr = [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];
	
	return timeStr;
}

//- (void)localVideoView:(LocalVideoView *)localVideoView pressedSwitchButton:(UIButton *)sender {
- (void)localVideoView:(UIView *)localVideoView pressedSwitchButton:(UIButton *)sender {
	AVCaptureDevicePosition position = [cameraCapture currentPosition];
	AVCaptureDevicePosition newPosition = position == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
	
	if ([cameraCapture hasCameraForPosition:newPosition]) {
		
		CATransition *animation = [CATransition animation];
		animation.duration = .5f;
		animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		animation.type = @"oglFlip";
		
		if (position == AVCaptureDevicePositionFront) {
			
			animation.subtype = kCATransitionFromRight;
		}
		else if(position == AVCaptureDevicePositionBack) {
			
			animation.subtype = kCATransitionFromLeft;
		}
		
		[localVideoView.superview.layer addAnimation:animation forKey:nil];
		
		[self.cameraCapture selectCameraPosition:newPosition];
	}
	 
}
 

- (IBAction)switchCam:(id)sender {
	
	AVCaptureDevicePosition position = [cameraCapture currentPosition];
	AVCaptureDevicePosition newPosition = position == AVCaptureDevicePositionFront ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
	//[self releaseButton:sender];
	[self resetHideTimer];
	// check whether videoCapture has or has not camera position
	// for example, some iPods do not have front camera
	if ([cameraCapture hasCameraForPosition:newPosition]) {
		[cameraCapture selectCameraPosition:newPosition];
	}
	
	if(newPosition == AVCaptureDevicePositionBack)
	{
		[_b_switch setBackgroundColor:[UIColor colorWithWhite:.7 alpha:.6]];
	}else{
		[_b_switch setBackgroundColor:[UIColor clearColor]];
	}
	
	[_v_videoout.layer insertSublayer:cameraCapture.previewLayer atIndex:10];
	
}

- (IBAction)toggleVideo:(id)sender {
	
	//[self releaseButton:sender];
	[self resetHideTimer];
	currentSession.localMediaStream.videoTrack.enabled = !currentSession.localMediaStream.videoTrack.isEnabled;
	
	if(!currentSession.localMediaStream.videoTrack.isEnabled)
		{
			[_b_video setBackgroundColor:[UIColor colorWithWhite:.7 alpha:.6]];
		}else{
			[_b_video setBackgroundColor:[UIColor clearColor]];
		}

}

- (IBAction)toggleMic:(id)sender {
	
	//[self releaseButton:sender];
	currentSession.localMediaStream.audioTrack.enabled = !currentSession.localMediaStream.audioTrack.isEnabled;
	
	[self resetHideTimer];
	
	if(!currentSession.localMediaStream.audioTrack.isEnabled){
		
		[_b_mic setBackgroundColor:[UIColor colorWithWhite:.7 alpha:.6]];
		
	}else{
		
		[_b_mic setBackgroundColor:[UIColor clearColor]];
		
	}
	
}

- (IBAction)hangup:(id)sender {
	
	//Hang up session in QBRTC
	NSLog(@"I am going to hang up session");
	[currentSession hangUp:nil];

}

- (IBAction)callinghangup:(id)sender {
	NSLog(@"I am hanging up before patient answers");
	
	if(currentSession){
		[currentSession hangUp:nil];
	}
	
	[self cleanUP];
	
}

- (IBAction)pressButton:(id)sender
{
	[sender setBackgroundColor:[UIColor colorWithWhite:1. alpha:.50]];
}

- (IBAction)releaseButton:(id)sender
{
	[UIView animateWithDuration:.3 animations:^{
		if (sender == [self b_hangup])
			{
			[sender setBackgroundColor:[UIColor colorWithRed:.66 green:.07 blue:.07 alpha:.6]];
			} else {
				[sender setBackgroundColor:[UIColor colorWithWhite:.67 alpha:.6]];
			}
	}];
}


- (void)resetHideTimer
{
	[callMenuHide invalidate];
	callMenuHide = [NSTimer scheduledTimerWithTimeInterval:3. target:self selector:@selector(hideTheMenu:) userInfo:nil repeats:NO];
}

- (void)hideTheMenu:(NSTimer *)timer
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[UIView animateWithDuration:.3 animations:^{
			[[self v_menubar] setAlpha:0.];
		}];
	});
		 

}



#pragma mark - View touches & swipes
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *d = [touches anyObject];
	if ([[d view] isDescendantOfView:[self view]])
		{
		dispatch_async(dispatch_get_main_queue(), ^{
			[[self v_menubar] setAlpha:1.];
		});
		}
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	
	UITouch *d = [touches anyObject];
	if ([[d view] isDescendantOfView:[self view]])
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[self resetHideTimer];
		
			});
		}
}

@end
