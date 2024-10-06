@interface SBUIFlashlightController : NSObject
+(id)sharedInstance;
-(void)warmUp;
-(void)_turnPowerOn;
-(void)_updateStateWithAvailable:(BOOL)arg1 level:(unsigned long long)arg2 overheated:(BOOL)arg3 ;
-(void)_postLevelChangeNotification:(unsigned long long)arg1 ;
-(void)removeAllObservers;
-(void)_setFlashlightLevel:(float)arg1 ;
-(void)addObserver:(id)arg1 ;
-(void)_storeFlashlightLevel:(unsigned long long)arg1 ;
-(void)removeObserver:(id)arg1 ;
-(BOOL)isAvailable;
-(void)_postOverheatedChangeNotification:(BOOL)arg1 ;
-(void)turnFlashlightOnForReason:(id)arg1 ;
-(unsigned long long)level;
-(void)setLevel:(unsigned long long)arg1 ;
-(void)turnFlashlightOffForReason:(id)arg1 ;
-(id)init;
-(void)_turnPowerOff;
-(unsigned long long)_loadFlashlightLevel;
-(void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void*)arg4 ;
-(void)_postAvailabilityChangeNotification:(BOOL)arg1 ;
-(void)coolDown;
-(BOOL)isOverheated;
@end