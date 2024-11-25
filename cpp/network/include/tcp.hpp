#pragma once
#include <server.hpp>
#include <memory>

namespace pt::network
{
    class TcpConnection : public std::enable_shared_from_this<TcpConnection>
    {
        public:
            typedef std::shared_ptr<TcpConnection> pointer;

        static pointer Create(asio::io_context& ioContext)
        {
            return pointer(new TcpConnection(ioContext));
        }

        asio::ip::tcp::socket & Socket()
        {
            return _socket;
        }

        void start()
        {
            _message = MakeDaytimeString();

            asio::async_write(_socket, asio::buffer(_message),
                std::bind(&TcpConnection::HandleWrite, shared_from_this()));
        }

    private:
        TcpConnection(asio::io_context& ioContext)
        : _socket(ioContext)
        {
        }

        void HandleWrite()
        {
        }

        asio::ip::tcp::socket _socket;
        std::string _message;
    };

    class TcpServer
    {
        public:
        TcpServer(asio::io_context & ioContext)
        : _ioContext(ioContext),
          _acceptor(ioContext, asio::ip::tcp::endpoint(asio::ip::tcp::v4(), 13))
        {
            StartAccept();
        }

    private:
      void StartAccept()
      {
        TcpConnection::pointer newConnection = TcpConnection::Create(_ioContext);

        _acceptor.async_accept(newConnection->Socket(),
            std::bind(&TcpServer::HandleAccept, this, newConnection, asio::placeholders::error));
      }

        void HandleAccept(TcpConnection::pointer newConnection, const std::error_code& error)
        {
            if (!error)
            {
                newConnection->start();
            }

            StartAccept();
        }

        asio::io_context& _ioContext;
        asio::ip::tcp::acceptor _acceptor;
    };
}