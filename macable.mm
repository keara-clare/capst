//
// Created by Sidhant Srikumar on 2019-02-14.
// Copyright (c) 2019 Pison. All rights reserved.
//

#import "macable.h"
#include "objc_cpp.h"
#include <CoreBluetooth/CoreBluetooth.h>
@implementation macable {
    
}
#pragma mark My Functions
- (instancetype)init {
    if(self = [super init]) {
        pendingRead = false;
        _dispatchQueue = dispatch_queue_create("CBqueue", Nil);
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:_dispatchQueue];
        _peripherals = [NSMutableDictionary dictionaryWithCapacity:10];
        _busy = true;
        _disconnected=false;
        _notifying = false;
        _characteristicsUUIDs = [NSMutableArray new];
        _serviceUUIDs = [NSMutableArray new];;
        _state = @"";
        _deviceDiscovered = false;
    }
    return self;
}

- (void)scan:(NSArray<NSString *> *)serviceUUIDs allowDuplicates:(BOOL)allowDuplicates {
    _busy=true;
    if(_centralManager.state == CBManagerStatePoweredOn) {
        NSMutableArray *advServicesUuid = [NSMutableArray arrayWithCapacity:[serviceUUIDs count]];
        [serviceUUIDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [advServicesUuid addObject:[CBUUID UUIDWithString:obj]];
        }];
        NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:allowDuplicates]};
        [_centralManager scanForPeripheralsWithServices:advServicesUuid options:options];
    } else
    {
        [self scan:serviceUUIDs allowDuplicates:allowDuplicates];
    }
}

- (void)stopScan {
    _busy=false;
    [_centralManager stopScan];
}

- (BOOL)connect:(NSString*) uuid {
    _busy = true;
    CBPeripheral *peripheral = _peripherals[uuid];
    if(!peripheral) {
        NSArray* peripherals = [_centralManager retrievePeripheralsWithIdentifiers:@[[[NSUUID alloc] initWithUUIDString:uuid]]];
        peripheral = [peripherals firstObject];
        if(peripheral) {
            peripheral.delegate = self;
        } else {
            return NO;
        }
    }
    NSDictionary* options = @{CBConnectPeripheralOptionNotifyOnDisconnectionKey: [NSNumber numberWithBool:YES]};
    [_centralManager connectPeripheral:peripheral options:options];
    return YES;
}
- (BOOL)disconnect:(NSString*) uuid {
    _disconnected = true;
    IF(CBPeripheral*, peripheral, _peripherals[uuid]) {
        [_centralManager cancelPeripheralConnection:peripheral];
        return YES;
    }
    return NO;
}
-(BOOL) discoverServices:(NSString*) uuid serviceUuids:(NSArray<NSString*>*) services {
    _busy = true;
    IF(CBPeripheral*, peripheral, _peripherals[uuid]) {
        NSMutableArray* servicesUuid = nil;
        if(services) {
            servicesUuid = [NSMutableArray arrayWithCapacity:[services count]];
            [services enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [servicesUuid addObject:[CBUUID UUIDWithString:obj]];
            }];
        }
        [peripheral discoverServices:servicesUuid];
        return YES;
    }
    return NO;
}
- (BOOL)discoverCharacteristics:(NSString*) uuid forService:(NSString*) serviceUuid characteristics:(NSArray<NSString*>*) characteristics {
    _busy = true;
    IF(CBPeripheral *, peripheral, _peripherals[uuid]) {
        IF(CBService*, service, [self getService:peripheral service:serviceUuid]) {
            NSMutableArray* characteristicsUuid = nil;
            if(characteristics) {
                characteristicsUuid = [NSMutableArray arrayWithCapacity:[characteristics count]];
                [characteristics enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [characteristicsUuid addObject:[CBUUID UUIDWithString:obj]];
                }];
            }
            [peripheral discoverCharacteristics:characteristicsUuid forService:service];
            return YES;
        }
    }
    return NO;
}
- (BOOL)notify:(NSString*) uuid service:(NSString*) serviceUuid characteristic:(NSString*) characteristicUuid on:(BOOL)on {
    _busy = true;
    _notifying = on;
    IF(CBPeripheral *, peripheral, _peripherals[uuid]) {
        IF(CBCharacteristic*, characteristic, [self getCharacteristic:peripheral service:serviceUuid characteristic:characteristicUuid]) {
            [peripheral setNotifyValue:on forCharacteristic:characteristic];
            return YES;
        }
    }
    return NO;
}
- (BOOL)write:(NSString*) uuid service:(NSString*) serviceUuid characteristic:(NSString*) characteristicUuid data:(NSData*) data withoutResponse:(BOOL)withoutResponse {
    NSLog(@"Data to write: %@\n",data);
    _busy = true;
    IF(CBPeripheral *, peripheral, [self.peripherals objectForKey:uuid]) {
        IF(CBCharacteristic*, characteristic, [self getCharacteristic:peripheral service:serviceUuid characteristic:characteristicUuid]) {
            CBCharacteristicWriteType type = withoutResponse ? CBCharacteristicWriteWithoutResponse : CBCharacteristicWriteWithResponse;
            [peripheral writeValue:data forCharacteristic:characteristic type:type];
            return YES;
        }
    }
    return NO;
}

- (BOOL)read:(NSString*) uuid service:(NSString*) serviceUuid characteristic:(NSString*) characteristicUuid {
    _busy = true;
    _notifying = true;
    IF(CBPeripheral *, peripheral, [self.peripherals objectForKey:uuid]) {
        IF(CBCharacteristic*, characteristic, [self getCharacteristic:peripheral service:serviceUuid characteristic:characteristicUuid]) {
            pendingRead = true;
            [peripheral readValueForCharacteristic:characteristic];
            return YES;
        }
    }
    return NO;
}
-(void)sleepfor:(int)seconds{
    [NSThread sleepForTimeInterval:seconds];
}
#pragma mark Central Roles
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    auto state = stateToString(central.state);
    _state =[NSString stringWithUTF8String:state.c_str()];
    NSLog(@"%@", _state);
    _busy=false;
}
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    _deviceDiscovered = true;
    std::string uuid = getUuid(peripheral);
    Peripheral p;
    p.address = getAddress(uuid, &p.addressType);
    IF(NSNumber*, connect, advertisementData[CBAdvertisementDataIsConnectable]) {
        p.connectable = [connect boolValue];
    }
    IF(NSString*, dataLocalName, [advertisementData objectForKey:CBAdvertisementDataLocalNameKey]) {
        p.name = std::make_pair([dataLocalName UTF8String], true);
    }
    if(!std::get<1>(p.name)) {
        IF(NSString*, name, [peripheral name]) {
            p.name = std::make_pair([name UTF8String], true);
        }
    }
    IF(NSNumber*, txLevel, [advertisementData objectForKey:CBAdvertisementDataTxPowerLevelKey]) {
        p.txPowerLevel = std::make_pair([txLevel intValue], true);
    }
    IF(NSData*, data, advertisementData[CBAdvertisementDataManufacturerDataKey]) {
        const UInt8* bytes = (UInt8 *)[data bytes];
        std::get<0>(p.manufacturerData).assign(bytes, bytes+[data length]);
        std::get<1>(p.manufacturerData) = true;
    }
    IF(NSDictionary*, dictionary, advertisementData[CBAdvertisementDataServiceDataKey]) {
        for (CBUUID* key in dictionary) {
            IF(NSData*, value, dictionary[key]) {
                auto serviceUuid = [[key UUIDString] UTF8String];
                Data sData;
                const UInt8* bytes = (UInt8 *)[value bytes];
                sData.assign(bytes, bytes+[value length]);
                std::get<0>(p.serviceData).push_back(std::make_pair(serviceUuid, sData));
            }
        }
        std::get<1>(p.serviceData) = true;
    }
    IF(NSArray*, services, advertisementData[CBAdvertisementDataServiceUUIDsKey]) {
        for (CBUUID* service in services) {
            std::get<0>(p.serviceUuids).push_back([[service UUIDString] UTF8String]);
        }
        std::get<1>(p.serviceUuids) = true;
    }
    if([peripheral.name containsString:@"Pison"] && peripheral.name != _PDevice.name){
        NSLog(@"Peripheral: %@", peripheral.name);
        if(_PDevice != peripheral){
            _PDevice = peripheral;
        }
        NSLog(@"UUID: %@", peripheral.identifier);
        if(_deviceUUID != peripheral.identifier){
            _deviceUUID = peripheral.identifier;
        }
    }
}
-(bool) isPeripheralDiscovered{
    if(_deviceDiscovered==true){
        return true;
    }
    else{
        return false;
    }
}
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    _busy = false;
    std::string uuid = getUuid(peripheral);
    NSString *uuid1 = [peripheral.identifier UUIDString];
    _peripherals[uuid1] = peripheral;
    return;
}
- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    _busy = false;
    std::string uuid = getUuid(peripheral);
    NSLog(@"Connection Failed");
    NSLog(@"%@", [NSString stringWithUTF8String:uuid.c_str()]);
}

-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    _disconnected = true;
    _busy = false;
    std::string uuid = getUuid(peripheral);
    NSLog(@"Disconnected");
}


#pragma mark Peripheral Roles
- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    std::string uuid = getUuid(peripheral);
    std::vector<std::string> services = getServices(peripheral.services);
    for(CBService *service in peripheral.services)
    {
        NSLog(@"Service discovered %@", service.UUID);
        [_serviceUUIDs addObject:[service.UUID UUIDString]];
    }
    _busy = false;
}


-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    std::string uuid = getUuid(peripheral);
    std::string serviceUuid = std::string([service.UUID.UUIDString UTF8String]);
    auto characteristics = getCharacteristics(service.characteristics);
    for(CBCharacteristic *characteristic in service.characteristics)
    {
        NSLog(@"characteristic discovered %@", characteristic.UUID);
        [_characteristicsUUIDs addObject:[characteristic.UUID UUIDString]];
    }
    _busy = false;
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    NSLog(@"hello");
    std::string uuid = getUuid(peripheral);
    std::string serviceUuid = [descriptor.characteristic.service.UUID.UUIDString UTF8String];
    std::string characteristicUuid = [descriptor.characteristic.UUID.UUIDString UTF8String];
    std::string descriptorUuid = [descriptor.UUID.UUIDString UTF8String];
    const UInt8* bytes = (UInt8 *)[descriptor.value bytes];
    Data data;
    data.assign(bytes, bytes+[descriptor.value length]);
}
- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    std::string uuid = getUuid(peripheral);
    std::string serviceUuid = [characteristic.service.UUID.UUIDString UTF8String];
    std::string characteristicUuid = [characteristic.UUID.UUIDString UTF8String];
    const UInt8* bytes = (UInt8 *)[characteristic.value bytes];
    Data data;
    data.assign(bytes, bytes+[characteristic.value length]);
    // bool isNotification = !pendingRead && characteristic.isNotifying;
    pendingRead = false;
    if(_notifying == true){
        NSLog(@"Notification length: %tu", characteristic.value.length);
        if(characteristic.value == nil){
            NSLog(@"Notification value:' '");
        }else{
            NSLog(@"Notification value: %@",characteristic.value);
        }
    }
    _busy=false;
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    std::string uuid = getUuid(peripheral);
    std::string serviceUuid = [characteristic.service.UUID.UUIDString UTF8String];
    std::string characteristicUuid = [characteristic.UUID.UUIDString UTF8String];
}
-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    std::string uuid = getUuid(peripheral);
    std::string serviceUuid = [characteristic.service.UUID.UUIDString UTF8String];
    std::string characteristicUuid = [characteristic.UUID.UUIDString UTF8String];
    _busy = false;
}

#pragma mark CB getters
-(CBService*)getService:(CBPeripheral*) peripheral service:(NSString*) serviceUuid {
    if(peripheral && peripheral.services) {
        for(CBService* service in peripheral.services) {
            if([service.UUID isEqualTo:[CBUUID UUIDWithString:serviceUuid]]) {
                return service;
            }
        }
    }
    return nil;
}

-(CBCharacteristic*)getCharacteristic:(CBPeripheral*) peripheral service:(NSString*) serviceUuid characteristic:(NSString*) characteristicUuid {
    CBService* service = [self getService:peripheral service:serviceUuid];
    if(service && service.characteristics) {
        for(CBCharacteristic* characteristic in service.characteristics) {
            if([characteristic.UUID isEqualTo:[CBUUID UUIDWithString:characteristicUuid]]) {
                return characteristic;
            }
        }
    }
    return nil;
}
@end
