cmake_minimum_required(VERSION 3.16)
project(discord_luau_opus LANGUAGES C)

set(OPUS_SOURCE_DIR "" CACHE PATH "The extracted libopus source tree")

if(NOT EXISTS "${OPUS_SOURCE_DIR}/CMakeLists.txt")
	message(FATAL_ERROR "OPUS_SOURCE_DIR must point at an extracted libopus source tree, got '${OPUS_SOURCE_DIR}'")
endif()

add_subdirectory("${OPUS_SOURCE_DIR}" opus)
target_sources(opus PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/settings.c")
