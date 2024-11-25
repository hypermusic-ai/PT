#pragma once
#include <iostream>

#include <native.hpp>
#include <asio.hpp>

namespace pt::network
{
    inline std::string MakeDaytimeString()
    {
      using namespace std; // For time_t, time and ctime;
      time_t now = time(0);
      return ctime(&now);
    }

    class Server{
    public:
        virtual void start() = 0;
        virtual void stop() = 0;
    };
}