#pragma once
#include <server.hpp>
#include <array>

namespace pt::network
{
    class UdpServer
    {
        public:
            UdpServer(asio::io_context& ioContext, asio::ip::port_type port);

        protected:
            void StartReceive();
            void HandleReceive(const std::error_code& error);
            void HandleSend(std::shared_ptr<std::string> /*message*/);

        private:
            asio::ip::udp::socket _socket;
            asio::ip::udp::endpoint _remoteEndpoint;
            std::array<char, 1> _recvBuffer;
    };
}