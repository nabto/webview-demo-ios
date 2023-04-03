/*
 * Copyright (C) 2008-2016 Nabto - All Rights Reserved.
 */

#import <Foundation/Foundation.h>
#import "nabto_client_api.h"

#define NABTO_ORANGE [UIColor colorWithRed:1.0 green:0.5 blue:0 alpha:1.0f]
#define NABTO_ORANGE_TRANSPARENT [UIColor colorWithRed:1.0 green:0.5 blue:0 alpha:0.3f]

@interface Manager : NSObject {
    BOOL initialized;
}

@property (nonatomic, assign)nabto_handle_t session;
@property (nonatomic, assign)nabto_tunnel_t tunnel;

- (nabto_status_t)nabtoStartup;
- (nabto_status_t)nabtoShutdown;

- (NSString *)nabtoVersion;

- (nabto_status_t)nabtoCreateSelfSignedProfile:(NSString *)email withPassword:(NSString *)password;
- (nabto_status_t)nabtoGetFingerprint:(NSString *)certificateId withResult:(char[16])result;

- (nabto_status_t)nabtoOpenSession:(NSString *)email withPassword:(NSString *)password;
- (nabto_status_t)nabtoOpenSessionGuest;
- (nabto_status_t)nabtoCloseSession;

- (nabto_status_t)nabtoFetchUrl:(NSString *)url withResultBuffer:(char **)resultBuffer resultLength:(size_t *)resultLength mimeType:(char **)mimeType;
- (nabto_status_t)nabtoSubmitPostData:(NSString *)url withBuffer:(NSString *)postBuffer resultBuffer:(char **)resultBuffer resultLength:(size_t *)resultLen mimeType:(char **)mimeType;

- (nabto_status_t)nabtoRpcInvoke:(NSString *)url withResultBuffer:(char **)jsonResponse;
- (nabto_status_t)nabtoRpcSetDefaultInterface:(NSString *)interfaceDefinition withErrorMessage:(char **)errorMessage;
- (nabto_status_t)nabtoRpcSetInterface:(NSString *)host withInterfaceDefinition:(NSString *)interfaceDefinition withErrorMessage:(char **)errorMessage;
                             
- (NSArray *)nabtoGetLocalDevices;
- (NSString *)nabtoGetSessionToken;

- (nabto_status_t)nabtoTunnelOpenTcp:(NSString *)host onPort:(int)port;
- (nabto_status_t)nabtoTunnelOpenTcp:(nabto_tunnel_t *)handle toHost:(NSString *)host onPort:(int)port;
- (int)nabtoTunnelVersion;
- (int)nabtoTunnelVersion:(nabto_tunnel_t)handle;
- (nabto_tunnel_state_t)nabtoTunnelInfo;
- (nabto_tunnel_state_t)nabtoTunnelInfo:(nabto_tunnel_t)handle;
- (nabto_status_t)nabtoTunnelError;
- (nabto_status_t)nabtoTunnelError:(nabto_tunnel_t)handle;
- (int)nabtoTunnelPort;
- (int)nabtoTunnelPort:(nabto_tunnel_t)handle;
- (nabto_status_t)nabtoTunnelClose;
- (nabto_status_t)nabtoTunnelClose:(nabto_tunnel_t)handle;

- (nabto_status_t)nabtoFree:(void *)p;

+ (id)sharedManager;
+ (NSString *)nabtoStatusString:(nabto_status_t)status;
+ (NSString *)nabtoTunnelInfoString:(nabto_tunnel_state_t)status;

@end
