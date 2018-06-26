//
//  main.cpp
//  WeatherServer
//
//  Created by Gusts Kaksis on 26/05/2018.
//  Copyright © 2018 Gusts Kaksis. All rights reserved.
//

#include <iostream>
#include "Database.h"
#include "Socket.h"
#include <pthread.h>

std::string dbURI = "postgresql://localhost:5432/weather_stations";
int srvPort = 6868;

Database* db;
Socket* sock;

void* spawn_server(void*)
{
    try
    {
        std::function<bool(const DataPacket& data)> callback = [=](const DataPacket& data){
            printf("Insert new row");
            
            DataSet dset;
            
            time_t now = std::time(nullptr);
            for (size_t i = 0; i < data.numContainers; i ++)
            {
                int64_t diff = data.cont[i].timestamp - data.timestamp;
                dset.supports_pressure = data.cont[i].features.pressure;
                dset.supports_temperature = data.cont[i].features.temperature;
                dset.timestamp = now + diff;
                dset.latitude = data.cont[i].location.latitude;
                dset.longitude = data.cont[i].location.longitude;
                dset.altitude = data.cont[i].altitude;
                dset.pressure = data.cont[i].pressure;
                dset.temperature = data.cont[i].temperature;
                db->StoreData(dset);
            }
        
            return true;
        };
        sock->Process(callback);
    }
    catch (const std::exception &e)
    {
        std::cerr << "ERROR: " << e.what() << std::endl;
    }
    
    return nullptr;
}

int main(int argc, const char * argv[])
{
    // Parse command line arguments
    
    int a = 1;
    while (a < argc)
    {
        if (std::string(argv[a]) == "--db")
        {
            if (a + 1 < argc)
            {
                dbURI = std::string(argv[a + 1]);
            }
        }
        else if (std::string(argv[a]) == "--port")
        {
            if (a + 1 < argc)
            {
                srvPort = std::atoi(argv[a + 1]);
            }
        }
        a++;
    }
    
    // Initialize database connection and spawn socket listeners
    
    try
    {
        // Connect to database
        Database d(dbURI);
        db = &d;
        
        // Bind to socket
        Socket s(srvPort);
        sock = &s;
        
        // Spawn some threads
        pthread_t thread[10];
        for (int b = 0; b < 10; b ++)
        {
            if (pthread_create(&thread[b], nullptr, spawn_server, nullptr) < 0)
            {
                throw std::runtime_error("Failed to create a thread");
            }
        }
        
        std::cout << "Server started!\n" << std::endl;
        
        while (1)
        {
            for (int b = 0; b < 10; b ++)
            {
                // Wait for the thread to finish
                pthread_join(thread[b], nullptr);
                // Re-spawn it again
                if (pthread_create(&thread[b], nullptr, spawn_server, nullptr) < 0)
                {
                    throw std::runtime_error("Failed to create a thread");
                }
            }
        }
    }
    catch (const std::exception &e)
    {
        std::cerr << "ERROR: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
