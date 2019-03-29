//
//  com_pison_able_BluetoothCentralNative.cpp
//  able-test
//
//  Created by Alisha Mitchell on 2/26/19.
//  Copyright © 2019 Pison. All rights reserved.
//

#include "com_pison_able_BluetoothCentralNative.h"  // Generated
#include <iostream>    // C++ standard IO header
#include <string>
#include <sstream>
#include <iomanip>
#include <iostream>
#include "callback.h"
#include <xlocale.h>
using namespace std;

//Java UUID 4 bytes-2 bytes-2 bytes-2 bytes-6 bytes
//mac UUID 4 bytes-2 bytes-2 bytes-2 bytes-6 bytes

// Convert a number into a hex string representation
template< typename T >
string int_to_hex(T i)
{
    stringstream stream;
    stream << setfill('0') << setw(sizeof(T) * 2)
    << hex << i;
    return stream.str();
}
// Convert from a native string to jstring
jstring native_str_to_j(JNIEnv *env, const string str)
{
    return env->NewStringUTF(str.c_str());
}
// Convert from jstring to native string
string j_str_to_native(JNIEnv *env, const jstring str_j)
{
    const char* chars = env->GetStringUTFChars(str_j, JNI_FALSE);
    string result = string(chars);
    env->ReleaseStringUTFChars(str_j, chars);
    return result;
}
static JavaVM *jvm;
//jclass cls;

//setup:
JNIEXPORT void JNICALL Java_com_pison_able_BluetoothCentralNative_setup(JNIEnv *env, jobject jthis, const jobject receiver){
    jint rs = env->GetJavaVM(&jvm);
    assert(rs == JNI_OK);
    const auto receiver_class = env->GetObjectClass(receiver);
    const auto bluetooth_unavailable = env->GetMethodID(receiver_class, "onBluetoothUnavailable", "(Ljava/lang/String;)V");
    //const auto bt = L"Bluetooth";
    callback::setup();
    string state = callback::readmanager();
    if(state == "poweredOn"){
        const auto bluetooth_ready = env->GetMethodID(receiver_class, "onBluetoothReady", "()V");
        env->CallObjectMethod(receiver, bluetooth_ready);
    }else if(state =="poweredOff")
    {
        char error[26] = "Bluetooth is powered off.";
        const auto error_string = env->NewStringUTF(error);
        env->CallObjectMethod(receiver, bluetooth_unavailable, error_string);
    }else if (state =="unsupported"){
        char error[41] = "This machine does not support Bluetooth.";
        const auto error_string = env->NewStringUTF(error);
        env->CallObjectMethod(receiver, bluetooth_unavailable, error_string);
    }else{
        char error[6]="Error";
        const auto error_string = env->NewStringUTF(error);
        env->CallObjectMethod(receiver, bluetooth_unavailable, error_string);
        
    }
}
static jobject scan_receiver = nullptr;
static jmethodID on_device_discovered = nullptr;
static bool currently_scanning = false;
jobject native_device_to_j(JNIEnv *env, string devName, string devUUID)
{
    const jstring j_name = env->NewStringUTF(devName.c_str());
    const jstring j_uuid = native_str_to_j(env,devUUID);
    const jclass device_class = env->FindClass("com/pison/able/BluetoothDevice");
    const jmethodID device_constructor = env->GetMethodID(device_class, "<init>", "(Ljava/lang/String;Ljava/lang/String;)V");
    
    return env->NewObject(device_class, device_constructor, j_name, j_uuid);
}
void add_device(string devName, string devUUID)
{
    if (currently_scanning & devName!= "" & devUUID !="") {
        JNIEnv *env;
        jint rs = jvm->AttachCurrentThread(reinterpret_cast<void **>(&env), nullptr);
        assert(rs == JNI_OK);
        const jobject device_j = native_device_to_j(env, devName, devUUID);
        env->CallObjectMethod(scan_receiver, on_device_discovered, device_j);
        jvm->DetachCurrentThread();
    }
}
//scanfordevices:
JNIEXPORT void JNICALL Java_com_pison_able_BluetoothCentralNative_scanForDevices(JNIEnv *env, jobject, const jobject receiver, const jint timeout){
     // Set up global references
    const jclass receiver_class = env->GetObjectClass(receiver);
     on_device_discovered = env->GetMethodID(receiver_class, "didDiscoverPeripheral", "(Lcom/pison/able/macable;)V");
    int time = timeout;
    scan_receiver = env->NewGlobalRef(receiver);
    currently_scanning = true;
    while(time>0){
        callback::scanForDevices();
        bool disc = callback::checkIfDiscovered();  //disc = true when peripheral is discovered
        if(disc==true){
            string devName = callback::readDevName();
            string devUUID = callback::readDevUuid();
            add_device(devName, devUUID);
        }
        time--;
    }
    // Delete global references
    env->DeleteGlobalRef(reinterpret_cast<jobject>(scan_receiver));
    scan_receiver = nullptr;
}
//populateservices:
JNIEXPORT void JNICALL Java_com_pison_able_BluetoothCentralNative_populateServices(JNIEnv *env, jobject, const jobject receiver, jobject device_j){
    callback::connectToDevice(10);
    callback::populateServices(10);
    callback::populateCharacteristics(10);
}

//readfromchar:
JNIEXPORT jbyteArray JNICALL Java_com_pison_able_BluetoothCentralNative_readFromCharacteristic(JNIEnv *, jobject, jobject, jobject, jobject, jobject){
    callback::readFromCharacteristic(10);
    return 0;
}
//subscribe:
JNIEXPORT void JNICALL Java_com_pison_able_BluetoothCentralNative_subscribeToNotifications(JNIEnv *env, jobject, const jobject receiver, const jobject device_j, const jobject service, const jobject characteristic_j){
    //jobject reciever = BluetoothStatusChangeReceiver's reciever to notify when writing is complete
    //jobject device_j = the bluetooth device to read from
    //jobject serice = the service to read from
    //jobject charactertistic_j = the characteristic to read from
    //callback::subscribeToNotifications(10);
    const auto receiver_class = env->GetObjectClass(receiver);
    bool disc = callback::checkIfDiscovered();  //disc = true when peripheral is discovered
    if(disc==true){
        string devName = callback::readDevName();   //get the device name
        string devUUID = callback::readDevUuid();   //get the device UUID
    }
    string state = callback::readmanager();         //checks the state of the manager
    
    
}
/*
 JNIEXPORT void JNICALL Java_com_pison_able_BluetoothCentralNative_subscribeToNotifications
 (JNIEnv *env, jobject, const jobject receiver, const jobject device_j, const jobject service, const jobject characteristic_j)
 {
 const auto receiver_class = env->GetObjectClass(receiver);
 on_device_connected = env->GetMethodID(receiver_class, "onDeviceConnected", "()V");
 on_connection_status_change = env->GetMethodID(receiver_class, "onConnectionStatusChange", "(Ljava/lang/String;)V");
 on_data_received = env->GetMethodID(receiver_class, "onDataReceived", "([B)V");
 notifications_receiver = env->NewGlobalRef(receiver);
 
 subscribed_device = j_device_to_native(env, device_j);
 if(subscribed_device != nullptr)
 {
 subscribed_device.ConnectionStatusChanged([=](const BluetoothLEDevice device, const auto args)
 {
 connection_status_changed(device);
 });
 //get_characteristic(env, service, characteristic_j, subscribed_device);
 GUID characteristicGuid = *j_uuid_to_guid(env, characteristic_j);
 for (GenericAttributeProfile::GattCharacteristic curCharacteristic : cachedCharacteristics)
 {
 if (curCharacteristic.Uuid() == characteristicGuid)
 {
 subscribed_characteristic = curCharacteristic;
 break;
 }
 }
 if(subscribed_characteristic == nullptr)
 {
 // Try getting it from the device
 subscribed_characteristic = get_characteristic(env, service, characteristic_j, subscribed_device);
 
 }
 if (subscribed_characteristic != nullptr)
 {
 connection_status_changed(subscribed_device);
 device_disconnected = false;
 if ((subscribed_characteristic.CharacteristicProperties() == GenericAttributeProfile::GattCharacteristicProperties::Notify)
 | (subscribed_characteristic.CharacteristicProperties() == GenericAttributeProfile::GattCharacteristicProperties::Indicate))
 {
 const auto status = subscribed_characteristic.WriteClientCharacteristicConfigurationDescriptorAsync(GenericAttributeProfile::GattClientCharacteristicConfigurationDescriptorValue::Notify).get();
 if (status == GenericAttributeProfile::GattCommunicationStatus::Success)
 {
 subscribed_characteristic.ValueChanged([=](const GenericAttributeProfile::GattCharacteristic sender, const GenericAttributeProfile::GattValueChangedEventArgs args)
 {
 if (notifications_connected)
 {
 auto reader = Storage::Streams::DataReader::FromBuffer(args.CharacteristicValue());
 std::vector<byte> bytes(reader.UnconsumedBufferLength());
 reader.ReadBytes(bytes);
 received_data(bytes);
 }
 });
 notifications_connected = true;
 }
 else
 {
 env->CallObjectMethod(receiver, on_connection_status_change,
 native_str_to_j(env, "Couldn't register for notifications from device. Move closer and try again."));
 }
 }
 else
 {
 env->CallObjectMethod(receiver, on_connection_status_change,
 native_str_to_j(env, "This characteristic does not support notification."));
 }
 }
 else
 {
 env->CallObjectMethod(receiver, on_connection_status_change,
 native_str_to_j(env, "Couldn't get characteristic. Move closer and try again."));
 }
 }
 else
 {
 env->CallObjectMethod(receiver, on_connection_status_change,
 native_str_to_j(env, "Couldn't connect to device. Move closer and try again."));
 }
 if(!notifications_connected)
 {
 cleanup_notifications(receiver);
 }
 }
 */
/*
 //callback's subscribe to notifications
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
 */
//writechar:
JNIEXPORT void JNICALL Java_com_pison_able_BluetoothCentralNative_writeToCharacteristic(JNIEnv *env, jobject, jobject receiver, jobject device_j, jobject service, jobject characteristic_j, jbyteArray bytes){
    callback::writeToCharacteristic(10, "2", false);
}
//unsubscribe:
JNIEXPORT void JNICALL Java_com_pison_able_BluetoothCentralNative_unsubscribeToNotifications(JNIEnv *env, jobject, const jobject receiver){
    callback::unsubscribeToNotifications(2);
}
//dispose:
JNIEXPORT void JNICALL Java_com_pison_able_BluetoothCentralNative_dispose(JNIEnv *env, jobject){
    callback::dispose();
}
