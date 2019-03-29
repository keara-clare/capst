//
// Created by Sidhant Srikumar on 2019-02-14.
// Copyright (c) 2019 Pison. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#include <dispatch/dispatch.h>

@interface macable : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate> {
    bool pendingRead;
}
@property (strong) CBCentralManager *centralManager;
@property dispatch_queue_t dispatchQueue;
@property NSMutableDictionary *peripherals;
@property bool busy;
@property bool notifying;
@property bool disconnected;
@property bool deviceDiscovered;
@property (strong) CBPeripheral *PDevice;
@property (strong) NSUUID* deviceUUID;
@property (strong) NSMutableArray<NSString*>* serviceUUIDs;
@property (strong) NSMutableArray<NSString *>* characteristicsUUIDs;
@property (strong) NSString* state;


- (instancetype)init;
- (void)scan: (NSArray<NSString*> *)serviceUUIDs allowDuplicates: (BOOL)allowDuplicates;
- (void)stopScan;
- (BOOL)connect:(NSString*) uuid;
- (BOOL)disconnect:(NSString*) uuid;
- (BOOL)discoverServices:(NSString*) uuid serviceUuids:(NSArray<NSString*>*) services;
- (BOOL)discoverCharacteristics:(NSString*) nsAddress forService:(NSString*) service characteristics:(NSArray<NSString*>*) characteristics;
- (BOOL)read:(NSString*) uuid service:(NSString*) serviceUuid characteristic:(NSString*) characteristicUuid;
- (BOOL)write:(NSString*) uuid service:(NSString*) serviceUuid characteristic:(NSString*) characteristicUuid data:(NSData*) data withoutResponse:(BOOL)withoutResponse;
- (BOOL)notify:(NSString*) uuid service:(NSString*) serviceUuid characteristic:(NSString*) characteristicUuid on:(BOOL)on;
-(void)sleepfor:(int)seconds;
-(bool) isPeripheralDiscovered;
@end
