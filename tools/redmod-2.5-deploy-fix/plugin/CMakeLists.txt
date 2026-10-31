# ynk_redmod_bridge: a RED4ext plugin that finishes what REDmod's script compiler can't.
# Build:  cmake -S . -B build -A x64  &&  cmake --build build --config Release
# Output: build/Release/ynk_redmod_bridge.dll -> red4ext/plugins/ynk_redmod_bridge/
cmake_minimum_required(VERSION 3.23)
project(ynk_redmod_bridge VERSION 2.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")

include(FetchContent)
# Pinned to the SDK commit that updated the types for game patch 2.5
FetchContent_Declare(
  red4ext_sdk
  GIT_REPOSITORY https://github.com/wopss/RED4ext.SDK.git
  GIT_TAG 5246e659
)
set(RED4EXT_HEADER_ONLY ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(red4ext_sdk)

add_library(ynk_redmod_bridge SHARED src/Main.cpp)
target_link_libraries(ynk_redmod_bridge PRIVATE RED4ext::SDK)
target_compile_definitions(ynk_redmod_bridge PRIVATE WIN32_LEAN_AND_MEAN NOMINMAX)
