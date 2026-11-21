cmake_minimum_required(VERSION 3.16)
project(immanip_consumer LANGUAGES C)

find_package(immanip CONFIG REQUIRED)
add_executable(consumer ../test_immanip.c)
target_link_libraries(consumer PRIVATE immanip::immanip)
enable_testing()
add_test(NAME consumer COMMAND consumer)
