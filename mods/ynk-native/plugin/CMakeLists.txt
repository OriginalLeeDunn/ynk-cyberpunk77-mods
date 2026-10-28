# ynk_native: a RED4ext plugin (C++ DLL) that adds native functions for redscript.
# Build:  cmake -S . -B build -A x64  &&  cmake --build build --config Release
# Output: build/Release/ynk_native.dll -> red4ext/plugins/ynk_native/
cmake_minimum_required(VERSION 3.23)
project(ynk_native VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)
# Pinned to the SDK commit that updated the types for game patch 2.5
FetchContent_Declare(
  red4ext_sdk
  GIT_REPOSITORY https://github.com/wopss/RED4ext.SDK.git
  GIT_TAG 5246e659
)
set(RED4EXT_HEADER_ONLY ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(red4ext_sdk)

add_library(ynk_native SHARED src/Main.cpp)
target_link_libraries(ynk_native PRIVATE RED4ext::SDK)
target_compile_definitions(ynk_native PRIVATE WIN32_LEAN_AND_MEAN NOMINMAX)
