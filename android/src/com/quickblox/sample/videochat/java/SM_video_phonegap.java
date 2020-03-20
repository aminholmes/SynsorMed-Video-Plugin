package com.quickblox.sample.videochat.java; import com.synsormed.mobile.R;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.List;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.FragmentManager;
import android.content.Context;
import android.content.Intent;
import android.content.res.Resources;
import android.media.AudioManager;
import android.os.Build;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.FrameLayout.LayoutParams;
import android.telephony.TelephonyManager;

import com.quickblox.videochat.webrtc.view.QBRTCVideoTrack;
import com.quickblox.auth.session.QBSettings;
import com.quickblox.core.QBEntityCallback;
import com.quickblox.core.exception.QBResponseException;
import com.quickblox.core.*;
import com.quickblox.users.model.QBUser;
import com.quickblox.users.QBUsers;
import com.quickblox.auth.QBAuth;
// import com.quickblox.auth.model.QBSession;
import com.quickblox.chat.QBChatService;
import com.quickblox.chat.QBSignaling;
import com.quickblox.chat.QBWebRTCSignaling;
import com.quickblox.chat.listeners.QBVideoChatSignalingManagerListener;
import com.quickblox.videochat.webrtc.AppRTCAudioManager;
import com.quickblox.videochat.webrtc.QBRTCClient;
import com.quickblox.videochat.webrtc.QBRTCConfig;
import com.quickblox.videochat.webrtc.QBRTCSession;
import com.quickblox.videochat.webrtc.QBRTCTypes;
import com.quickblox.videochat.webrtc.QBSignalingSpec;
import com.quickblox.videochat.webrtc.callbacks.QBRTCClientSessionCallbacks;
import com.quickblox.videochat.webrtc.callbacks.QBRTCClientVideoTracksCallbacks;
import com.quickblox.videochat.webrtc.callbacks.QBRTCSessionConnectionCallbacks;
import com.quickblox.videochat.webrtc.callbacks.QBRTCSignalingCallback;
import com.quickblox.videochat.webrtc.callbacks.QBRTCStatsReportCallback;
import com.quickblox.videochat.webrtc.exception.QBRTCException;
import com.quickblox.videochat.webrtc.exception.QBRTCSignalException;
import com.quickblox.videochat.webrtc.callbacks.QBRTCClientVideoTracksCallbacks;

import com.quickblox.sample.videochat.java.util.QBResRequestExecutor;
import com.quickblox.sample.videochat.java.utils.WebRtcSessionManager;

// import com.quickblox.sample.groupchatwebrtc.activities.CallActivity;




/**
 *	Core plugin of the app.
 */
public class SM_video_phonegap extends CordovaPlugin {

	/**	Callback linked to connection events */
	private CallbackContext connectionCallback = null;
	/**	Callback linked to authentication events */
	private CallbackContext authenticationCallback = null;
	/**	Callback linked to callWindow events */
	private CallbackContext callWindowCallback = null;
    private CallbackContext createCallCallback = null;
	private  static Boolean isProvider=false;
	private  static Boolean isDataAvailable=false;

	/**	Callback map containing their status */
	private Map<String, CallbackContext> statusCallbacks = new HashMap<String, CallbackContext>();

	/** The AudioManager allows us to detect the speaker mode and the wired headset mode */
	private AudioManager audioManager;
	
	static final String APP_ID = "41633";
	static final String AUTH_KEY = "YKQGUMXRvwtK9kf";
	static final String AUTH_SECRET = "ND-eQkQxAYAUYpM";
	static final String ACCOUNT_KEY = "Ky2eW7fR2tqfoDzxgZB1";
	private QBChatService chatService;
	private QBRTCClient rtcClient;
	private QBRTCSession currentSession;
    private int currentPatientID;
    private boolean hasRemoteTrack = false;
    private boolean hasLocalTrack = false;
    private static QBRTCVideoTrack currentLocalTrack =  null;
    private static QBRTCVideoTrack currentRemoteTrack = null;


    private QBResRequestExecutor requestExecutor; 

    
		

	/**	Custom Exception */
	@SuppressWarnings("serial")
	private static class DirectError extends Exception {
		/** The code value */
		int code;

		/**
		 * Default constructor with supplied code
		 * @param code .
		 */
		public DirectError(int code) {
			this.code = code;
		}

		/** @return the code value */
		public int getCode() {
			return code;
		}
	}

	@Override
	public void initialize(CordovaInterface cordova, CordovaWebView webView) {
		super.initialize(cordova, webView);

		requestExecutor = new QBResRequestExecutor();

		/*Rtcc.ensureNativeLoad();

		Rtcc.eventBus().register(this);

		audioManager = (AudioManager) cordova.getActivity().getSystemService(Context.AUDIO_SERVICE);*/
	}


	@Override
	public void onDestroy() {

	/*****Commented because we don't use Rtcc engine anymore. Was causing error: Amin 10/10/16
	
        if (Rtcc.getEngineStatus() != RtccEngine.Status.UNDEFINED.UNDEFINED) {
            Log.d("AminLog","About to disconnect RTCC on destroy");
            Rtcc.instance().disconnect();
        }

		Rtcc.eventBus().unregister(this);
	*/
		
		super.onDestroy();
	}

	@Override
	public boolean execute(String action, CordovaArgs args, CallbackContext callback) throws JSONException {
		Log.d("AminLog", "The string action is: " + action);
		Log.d("call_session", "The string action is: " + action);
		try {
			Log.d("call_session", " entered try");
			if ("initQB".equals(action))
				initQB(callback, args.getString(0));
			else if ("authent".equals(action)){	
				authent(callback, args.getString(0));
			}/*
			else if ("acceptCall".equals(action)){
				acceptCall(callback);
			}
			else if ("setDisplayName".equals(action))
				setDisplayName(callback, args.getString(0));
			else if ("getStatus".equals(action))
				getStatus(callback, args.getString(0));
			else if ("createCall".equals(action))
			{
				isProvider=args.getBoolean(1);
				isDataAvailable=args.getBoolean(2);
				if(args.getBoolean(1))
				{
					Log.d("provider", "video screen is in use by provider");
				}
				else
				{
					Log.d("provider", "Video Screen is in use by patient.");
				}
				if(args.getBoolean(2))
				{
					Log.d("provider", "patient data is available");
				}
				else
				{
					Log.d("provider", "patient data is not available.");
				}
				createCall(callback, args.getString(0));
			}
			else if ("disconnect".equals(action))
				disconnect(callback);
			else if ("muteOut".equals(action))
				muteOut(callback, args.getInt(0), args.getBoolean(1));
			else if ("resume".equals(action))
			{
				if(args.getBoolean(1))
				{
					Log.d("patientInResume", "video screen is in use by provider");
				}
				else
				{
					Log.d("patientInResume", "Video Screen is in use by patient.");
				}
				isProvider=args.getBoolean(1);
				resume(callback, args.getInt(0));
			}
				
			else if ("hangup".equals(action)){
				Log.d("call_session", "hangup short entered");
				hangup(callback, args.getInt(0));
			}

			else if ("hangUp".equals(action)){
				Log.d("call_session", "hangUp entered");
				final Activity activity = cordova.getActivity();
				final CallbackContext callbackLocal = callback;
				final CordovaArgs argsLocal = args;
				Log.d("AminLog", "Amin is in the display Call Window");


				int callId = 0;
				try
				{
					callId = argsLocal.getInt(0);
				}
				catch(Exception e){
					Log.d("call_session", "argsLocal callid issue");
				}

				final int  callIdFinal = callId;
				activity.runOnUiThread(new Runnable() {
					@Override public void run() {
						hangup(callbackLocal, callIdFinal);
					}
				});
			}

			else if ("displayCallWindow".equals(action))
			{
				// displayCallWindow(callback, args.getInt(0), args.getBoolean(1));
				addCallContainer(args.getInt(0));
			}
			else if ("displayCallView".equals(action))
				displayCallView(callback, args.getInt(0));
			else if ("hideCallView".equals(action))
				hideCallView(callback);
			else if ("setAudioRoute".equals(action))
				setAudioRoute(callback, args.getBoolean(0));
			else if ("getOSInfos".equals(action))
				getOSInfos(callback);
            else if ("getEngineStatus".equals(action))
                getEngineStatus(callback);
            else if ("getNetworkType".equals(action)){
				getNetworkType(callback);
			}*/
			else
				return false;
		}
		catch (DirectError e) {
			Log.d("call_session", "DirectError =?>" + e);
			callback.error(e.getCode());
		}
		return true;
	}

	private void initQB(CallbackContext callback, String appId) throws DirectError{

		 connectionCallback = callback;
        
        Log.d("AminLog", "I made it to initQB");
		Log.d("call_session", "initQB");
        
		QBSettings.getInstance().init(this.cordova.getActivity().getApplicationContext(), APP_ID, AUTH_KEY, AUTH_SECRET);
		QBSettings.getInstance().setAccountKey(ACCOUNT_KEY);

		callback.success();
	}

	private void authent(CallbackContext callback, String userID) throws DirectError {
		Log.d("AminLog","I am about to authenticate");
		Log.d("call_session", "authent");
        authenticationCallback = callback;
        loginQBUser(userID);

	}
	/**
	*
	* Log in the QB user
	*
	**/
	
	private void loginQBUser(String loginID){
	
		String login = loginID;
		String password = login.concat("password"); 
 
		QBUser user = null;
        user = new QBUser();
        user.setLogin(login);
        user.setPassword(password);


        Log.d("AminLog", "SignIn Started");
        requestExecutor.signInUser(user, new QBEntityCallbackImpl<QBUser>() {
            @Override
            public void onSuccess(QBUser user, Bundle params) {
                Log.d("AminLog", "SignIn Successful");
                initQBRTCClient();
				authenticationCallback.success();
            }

            @Override
            public void onError(QBResponseException responseException) {
                Log.d("AminLog","Failed logging into QB chat");
				String errorString = "";
				for (String s : responseException.getErrors())
					{
					errorString += s + "\t";
					}
				authenticationCallback.error(errorString);
            }
        });
	
	}

	private void initQBRTCClient() {
        rtcClient = QBRTCClient.getInstance(this.cordova.getActivity().getApplicationContext());
        // Add signalling manager
        chatService.getVideoChatWebRTCSignalingManager().addSignalingManagerListener(new QBVideoChatSignalingManagerListener() {
            @Override
            public void signalingCreated(QBSignaling qbSignaling, boolean createdLocally) {
                if (!createdLocally) {
                    rtcClient.addSignaling((QBWebRTCSignaling) qbSignaling);
                }
            }
        });

        // Configure
        QBRTCConfig.setDebugEnabled(true);
        //SettingsUtil.configRTCTimers(LoginService.this);

        // Add service as callback to RTCClient
        rtcClient.addSessionCallbacksListener(WebRtcSessionManager.getInstance(this.cordova.getActivity().getApplicationContext()));
        rtcClient.prepareToProcessCalls();
    }





}
