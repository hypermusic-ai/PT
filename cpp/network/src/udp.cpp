#include <udp.hpp>

namespace pt::network
{
    UdpServer::UdpServer(asio::io_context& ioContext, asio::ip::port_type port)
        : _socket(ioContext, asio::ip::udp::endpoint(asio::ip::udp::v4(), port))
    {
        StartReceive();
    }

    void UdpServer::StartReceive()
    {
        _socket.async_receive_from(
            asio::buffer(_recvBuffer), _remoteEndpoint,
                std::bind(&UdpServer::HandleReceive, this, asio::placeholders::error));
    }

    void UdpServer::HandleReceive(const std::error_code& error)
    {
        if (!error)
        {
            std::shared_ptr<std::string> message(new std::string(MakeDaytimeString()));
    
            _socket.async_send_to(asio::buffer(*message), _remoteEndpoint,
                    std::bind(&UdpServer::HandleSend, this, message));
    
            StartReceive();
        }
    }


    void UdpServer::HandleSend(std::shared_ptr<std::string> /*message*/)
    {

    }
}