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

int main(int argc, const char * argv[])
{
    std::string dbURI = "postgresql://localhost:5433/weather_stations";
    int srvPort = 6868;
    
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
        Database db(dbURI);
        // TODO: spawn socket listeners
    }
    catch (const std::exception &e)
    {
        std::cerr << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
