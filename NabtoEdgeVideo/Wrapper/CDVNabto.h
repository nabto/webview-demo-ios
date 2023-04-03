/*
 * Copyright (C) 2008-2016 Nabto - All Rights Reserved.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>
#import "IsShowingAd.h"

@interface CDVNabto : CDVPlugin <IsShowingAd> { 
}


@property (atomic, assign, getter=isShowingAd) BOOL showingAd;

/* Nabto API */
- (void)startup:(CDVInvokedUrlCommand*)command;
- (void)shutdown:(CDVInvokedUrlCommand*)command;
- (void)createKeyPair:(CDVInvokedUrlCommand*)command;
- (void)getFingerprint:(CDVInvokedUrlCommand*)command;
- (void)rpcSetDefaultInterface:(CDVInvokedUrlCommand*)command;
- (void)rpcSetInterface:(CDVInvokedUrlCommand*)command;
- (void)rpcInvoke:(CDVInvokedUrlCommand*)command;
- (void)prepareInvoke:(CDVInvokedUrlCommand*)command;
- (void)fetchUrl:(CDVInvokedUrlCommand*)command;
- (void)getSessionToken:(CDVInvokedUrlCommand*)command;
- (void)getLocalDevices:(CDVInvokedUrlCommand*)command;
- (void)version:(CDVInvokedUrlCommand*)command;

/* Nabto Tunnel API */
- (void)tunnelOpenTcp:(CDVInvokedUrlCommand*)command;
- (void)tunnelVersion:(CDVInvokedUrlCommand*)command;
- (void)tunnelState:(CDVInvokedUrlCommand*)command;
- (void)tunnelLastError:(CDVInvokedUrlCommand*)command;
- (void)tunnelPort:(CDVInvokedUrlCommand*)command;
- (void)tunnelClose:(CDVInvokedUrlCommand*)command;

/* Ad functionallity */
- (void)showAd;
- (UIViewController*) topMostController;


@end
