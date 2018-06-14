//
//  Database.h
//  WeatherServer
//
//  Created by Gusts Kaksis on 14/06/2018.
//  Copyright © 2018 Gusts Kaksis. All rights reserved.
//

#ifndef Database_h
#define Database_h

#include <stdio.h>
#include <pqxx/pqxx>
#include "DataPacket.h"

struct DataSet
{
    // Feature bitset
    uint32_t supports_pressure : 1;
    uint32_t supports_temperature : 1;
    // implicit padding up to 1 uint32_t
    float pressure;
    float temperature;
    float latitude;
    float longitude;
    float altitude;
};

class Database
{
    
public:
    Database(const std::string& uri);
    ~Database();
    
    bool StoreData(const DataSet& data);
    
private:
    pqxx::connection con;
    
};

#endif /* Database_h */
