#pragma once
#include <server.hpp>
#include <memory>
#include <array>

namespace pt::network
{
    class TcpConnection : public std::enable_shared_from_this<TcpConnection>
    {
        public:
            typedef std::shared_ptr<TcpConnection> pointer;

            static pointer Create(asio::io_context& ioContext);
            asio::ip::tcp::socket & Socket();
            void Start();

        protected:
            TcpConnection(asio::io_context & ioContext);
            void HandleRequest(std::size_t length);
            void WriteResponse(const std::string & response);

        private:
            asio::ip::tcp::socket _socket;
            std::string _message;
            std::array<char, 1024> _buffer;
    };

    class TcpServer
    {
        public:
            TcpServer(asio::io_context & ioContext, asio::ip::port_type port);

        protected:
            void StartAccept();
            void HandleAccept(TcpConnection::pointer newConnection, const std::error_code& error);
        
        private:
            asio::io_context& _ioContext;
            asio::ip::tcp::acceptor _acceptor;
    };
}