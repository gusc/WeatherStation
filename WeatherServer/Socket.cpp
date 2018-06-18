//
//  Socket.cpp
//  WeatherServer
//
//  Created by Gusts Kaksis on 14/06/2018.
//  Copyright © 2018 Gusts Kaksis. All rights reserved.
//

#include "Socket.h"
#include <cstring>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

Socket::Socket(uint16_t port)
{
    struct sockaddr_in serv_addr;
    
    this->con = socket(AF_INET, SOCK_STREAM, 0);
    if (this->con < 0)
    {
        throw "Can't open socket";
    }
    
    std::memset(&serv_addr, 0, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = INADDR_ANY;
    serv_addr.sin_port = htons(port);
    if (bind(this->con, reinterpret_cast<struct sockaddr*>(&serv_addr), sizeof(serv_addr)) < 0)
    {
        throw "Can't bind to port";
    }
    
    if (listen(this->con, 5) < 0)
    {
        throw "Failed to listen to connection";
    }
}

Socket::~Socket()
{
    if (this->con)
    {
        close(this->con);
    }
}

void Socket::Process(std::function<bool (const DataPacket &)> &lambda)
{
    struct sockaddr cli_addr;
    socklen_t cli_size = sizeof(cli_addr);
    
    DataPacket dp;
    
    std::memset(&cli_addr, 0, cli_size);
    if (accept(this->con, &cli_addr, &cli_size) < 0)
    {
        throw "Failed to establish connection";
    }
    
    if (recv(this->con, &dp, sizeof(dp), 0) < sizeof(dp))
    {
        throw "Not enough bytes received";
    }
    
    DataPacket* dp2 = reinterpret_cast<DataPacket*>(std::calloc(dp.packetSize / 4, 4));
    std::memcpy(dp2, &dp, sizeof(dp));
    
    size_t leftovers = dp.packetSize - sizeof(dp);
    
    if (recv(this->con, &dp2->cont[2], leftovers, 0) < leftovers)
    {
        throw "Malformed packet size";
    }
    
    lambda(*dp2);
}
