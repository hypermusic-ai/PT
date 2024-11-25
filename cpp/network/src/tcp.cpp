#include <tcp.hpp>

namespace pt::network
{
    // Function to generate an HTTP response
    std::string CreateResponse(const std::string& request) {
        std::string body = "<html><body><h1>PT-node TCP Server</h1></body></html>";
        std::string response = 
            "HTTP/1.1 200 OK\r\n"
            "Content-Length: " + std::to_string(body.size()) + "\r\n"
            "Content-Type: text/html\r\n"
            "Connection: keep-alive\r\n\r\n" + 
            body;
        return response;
    }

    TcpConnection::TcpConnection(asio::io_context& ioContext)
        : _socket(ioContext)
    {
    }

    TcpConnection::pointer TcpConnection::Create(asio::io_context& ioContext)
    {
        return pointer(new TcpConnection(ioContext));
    }

    asio::ip::tcp::socket & TcpConnection::Socket()
    {
        return _socket;
    }

    void TcpConnection::Start()
    {
        std::cout<<std::format("TCP new connection {} \n", _socket.local_endpoint().address().to_string());

        auto self(shared_from_this());

        _socket.async_read_some(asio::buffer(_buffer),
            [this, self](std::error_code ec, std::size_t length) {
                if (!ec) {
                    HandleRequest(length);
                }
            });
    }

    void TcpConnection::HandleRequest(std::size_t length) {
        std::string request(_buffer.data(), length);
        std::string response = CreateResponse(request);
        WriteResponse(response);
    }

    void TcpConnection::WriteResponse(const std::string& response) 
    {
        auto self(shared_from_this());

        asio::async_write(_socket, asio::buffer(response),
            [this, self](std::error_code ec, std::size_t /*length*/) {
                if (!ec) {
                    _socket.close();
                }
            });
    }

    TcpServer::TcpServer(asio::io_context & ioContext, asio::ip::port_type port)
        : _ioContext(ioContext),
          _acceptor(ioContext, asio::ip::tcp::endpoint(asio::ip::tcp::v4(), port))
    {
        std::cout<<std::format("TCP server started on port {} \n", port);
        StartAccept();
    }

    void TcpServer::StartAccept()
    {
        TcpConnection::pointer newConnection = TcpConnection::Create(_ioContext);

        _acceptor.async_accept(newConnection->Socket(),
                std::bind(&TcpServer::HandleAccept, this, newConnection, asio::placeholders::error));
    }
    
    void TcpServer::HandleAccept(TcpConnection::pointer newConnection, const std::error_code& error)
    {
        if (!error)
        {   
            newConnection->Start();
        }

        StartAccept();
    }
}