#import "RNSound.h"

#if __has_include("RCTUtils.h")
#import "RCTUtils.h"
#else
#import <React/RCTUtils.h>
#endif
#import <React/RCTConvert.h>

NSString *const outputPhone = @"Phone";
NSString *const outputPhoneSpeaker = @"Phone Speaker";
NSString *const outputBluetooth = @"Bluetooth";
NSString *const outputHeadphones = @"Headphones";

@implementation RNSound {
    NSMutableDictionary *_playerPool;
    NSMutableDictionary *_callbackPool;
}

@synthesize _key = _key;

- (void)audioSessionChangeObserver:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    AVAudioSessionRouteChangeReason audioSessionRouteChangeReason =
        [userInfo[@"AVAudioSessionRouteChangeReasonKey"] longValue];
    AVAudioSessionInterruptionType audioSessionInterruptionType =
        [userInfo[@"AVAudioSessionInterruptionTypeKey"] longValue];
    AVAudioPlayer *player = [self playerForKey:self._key];
    if (audioSessionInterruptionType == AVAudioSessionInterruptionTypeEnded) {
        if (player && player.isPlaying) {
            [player play];
        }
    }
    if (audioSessionRouteChangeReason ==
        AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        if (player) {
            [player pause];
        }
    }
    if (audioSessionInterruptionType == AVAudioSessionInterruptionTypeBegan) {
        if (player) {
            [player pause];
        }
    }
}

- (NSMutableDictionary *)playerPool {
    if (!_playerPool) {
        _playerPool = [NSMutableDictionary new];
    }
    return _playerPool;
}

- (NSMutableDictionary *)callbackPool {
    if (!_callbackPool) {
        _callbackPool = [NSMutableDictionary new];
    }
    return _callbackPool;
}

- (AVAudioPlayer *)playerForKey:(nonnull NSNumber *)key {
    return [[self playerPool] objectForKey:key];
}

- (NSNumber *)keyForPlayer:(nonnull AVAudioPlayer *)player {
    return [[[self playerPool] allKeysForObject:player] firstObject];
}

- (RCTResponseSenderBlock)callbackForKey:(nonnull NSNumber *)key {
    return [[self callbackPool] objectForKey:key];
}

- (NSString *)getDirectory:(int)directory {
    return [NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask,
                                                YES) firstObject];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
                       successfully:(BOOL)flag {
    @synchronized(self) {
        NSNumber *key = [self keyForPlayer:player];
        if (key == nil)
            return;

        [self setOnPlay:NO forPlayerKey:key];
        RCTResponseSenderBlock callback = [self callbackForKey:key];
        if (callback) {
            callback(
                [NSArray arrayWithObjects:[NSNumber numberWithBool:flag], nil]);
            [[self callbackPool] removeObjectForKey:key];
        }
    }
}

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents {
    return [NSArray arrayWithObjects:@"onPlayChange", nil];
}

- (NSDictionary *)constantsToExport {
    return [NSDictionary
        dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"IsAndroid",
                                     [[NSBundle mainBundle] bundlePath],
                                     @"MainBundlePath",
                                     [self getDirectory:NSDocumentDirectory],
                                     @"NSDocumentDirectory",
                                     [self getDirectory:NSLibraryDirectory],
                                     @"NSLibraryDirectory",
                                     [self getDirectory:NSCachesDirectory],
                                     @"NSCachesDirectory", nil];
}

RCT_EXPORT_METHOD(enable : (BOOL)enabled) {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryAmbient error:nil];
    [session setActive:enabled error:nil];
}

RCT_EXPORT_METHOD(setActive : (BOOL)active) {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:active error:nil];
}

RCT_EXPORT_METHOD(setMode : (NSString *)modeName) {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSString *mode = nil;

    if ([modeName isEqual:@"Default"]) {
        mode = AVAudioSessionModeDefault;
    } else if ([modeName isEqual:@"VoiceChat"]) {
        mode = AVAudioSessionModeVoiceChat;
    } else if ([modeName isEqual:@"VideoChat"]) {
        mode = AVAudioSessionModeVideoChat;
    } else if ([modeName isEqual:@"GameChat"]) {
        mode = AVAudioSessionModeGameChat;
    } else if ([modeName isEqual:@"VideoRecording"]) {
        mode = AVAudioSessionModeVideoRecording;
    } else if ([modeName isEqual:@"Measurement"]) {
        mode = AVAudioSessionModeMeasurement;
    } else if ([modeName isEqual:@"MoviePlayback"]) {
        mode = AVAudioSessionModeMoviePlayback;
    } else if ([modeName isEqual:@"SpokenAudio"]) {
        mode = AVAudioSessionModeSpokenAudio;
    }

    if (mode) {
        [session setMode:mode error:nil];
    }
}

RCT_EXPORT_METHOD(setCategory
                  : (NSString *)categoryName mixWithOthers
                  : (BOOL)mixWithOthers) {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSString *category = nil;

    if ([categoryName isEqual:@"Ambient"]) {
        category = AVAudioSessionCategoryAmbient;
    } else if ([categoryName isEqual:@"SoloAmbient"]) {
        category = AVAudioSessionCategorySoloAmbient;
    } else if ([categoryName isEqual:@"Playback"]) {
        category = AVAudioSessionCategoryPlayback;
    } else if ([categoryName isEqual:@"Record"]) {
        category = AVAudioSessionCategoryRecord;
    } else if ([categoryName isEqual:@"PlayAndRecord"]) {
        category = AVAudioSessionCategoryPlayAndRecord;
    }
#if TARGET_OS_IOS
    else if ([categoryName isEqual:@"AudioProcessing"]) {
        category = AVAudioSessionCategoryAudioProcessing;
    }
#endif
    else if ([categoryName isEqual:@"MultiRoute"]) {
        category = AVAudioSessionCategoryMultiRoute;
    }

    if (category) {
        if (mixWithOthers) {
            [session setCategory:category
                     withOptions:AVAudioSessionCategoryOptionMixWithOthers
                           error:nil];
        } else {
            [session setCategory:category error:nil];
        }
    }
}

RCT_EXPORT_METHOD(enableInSilenceMode : (BOOL)enabled) {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:enabled error:nil];
}

RCT_EXPORT_METHOD(prepare
                  : (NSString *)fileName withKey
                  : (nonnull NSNumber *)key withOptions
                  : (NSDictionary *)options withCallback
                  : (RCTResponseSenderBlock)callback) {
    NSError *error;
    NSURL *fileNameUrl;
    AVAudioPlayer *player;

    if ([fileName hasPrefix:@"http"]) {
        fileNameUrl = [NSURL URLWithString:fileName];
        NSData *data = [NSData dataWithContentsOfURL:fileNameUrl];
        player = [[AVAudioPlayer alloc] initWithData:data error:&error];
    } else if ([fileName hasPrefix:@"ipod-library://"]) {
        fileNameUrl = [NSURL URLWithString:fileName];
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileNameUrl
                                                        error:&error];
    } else {
        fileNameUrl = [NSURL URLWithString:fileName];
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileNameUrl
                                                        error:&error];
    }

    if (player) {
        @synchronized(self) {
            player.delegate = self;
            player.enableRate = YES;
            [player prepareToPlay];
            [[self playerPool] setObject:player forKey:key];
            callback([NSArray
                arrayWithObjects:[NSNull null],
                                 [NSDictionary
                                     dictionaryWithObjectsAndKeys:
                                         [NSNumber
                                             numberWithDouble:player.duration],
                                         @"duration",
                                         [NSNumber numberWithUnsignedInteger:
                                                       player.numberOfChannels],
                                         @"numberOfChannels", nil],
                                 nil]);
        }
    } else {
        callback([NSArray arrayWithObjects:RCTJSErrorFromNSError(error), nil]);
    }
}

RCT_EXPORT_METHOD(play: (NSDictionary *)options
                  : (nonnull NSNumber *)key withCallback
                  : (RCTResponseSenderBlock)callback) {
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(audioSessionChangeObserver:)
               name:AVAudioSessionRouteChangeNotification
             object:nil];
    self._key = key;
    AVAudioPlayer *player = [self playerForKey:key];
    if (player) {
        [[self callbackPool] setObject:[callback copy] forKey:key];
        NSString *output = [RCTConvert NSString:options[@"output"]];
        [self setAudioOutput:output];
        [player play];
        [self setOnPlay:YES forPlayerKey:key];
    }
}

- (void)setAudioOutput:(NSString *)output {
    NSLog(@"output %@",output);
  if([output isEqualToString:outputPhoneSpeaker]){
    printf("OutputPhoneSpeaker");
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];

  } else if ([output isEqualToString:outputPhone]){
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    printf("OutputPhone");
  } else {
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
  }
}

RCT_EXPORT_METHOD(pause
                  : (nonnull NSNumber *)key withCallback
                  : (RCTResponseSenderBlock)callback) {
    AVAudioPlayer *player = [self playerForKey:key];
    if (player) {
        [player pause];
        callback([NSArray array]);
    }
}

RCT_EXPORT_METHOD(stop
                  : (nonnull NSNumber *)key withCallback
                  : (RCTResponseSenderBlock)callback) {
    AVAudioPlayer *player = [self playerForKey:key];
    if (player) {
        [player stop];
        player.currentTime = 0;
        callback([NSArray array]);
    }
}

RCT_EXPORT_METHOD(release : (nonnull NSNumber *)key) {
    @synchronized(self) {
        AVAudioPlayer *player = [self playerForKey:key];
        if (player) {
            [player stop];
            [[self callbackPool] removeObjectForKey:key];
            [[self playerPool] removeObjectForKey:key];
            NSNotificationCenter *notificationCenter =
                [NSNotificationCenter defaultCenter];
            [notificationCenter removeObserver:self];
        }
    }
}

RCT_EXPORT_METHOD(setVolume
                  : (nonnull NSNumber *)key withValue
                  : (nonnull NSNumber *)value) {
    AVAudioPlayer *player = [self playerForKey:key];
    if (player) {
        player.volume = [value floatValue];
    }
}

RCT_EXPORT_METHOD(getSystemVolume : (RCTResponseSenderBlock)callback) {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    callback(@[ @(session.outputVolume) ]);
}

RCT_EXPORT_METHOD(setPan
                  : (nonnull NSNumber *)key withValue
                  : (nonnull NSNumber *)value) {
    AVAudioPlayer *player = [self playerForKey:key];
    if (player) {
        player.pan = [value floatValue];
    }
}

RCT_EXPORT_METHOD(setNumberOfLoops
                  : (nonnull NSNumber *)key withValue
                  : (nonnull NSNumber *)value) {
    AVAudioPlayer *player = [self playerForKey:key];
    if (player) {
        player.numberOfLoops = [value intValue];
    }
}

RCT_EXPORT_METHOD(setSpeed
                  : (nonnull NSNumber *)key withValue
                  : (nonnull NSNumber *)value) {
    AVAudioPlayer *player = [self playerForKey:key];
    if (player) {
        player.rate = [value floatValue];
    }
}

RCT_EXPORT_METHOD(setCurrentTime
                  : (nonnull NSNumber *)key withValue
                  : (nonnull NSNumber *)value) {
    AVAudioPlayer *player = [self playerForKey:key];
    if (player) {
        player.currentTime = [value doubleValue];
    }
}

RCT_EXPORT_METHOD(getCurrentTime
                  : (nonnull NSNumber *)key withCallback
                  : (RCTResponseSenderBlock)callback) {
    AVAudioPlayer *player = [self playerForKey:key];
    if (player) {
        callback([NSArray
            arrayWithObjects:[NSNumber numberWithDouble:player.currentTime],
                             [NSNumber numberWithBool:player.isPlaying], nil]);
    } else {
        callback([NSArray arrayWithObjects:[NSNumber numberWithInteger:-1],
                                           [NSNumber numberWithBool:NO], nil]);
    }
}

RCT_EXPORT_METHOD(setSpeakerPhone : (BOOL)on) {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (on) {
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                   error:nil];
    } else {
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone
                                   error:nil];
    }
    [session setActive:true error:nil];
}

RCT_EXPORT_METHOD(getOutputs:(RCTResponseSenderBlock)callback)
{
  //Reset audio output route and session catetory when get the list
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
  [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];

  NSMutableArray *array;
  BOOL isHeadsetOn = false;
  BOOL isBluetoothConnected = false;

  AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
  for (AVAudioSessionPortDescription* desc in [route outputs]) {
    if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones]) {
      isHeadsetOn = true;
      continue;
    }

    if ([[desc portType] isEqualToString:AVAudioSessionPortBluetoothA2DP] ||
        [[desc portType] isEqualToString:AVAudioSessionPortBluetoothLE] ||
        [[desc portType] isEqualToString:AVAudioSessionPortBluetoothHFP]) {
      isBluetoothConnected = true;
    }
  }
  if (isHeadsetOn) {
    array = [NSMutableArray arrayWithArray: @[outputHeadphones]];
  } else if (isBluetoothConnected) {
    array = [NSMutableArray arrayWithArray: @[outputPhone, outputPhoneSpeaker, outputBluetooth]];
  } else {
    array = [NSMutableArray arrayWithArray: @[outputPhone, outputPhoneSpeaker]];
  }

  callback(@[array]);
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}
- (void)setOnPlay:(BOOL)isPlaying forPlayerKey:(nonnull NSNumber *)playerKey {
    [self
        sendEventWithName:@"onPlayChange"
                     body:[NSDictionary
                              dictionaryWithObjectsAndKeys:
                                  [NSNumber
                                      numberWithBool:isPlaying ? YES : NO],
                                  @"isPlaying", playerKey, @"playerKey", nil]];
}
@end
