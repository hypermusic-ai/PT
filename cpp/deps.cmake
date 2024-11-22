cmake_minimum_required(VERSION 3.20)

include(FetchContent)

message(STATUS "declaring additional dependencies ...")

FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG        703bd9caab50b139428cea1aaff9974ebee5742e # release-1.10.0
)
message(STATUS "declaring `googletest` dependency")

FetchContent_Declare(
  asio
  GIT_REPOSITORY https://github.com/chriskohlhoff/asio.git
  GIT_TAG        03ae834edbace31a96157b89bf50e5ee464e5ef9 # release-1.32.0
)
message(STATUS "declaring `asio` dependency")
