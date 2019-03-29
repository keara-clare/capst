//
//  callback.m
//  able-test
//
//  Created by Alisha Mitchell on 2/23/19.
//  Copyright © 2019 Pison. All rights reserved.
//


#include "callback.h"
#include <string>
#include "macable.h"
#include "objc_cpp.h"
macable *blemanager;
void callback::setup()
{
    NSLog(@"Starting setup");
    blemanager = [[macable alloc] init];
    while(blemanager.busy == true){
        [blemanager sleepfor:0.5f];
    }
    NSLog(@"Setup finished");
}
void callback::scanForDevices()
{
    NSLog(@"Starting to scan for devices");
    [blemanager scan:nil allowDuplicates:YES];
    while(blemanager.busy == true){
        [blemanager sleepfor:1.0];
    }
}
bool callback::checkIfDiscovered()
{
    /*Checks to see if a peripheral has been discovered from scan*/
    return [blemanager isPeripheralDiscovered];
    
}
void callback::stopScanForDevices(){
    [blemanager stopScan];
    NSLog(@"Scan for devices finished");
}
void callback::connectToDevice(int timeout){
    if(blemanager.disconnected == false){
        if(blemanager.PDevice != nil){
            NSLog(@"Trying to connect to device %@",blemanager.PDevice.name);
            int i = timeout;
            [blemanager connect:[blemanager.deviceUUID UUIDString]];
            while(blemanager.busy==true){
                [blemanager sleepfor:0.5];
            }
            NSLog(@"Connection to %@ succeeded",blemanager.PDevice.name);
            while(blemanager.disconnected == false && i>0){
                if(i>0){
                    [blemanager sleepfor:0.5];
                    i--;
                }else{
                    NSLog(@"No further instruction for connection. Disconnecting device");
                    [blemanager disconnect:[blemanager.deviceUUID UUIDString]];
                    break;
                }
            }
        }
        else{
            blemanager.disconnected = true;
            NSLog(@"No device to be connected. Check that the device is turned on and try again");
        }
    }
}
void callback::populateServices(int timeout){
    if(blemanager.disconnected == false){
        NSLog(@"Finding the Device's services");
        int i = timeout;
        [blemanager discoverServices:[blemanager.deviceUUID UUIDString] serviceUuids:nil];
        while(blemanager.busy == true){
            [blemanager sleepfor:0.5];
        }
        NSLog(@"Services populated");
        while(blemanager.disconnected == false && i>0){
            if(i>0){
                [blemanager sleepfor:0.5];
                i--;
            }else{
                NSLog(@"No further instruction for connection. Disconnecting device");
                [blemanager disconnect:[blemanager.deviceUUID UUIDString]];
                break;
            }
        }
    }
}
void callback::populateCharacteristics(int timeout){
    if(blemanager.disconnected == false){
        NSLog(@"Finding the Device's characteristics");
        int i = timeout;
        if(blemanager.serviceUUIDs != nil){
            [blemanager discoverCharacteristics:[blemanager.deviceUUID UUIDString] forService:[blemanager.serviceUUIDs objectAtIndex:0] characteristics:nil];
            while(blemanager.busy == true){
                [blemanager sleepfor:0.5];
            }
            NSLog(@"Characteristics populated");
            while(blemanager.disconnected == false && i>0){
                if(i>0){
                    [blemanager sleepfor:0.5];
                    i--;
                }else{
                    NSLog(@"No further instruction for connection. Disconnecting device");
                    [blemanager disconnect:[blemanager.deviceUUID UUIDString]];
                    break;
                }
            }
        }
        else{
            NSLog(@"No characteristics found");
        }
    }
}
void callback::readFromCharacteristic(int timeout){
    if(blemanager.disconnected == false){
        NSLog(@"Reading characteristic");
        int i = timeout;
        if(blemanager.characteristicsUUIDs != nil){
            [blemanager read:[blemanager.deviceUUID UUIDString] service:[blemanager.serviceUUIDs objectAtIndex:0] characteristic:[blemanager.characteristicsUUIDs objectAtIndex:1]];
            while(blemanager.busy == true){
                [blemanager sleepfor:0.5];
            }
            NSLog(@"Characteristic read");
            while(blemanager.disconnected == false && i>0){
                if(i>0){
                    [blemanager sleepfor:0.5];
                    i--;
                }else{
                    NSLog(@"No further instruction for connection. Disconnecting device");
                    [blemanager disconnect:[blemanager.deviceUUID UUIDString]];
                    break;
                }
            }
        }
    }
}
void callback::subscribeToNotifications(int timeout){
    if(blemanager.disconnected == false){
        NSLog(@"Subscribing to notifications");
        int i = timeout;
        if(blemanager.characteristicsUUIDs != nil){
            [blemanager notify:[blemanager.deviceUUID UUIDString] service:[blemanager.serviceUUIDs objectAtIndex:0] characteristic:[blemanager.characteristicsUUIDs objectAtIndex:1] on:YES];
            while(blemanager.busy == true){
                [blemanager sleepfor:0.5];
            }
            while(blemanager.disconnected == false && blemanager.notifying==true && i>0){
                if(i>0){
                    [blemanager sleepfor:0.5];
                    i--;
                }else{
                    blemanager.notifying=false;
                }
            }
        }
    }
}
void callback::writeToCharacteristic(int timeout, std::string data, bool withoutResponse){
    if(blemanager.disconnected == false){
        NSLog(@"Writing to characteristic");
        int i = timeout;
        NSString *dataNS = [NSString stringWithCString:data.c_str()
                                                    encoding:[NSString defaultCStringEncoding]];
        NSData *Data = [NSData dataWithBytes:dataNS.UTF8String length:dataNS.length] ;
        if(blemanager.characteristicsUUIDs != nil){
            [blemanager write:[blemanager.deviceUUID UUIDString] service:[blemanager.serviceUUIDs objectAtIndex:0] characteristic:[blemanager.characteristicsUUIDs objectAtIndex:0] data:Data withoutResponse:withoutResponse];
            while(blemanager.busy == true){
                [blemanager sleepfor:0.5];
            }
            NSLog(@"Characteristic written to successfully");
            while(blemanager.disconnected == false && i>0){
                if(i>0){
                    [blemanager sleepfor:0.5];
                    i--;
                }else{
                    NSLog(@"No further instruction for connection. Disconnecting device");
                    [blemanager disconnect:[blemanager.deviceUUID UUIDString]];
                    break;
                }
            }
        }
    }
}
void callback::unsubscribeToNotifications(int timeout){
    if(blemanager.disconnected == false){
        NSLog(@"Unsubscribing to notifications");
        int i = timeout;
        if(blemanager.characteristicsUUIDs != nil){
            [blemanager notify:[blemanager.deviceUUID UUIDString] service:[blemanager.serviceUUIDs objectAtIndex:0] characteristic:[blemanager.characteristicsUUIDs objectAtIndex:1] on:NO];
            while(blemanager.busy == true){
                [blemanager sleepfor:0.5];
            }
            NSLog(@"Successfully unsubscribed to notifications");
            while(blemanager.disconnected == false && i>0){
                if(i>0){
                    [blemanager sleepfor:0.5];
                    i--;
                }else{
                    NSLog(@"No further instruction for connection. Disconnecting device");
                    [blemanager disconnect:[blemanager.deviceUUID UUIDString]];
                    break;
                }
            }
        }
    }
}
void callback::dispose(){
    NSLog(@"Disconnecting device %@",blemanager.PDevice.name);
    [blemanager disconnect:[blemanager.deviceUUID UUIDString]];
    NSLog(@"Device successfully disconnected. Ending program now.");
}
bool callback::readbusy(){
    return blemanager.busy;
}
bool callback::readdisconnected(){
    return blemanager.disconnected;
}
bool callback::readnotifying(){
    return blemanager.notifying;
}
string callback::readmanager(){
    return string([blemanager.state UTF8String]);
    //return "hello";
    //string state = stateToString(blemanager.centralManager.state);
    //return state;
}
string callback::readDevName(){
    return string([blemanager.PDevice.name UTF8String]);
}
string callback::readDevUuid(){
    return string([[blemanager.PDevice.identifier UUIDString] UTF8String]);
}
