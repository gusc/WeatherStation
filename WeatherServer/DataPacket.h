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
    uint32_t containerSize;
    uint32_t containerId; // also char[4]
};

struct DataPacket
{
    uint32_t headerSize;
    uint32_t packetVersion;
    uint32_t timestamp;
    uint32_t numContainers;
    DataContainer cont[1]; // First of many
};

#define CONTAINER_ID_PRESSURE 0x72737370
#define CONTAINER_ID_TEMPERATURE 0x706D6574
#define CONTAINER_ID_LOCATION 0x2E737067

struct DataPressure
{
    DataContainer header;
    float pressure;
};

struct DataTemperature
{
    DataContainer header;
    float temperature;
};

struct DataLocation
{
    DataContainer header;
    float latitude;
    float longitude;
    float altitude;
};

#endif /* DataPacket_h */
