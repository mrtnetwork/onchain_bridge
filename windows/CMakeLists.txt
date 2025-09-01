cmake_minimum_required(VERSION 3.15)

set(PROJECT_NAME "on_chain_bridge")
set(WIL_VERSION "1.0.220201.1")
set(CPPWINRT_VERSION "2.0.220418.1")
project(${PROJECT_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.15...3.25)


include(FetchContent)

set(PLUGIN_NAME "on_chain_bridge_plugin")

FetchContent_Declare(nuget
  URL "https://dist.nuget.org/win-x86-commandline/v6.0.0/nuget.exe"
  URL_HASH SHA256=04eb6c4fe4213907e2773e1be1bbbd730e9a655a3c9c58387ce8d4a714a5b9e1
  DOWNLOAD_NO_EXTRACT true
)

find_program(NUGET nuget)
if (NOT NUGET)
    message("Nuget.exe not found, trying to download or use cached version.")
    FetchContent_MakeAvailable(nuget)
    set(NUGET ${nuget_SOURCE_DIR}/nuget.exe)
endif()

execute_process(COMMAND
    ${NUGET} install Microsoft.Windows.ImplementationLibrary -Version ${WIL_VERSION} -OutputDirectory ${CMAKE_BINARY_DIR}/packages
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    RESULT_VARIABLE ret)
if (NOT ret EQUAL 0)
    message(FATAL_ERROR "Failed to install nuget package Microsoft.Windows.ImplementationLibrary.${WIL_VERSION}")
endif()

execute_process(COMMAND
    ${NUGET} install Microsoft.Windows.CppWinRT -Version ${CPPWINRT_VERSION} -OutputDirectory packages
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    RESULT_VARIABLE ret)
if (NOT ret EQUAL 0)
    message(FATAL_ERROR "Failed to install nuget package Microsoft.Windows.CppWinRT.${CPPWINRT_VERSION}")
endif()

set(CPPWINRT ${CMAKE_BINARY_DIR}/packages/Microsoft.Windows.CppWinRT.${CPPWINRT_VERSION}/bin/cppwinrt.exe)
execute_process(COMMAND
    ${CPPWINRT} -input sdk -output include
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    RESULT_VARIABLE ret)
if (NOT ret EQUAL 0)
    message(FATAL_ERROR "Failed to run cppwinrt.exe")
endif()


include_directories(BEFORE SYSTEM ${CMAKE_BINARY_DIR}/include)
message(WARNING "Include directory: ${CMAKE_BINARY_DIR}/include")

list(APPEND PLUGIN_SOURCES
  "on_chain_bridge_plugin.cpp"
  "on_chain_bridge_plugin.h"
)

add_library(${PLUGIN_NAME} SHARED
  "include/on_chain_bridge/on_chain_bridge_plugin_c_api.h"
  "on_chain_bridge_plugin_c_api.cpp"
  "storage.cpp"
  "include/storage.hpp"
  "windows_manager.cpp"
  "include/windows_manager.hpp"
  ${PLUGIN_SOURCES}
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_compile_features(${PLUGIN_NAME} PRIVATE cxx_std_20)
target_compile_options(${PLUGIN_NAME} PRIVATE /await)
target_link_libraries(${PLUGIN_NAME} PRIVATE ${CMAKE_BINARY_DIR}/packages/Microsoft.Windows.ImplementationLibrary.${WIL_VERSION}/build/native/Microsoft.Windows.ImplementationLibrary.targets)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin comsuppw windowsapp dwmapi)
  
set(mrt_n_bundled_libraries
  ""
  PARENT_SCOPE
)

if(NOT DEFINED STORAGE_PREFIX)
  add_compile_definitions(SECURE_STORAGE_KEY_PREFIX="${BINARY_NAME}_VGhpcyBpcyB0aGUgcHJlZml4IGZv_")
else()
  add_compile_definitions(SECURE_STORAGE_KEY_PREFIX="${STORAGE_PREFIX}_VGhpcyBpcyB0aGUgcHJlZml4IGZv_")
endif()
