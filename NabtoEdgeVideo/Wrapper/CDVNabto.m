/*
 * Copyright (C) 2008-2016 Nabto - All Rights Reserved.
 */

#import "CDVNabto.h"
#import "Manager.h"
#import "AdViewController.h"
#import "AdManager.h"

@implementation CDVNabto 

#pragma mark Nabto API

- (void)startup:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
            CDVPluginResult* res = nil;
            nabto_status_t status = [[Manager sharedManager] nabtoStartup];
            if (status == NABTO_OK) {
                res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            } else {
                res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:status];
            }
            [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
        }];
}

- (void)startupAndOpenProfile:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* res = nil;

        nabto_status_t status = [[Manager sharedManager] nabtoStartup];
        if (status != NABTO_OK) {
            res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:status];
        } else {
            status = [[Manager sharedManager] nabtoOpenSession:[command.arguments objectAtIndex:0]
                                                  withPassword:[command.arguments objectAtIndex:1]];
            if (status == NABTO_OK) {
                res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            } else {
                NSLog(@"nabtoOpenSession failed with status [%d]", status);
                res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:status];
            }
        }
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
    }];
}

- (void)handleStatus:(nabto_status_t)status withCommand:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *res = nil;
    if (status == NABTO_OK) {
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:status];
    }
    [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
}

- (void)handleJsonError:(char*)jsonString withCommand:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                             messageAsString:[NSString stringWithUTF8String:jsonString]];
    [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
}

- (void)createKeyPair:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        nabto_status_t status = [[Manager sharedManager]
                                    nabtoCreateSelfSignedProfile:[command.arguments objectAtIndex:0]
                                                    withPassword:[command.arguments objectAtIndex:1]];
        [self handleStatus:status withCommand:command];
    }];
}

- (void)getFingerprint:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
            char fingerprint[16];
            CDVPluginResult *res = nil;
            nabto_status_t status = [[Manager sharedManager]
                                            nabtoGetFingerprint:[command.arguments objectAtIndex:0]
                                                     withResult:fingerprint];
            if (status == NABTO_OK) {
                char fingerprintString[2*sizeof(fingerprint)];
                for (size_t i=0; i<sizeof(fingerprint); i++) {
                    sprintf(fingerprintString+2*i, "%02x", (unsigned char)(fingerprint[i]));
                }
                NSData *data = [NSData dataWithBytes:fingerprintString length:sizeof(fingerprintString)];
                NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"Got fingerprint [%@]", str);
                res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                        messageAsString:str];
            } else {
                res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:status];
            }
            [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
        }];
}


- (void)shutdown:(CDVInvokedUrlCommand*)command {
    [[AdManager instance] clear];
    [self.commandDelegate runInBackground:^{
            nabto_status_t status = [[Manager sharedManager] nabtoShutdown];
            [self handleStatus:status withCommand:command];
    }];
}

- (void)fetchUrl:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *res = nil;

        nabto_status_t status;
        char *resultBuffer = 0;
        size_t resultLen = 0;
        char *resultMimeType = 0;

        status = [[Manager sharedManager] nabtoFetchUrl:[command.arguments objectAtIndex:0]
                                       withResultBuffer:&resultBuffer
                                           resultLength:&resultLen
                                               mimeType:&resultMimeType];
        if (status == NABTO_OK) {
            NSData *data = [NSData dataWithBytes:resultBuffer length:resultLen];
            res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                    messageAsString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
            nabtoFree(resultBuffer);
        } else {
            res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:status];
        }

        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
    }];
}

- (void)prepareInvoke:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *res = nil;
    NSString* jsonHosts = [command.arguments objectAtIndex:0];
    NSLog(@"Cordova prepareInvoke begins, jsonHosts=[%@], class=[%@]", jsonHosts, NSStringFromClass([jsonHosts class]));
    if ([[AdManager instance] addDevices:jsonHosts]) {
        if ([[AdManager instance] shouldShowAd]) {
            [self showAd];
            [[AdManager instance] confirmAdShown];
        }
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        NSLog(@"Invalid json array: [%@]", jsonHosts);
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:NABTO_FAILED];
    }
    [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
    NSLog(@"Cordova prepareInvoke ends");
}

- (void)doInvokeRpc:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *res = nil;
        NSLog(@"Cordova RPC invoke runInBackground ");
        nabto_status_t status;
        char *jsonString = 0;
        
        status = [[Manager sharedManager] nabtoRpcInvoke:[command.arguments objectAtIndex:0]
                                        withResultBuffer:&jsonString];
        if (status == NABTO_OK || status == NABTO_FAILED_WITH_JSON_MESSAGE) {
            int cdvStatus;
            if (status == NABTO_OK) {
                cdvStatus = CDVCommandStatus_OK;
            } else {
                cdvStatus = CDVCommandStatus_ERROR;
            }
            res = [CDVPluginResult resultWithStatus:cdvStatus
                                messageAsString:[NSString stringWithUTF8String:jsonString]];
            nabtoFree(jsonString);
        } else {
            res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:status];
        }
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
    }];
}

- (NSString*)createUnpreparedError:(NSString*)url {
    return [NSString stringWithFormat: 
                         @"{\"error\" : {"
                          "\"event\" : 2000068,"
                         "\"header\" : \"Unprepared device invoked\","
                           "\"body\" : \"rpcInvoke was called with unprepared device. prepareInvoke must be called before device can be invoked\","
                         "\"detail\" : \"%@\""
                     "}}", url];
}
        

- (void)rpcInvoke:(CDVInvokedUrlCommand*)command {
    NSString* url = [command.arguments objectAtIndex:0];
    NSLog(@"Cordova rpcInvoke begins, url=[%@], class=[%@]", url, NSStringFromClass([url class]));
    if ([[AdManager instance] isHostInUrlKnown:url]) {
        [self doInvokeRpc:command];
    } else {
        NSLog(@"Prepare not invoked for url %@", url);
        CDVPluginResult* res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                messageAsString:[self createUnpreparedError:url]];
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
    }
}

- (void)rpcSetDefaultInterface:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        nabto_status_t status;
        char *jsonString;
        status = [[Manager sharedManager] nabtoRpcSetDefaultInterface:[command.arguments objectAtIndex:0]
                                                     withErrorMessage:&jsonString];

        if (status == NABTO_FAILED_WITH_JSON_MESSAGE) {
            [self handleJsonError:jsonString withCommand:command];
            nabtoFree(jsonString);
        } else {
            [self handleStatus:status withCommand:command];
        }
    }];
}

- (void)rpcSetInterface:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        nabto_status_t status;
        char *jsonString = 0;
        status = [[Manager sharedManager] nabtoRpcSetInterface:[command.arguments objectAtIndex:0]
                                       withInterfaceDefinition:[command.arguments objectAtIndex:1]
                                              withErrorMessage:&jsonString];
        if (status == NABTO_FAILED_WITH_JSON_MESSAGE) {
            [self handleJsonError:jsonString withCommand:command];
            nabtoFree(jsonString);
        } else {
            [self handleStatus:status withCommand:command];
        }
    }];
}

- (void)getSessionToken:(CDVInvokedUrlCommand*)command {
    NSString *token = [[Manager sharedManager] nabtoGetSessionToken];
    CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:token];
    [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
}

- (void)getLocalDevices:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        NSArray *devices = [[Manager sharedManager] nabtoGetLocalDevices];
        CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:devices];
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
    }];
}

- (void)version:(CDVInvokedUrlCommand*)command {
    NSString *version = [[Manager sharedManager] nabtoVersion];
    CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:version];
    [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
}

#pragma mark Nabto Tunnel API

- (void)tunnelOpenTcp:(CDVInvokedUrlCommand*)command {
    CDVPluginResult *res = nil;
    
    nabto_status_t status = [[Manager sharedManager] nabtoTunnelOpenTcp:[command.arguments objectAtIndex:0] onPort:[[command.arguments objectAtIndex:1] intValue]];
    if (status == NABTO_OK) {
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:status];
    }
    
    [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
}

- (void)tunnelVersion:(CDVInvokedUrlCommand*)command {
    int version = [[Manager sharedManager] nabtoTunnelVersion];
    CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:version];
    [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
}

- (void)tunnelState:(CDVInvokedUrlCommand*)command {
    nabto_tunnel_state_t state = [[Manager sharedManager] nabtoTunnelInfo];
    CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:state];
    [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
}

- (void)tunnelLastError:(CDVInvokedUrlCommand*)command {
    nabto_status_t status = [[Manager sharedManager] nabtoTunnelError];
    CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:status];
    [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
}

- (void)tunnelPort:(CDVInvokedUrlCommand*)command {
    int port = [[Manager sharedManager] nabtoTunnelPort];
    CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:port];
    [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
}

- (void)tunnelClose:(CDVInvokedUrlCommand*)command {
    nabto_status_t status = [[Manager sharedManager] nabtoTunnelClose];
    [self handleStatus:status withCommand:command];
}

- (void)showAd {
    @synchronized (self) {
        if(![self isShowingAd]) {
           self.showingAd = YES; 
           AdViewController* avc = [[AdViewController alloc] init];
           avc.CDV=self;
           [[self topMostController] presentViewController:avc animated:YES completion:nil];
        } else {
           NSLog(@"Not showing add.. already showing");
        }
    }
    
}

- (UIViewController*) topMostController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;

    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }

    return topController;
}

@end
