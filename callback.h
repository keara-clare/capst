//
//  callback.h
//  able-test
//
//  Created by Alisha Mitchell on 2/23/19.
//  Copyright © 2019 Pison. All rights reserved.
//

#ifndef __callback__
#define __callback__
#include <string>
using namespace std;

class callback
{
    public:
        static void setup();
        static void scanForDevices();
        static bool checkIfDiscovered();
        static void stopScanForDevices();
        static void connectToDevice(int timeout);
        static void populateServices(int timeout);
        static void populateCharacteristics(int timeout);
        static void readFromCharacteristic(int timeout);
        static void subscribeToNotifications(int timeout);
        static void writeToCharacteristic(int timeout, string data, bool withoutResponse);
        static void unsubscribeToNotifications(int timeout);
        static void dispose();
        static bool readbusy();
        static bool readdisconnected();
        static bool readnotifying();
        static string readmanager();
        static string readDevName();
        static string readDevUuid();

};
/*********************************************
 //scanfordevices:
 JNIEXPORT void JNICALL Java_com_pison_able_BluetoothCentralNative_scanForDevices(JNIEnv *env, jobject, const jobject receiver, const jint timeout){
 int time = timeout;
 currently_scanning = true;
 while(time > 0){
 callback::scanForDevices();
 add_device(callback::readDevName(), callback::readDevUuid());
 time--;
 }
 callback::stopScanForDevices();
 currently_scanning = false;
 env->DeleteGlobalRef(reinterpret_cast<jobject>(scan_receiver));
 scan_receiver = nullptr;
 }
 
 *******************************************/


#endif /* defined(__callback__) */
