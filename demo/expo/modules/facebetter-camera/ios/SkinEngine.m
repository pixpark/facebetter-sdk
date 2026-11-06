#import "SkinEngine.h"

#import <Facebetter/FBBeautyEffectEngine.h>

@implementation SkinEngine {
  NSLock *_lock;
  FBBeautyEffectEngine *_engine;
  FBEngineCallbacks *_callbacks;
  BOOL _ready;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _lock = [[NSLock alloc] init];
  }
  return self;
}

- (void)start:(void (^)(NSString *status))onStatus {
  [_lock lock];
  if (_engine != nil) {
    [_lock unlock];
    return;
  }

  FBLogConfig *log = [[FBLogConfig alloc] init];
  log.consoleEnabled = YES;
  log.fileEnabled = NO;
  log.level = FBLogLevel_Info;
  [FBBeautyEffectEngine setLogConfig:log];

  FBEngineConfig *config = [[FBEngineConfig alloc] init];
  config.appId = @"dddb24155fd045ab9c2d8aad83ad3a4a";
  config.appKey = @"-VINb6KRgm5ROMR6DlaIjVBO9CDvwsxRopNvtIbUyLc";

  FBBeautyEffectEngine *created = [FBBeautyEffectEngine createEngineWithConfig:config];
  if (created == nil) {
    _ready = NO;
    [_lock unlock];
    if (onStatus) {
      onStatus(@"initFailed");
    }
    return;
  }

  __weak SkinEngine *weakSelf = self;
  _callbacks = [[FBEngineCallbacks alloc] init];
  _callbacks.onEngineEvent = ^(FBEngineEventCode code, NSString *_Nullable message) {
    SkinEngine *strongSelf = weakSelf;
    if (strongSelf == nil) {
      return;
    }
    NSString *status = nil;
    BOOL ready = strongSelf->_ready;
    switch (code) {
      case FBEngineEventCodeLicenseValidationSuccess:
      case FBEngineEventCodeInitializationComplete:
        ready = YES;
        status = @"ready";
        break;
      case FBEngineEventCodeLicenseValidationFailed:
        ready = NO;
        status = @"authFailed";
        break;
      case FBEngineEventCodeInitializationFailed:
        ready = NO;
        status = @"initFailed";
        break;
      default:
        return;
    }
    [strongSelf->_lock lock];
    strongSelf->_ready = ready;
    [strongSelf->_lock unlock];
    if (onStatus) {
      onStatus(status);
    }
  };
  [created setCallbacks:_callbacks];
  [created setSmoothingStyle:FBSmoothingStyle_Natural];
  _engine = created;
  _ready = YES;
  [_lock unlock];
  if (onStatus) {
    onStatus(@"ready");
  }
}

- (void)applySmoothing:(float)smoothing
             whitening:(float)whitening
              rosiness:(float)rosiness
               blemish:(float)blemish
               clarity:(float)clarity
              skinOnly:(BOOL)skinOnly {
  [_lock lock];
  FBBeautyEffectEngine *current = _ready ? _engine : nil;
  [_lock unlock];
  if (current == nil) {
    return;
  }
  [current setSmoothing:smoothing];
  [current setWhitening:whitening];
  [current setRosiness:rosiness];
  [current setBlemish:blemish];
  [current setClarity:clarity];
  [current setBeautySkinOnly:skinOnly];
}

- (uint32_t)processTexture:(uint32_t)texture width:(int)width height:(int)height {
  [_lock lock];
  FBBeautyEffectEngine *current = _engine;
  BOOL ready = _ready;
  [_lock unlock];
  if (current == nil || !ready || texture == 0 || width <= 0 || height <= 0) {
    return texture;
  }
  FBImageFrame *input = [FBImageFrame createWithTexture:texture width:width height:height stride:width * 4];
  if (input == nil) {
    return texture;
  }
  input.type = FBFrameTypeVideo;
  FBImageFrame *output = [current processImage:input];
  uint32_t outputTexture = output != nil ? [output texture] : 0;
  return outputTexture != 0 ? outputTexture : texture;
}

- (void)releaseEngine {
  [_lock lock];
  _engine = nil;
  _callbacks = nil;
  _ready = NO;
  [_lock unlock];
}

@end
