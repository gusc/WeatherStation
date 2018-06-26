//
//  Socket.cpp
//  WeatherServer
//
//  Created by Gusts Kaksis on 14/06/2018.
//  Copyright © 2018 Gusts Kaksis. All rights reserved.
//

#include "Socket.h"
#include <cstring>
#include <cerrno>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string>

Socket::Socket(uint16_t port)
{
    struct sockaddr_in serv_addr;
    
    this->con = socket(AF_INET, SOCK_STREAM, 0);
    if (this->con < 0)
    {
        throw std::runtime_error("Can't open socket");
    }
    
    std::memset(&serv_addr, 0, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = INADDR_ANY;
    serv_addr.sin_port = htons(port);
    if (bind(this->con, reinterpret_cast<struct sockaddr*>(&serv_addr), sizeof(serv_addr)) < 0)
    {
        throw std::runtime_error("Can't bind to port");
    }
    
    if (listen(this->con, 5) < 0)
    {
        throw std::runtime_error("Failed to listen to connection");
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
    
    DataPacket dp = {0};
    DataPacket* dpp = &dp;
    
    std::memset(&cli_addr, 0, cli_size);
    
    int client = accept(this->con, &cli_addr, &cli_size);
    if (client < 0)
    {
        std::string err = "Failed to establish connection: " + std::string(strerror(errno));
        throw std::runtime_error(err);
    }
    
    ssize_t recSize = recv(client, &dp, sizeof(dp), MSG_WAITALL);
    if (recSize < 0)
    {
        std::string err = "Not enough bytes received: " + std::string(strerror(errno));
        throw std::runtime_error(err);
    }
    
    if (dp.numContainers > 1)
    {
        dpp = reinterpret_cast<DataPacket*>(std::calloc(dp.packetSize / 4, 4));
        std::memcpy(dpp, &dp, sizeof(dp));
        
        ssize_t leftovers = dp.packetSize - sizeof(dp);
        if (leftovers > 0)
        {
            recSize = recv(client, &dpp->cont[1], leftovers, MSG_WAITALL);
            if (recSize < 0)
            {
                std::string err = "Malformed packet size: " + std::string(strerror(errno));
                throw std::runtime_error(err);
            }
        }
    }
    
    close(client);
    
    lambda(*dpp);
}
