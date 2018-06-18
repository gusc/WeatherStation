//
//  DataPacket.h
//  WeatherStation
//
//  Created by Gusts Kaksis on 14/06/2018.
//  Copyright © 2018 Gusts Kaksis. All rights reserved.
//

#ifndef DataPacket_h
#define DataPacket_h

struct DataContainer
{
    struct {
        uint32_t pressure : 1;
        uint32_t temperature : 1;
        uint32_t altitude : 1;
        uint32_t reserved : 29;
    } features;
    uint32_t timestamp;
    struct {
        float latitude;
        float longitude;
    } location;
    float pressure;
    float temperature;
    float altitude;
};

struct DataPacket
{
    uint32_t headerVersion : 16;
    uint32_t packetSize : 16;
    uint32_t timestamp;
    uint32_t numContainers;
    DataContainer cont[1]; // First of many
};

#endif /* DataPacket_h */
