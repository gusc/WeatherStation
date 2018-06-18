//
//  Socket.h
//  WeatherServer
//
//  Created by Gusts Kaksis on 14/06/2018.
//  Copyright © 2018 Gusts Kaksis. All rights reserved.
//

#ifndef Socket_h
#define Socket_h

#include <cstdint>
#include <functional>
#include "DataPacket.h"

class Socket
{
public:
    Socket(uint16_t port);
    ~Socket();
    
    void Process(std::function<bool(const DataPacket& data)>& lambda);
private:
    int con;
    
};

#endif /* Socket_h */
