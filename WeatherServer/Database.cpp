//
//  Database.cpp
//  WeatherServer
//
//  Created by Gusts Kaksis on 14/06/2018.
//  Copyright © 2018 Gusts Kaksis. All rights reserved.
//

#include "Database.h"

Database::Database(const std::string& uri) : con(uri)
{
}

Database::~Database()
{
    con.disconnect();
}

bool Database::StoreData(const DataSet &data)
{
    pqxx::work trans(con);
    
    std::string query = "INSERT INTO weather_data (pressure, temperature, latitude, longitude, altitude) VALUES (";
    if (data.supports_pressure)
    {
        query += std::to_string(data.pressure) + ", ";
    }
    else
    {
        query += "NULL, ";
    }
    if (data.supports_temperature)
    {
        query += std::to_string(data.temperature) + ", ";
    }
    else
    {
        query += "NULL, ";
    }
    query += std::to_string(data.latitude) + ", ";
    query += std::to_string(data.longitude) + ", ";
    query += std::to_string(data.altitude) + ")";
    
    pqxx::result res = trans.exec(query);
    
    trans.commit();
    return true;
}
