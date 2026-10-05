cmake_minimum_required(VERSION 3.24)
set(CMAKE_SYSTEM_NAME WindowsStore)
set(CMAKE_SYSTEM_VERSION 10.0.19041.0 CACHE STRING "Xbox SDK")
project(MegaManX4RecompUWP C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(MMX4_UWP_DEPS "" CACHE PATH "Worley UWP dependencies (x64/bin, x64/lib, x64/include)")
option(MMX4_PLATFORM_CHECK "Compile the platform/runtime without generated game code" OFF)

if(NOT MSVC)
  message(FATAL_ERROR "Use MSVC and the Windows UWP SDK")
endif()

foreach(f include/SDL2/SDL.h lib/SDL2.lib bin/SDL2.dll)
  if(NOT EXISTS "${MMX4_UWP_DEPS}/x64/${f}")
    message(FATAL_ERROR "Missing UWP dependency: ${MMX4_UWP_DEPS}/x64/${f}")
  endif()
endforeach()

add_compile_definitions(PSX_UWP=1 WINAPI_FAMILY=WINAPI_FAMILY_APP NOMINMAX _CRT_SECURE_NO_WARNINGS)
set(PSX_SDL_BACKEND SDL2 CACHE STRING "" FORCE)
set(SDL2_INCLUDE_DIRS "${MMX4_UWP_DEPS}/x64/include;${MMX4_UWP_DEPS}/x64/include/SDL2")
set(SDL2_LIBRARIES "${MMX4_UWP_DEPS}/x64/lib/SDL2.lib")
set(PSX_RECOMP_UI OFF CACHE BOOL "" FORCE)
set(PSX_ENABLE_VULKAN OFF CACHE BOOL "" FORCE)
set(PSX_DEBUG_TOOLS OFF CACHE BOOL "" FORCE)
set(PSX_PGXP_VARIANT OFF CACHE BOOL "" FORCE)
set(PSX_REWIND OFF CACHE BOOL "" FORCE)
set(PSXRECOMP_BIOS_STEMS OpenBIOS CACHE STRING "" FORCE)
set(PSXRECOMP_SKIP_BIOS_STALE_CHECK ON CACHE BOOL "" FORCE)
set(PSXRECOMP_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/upstream/psxrecomp-v4")
set(PSXRECOMP_ALLOW_NO_BIOS ${MMX4_PLATFORM_CHECK} CACHE BOOL "" FORCE)
include("${PSXRECOMP_ROOT}/runtime/runtime.cmake")

set_property(SOURCE "${PSXRECOMP_ROOT}/runtime/src/starvation_ring.c"
  APPEND PROPERTY COMPILE_OPTIONS /experimental:c11atomics)

file(GLOB game_shards "${CMAKE_CURRENT_SOURCE_DIR}/upstream/generated/SLUS_005.61_full_*.c")
set(game_dispatch "${CMAKE_CURRENT_SOURCE_DIR}/upstream/generated/SLUS_005.61_dispatch.c")
if(NOT MMX4_PLATFORM_CHECK AND (NOT game_shards OR NOT EXISTS "${game_dispatch}"))
  message(FATAL_ERROR "Generate game code from your X4 USA disc with tools/generate.ps1 first.")
endif()

set(game_args)
if(game_shards AND EXISTS "${game_dispatch}")
  list(APPEND game_args
    GAME_GENERATED_FULL_C ${game_shards}
    GAME_GENERATED_DISPATCH_C "${game_dispatch}")
endif()

psxrecomp_add_runtime_target(mmx4 ${game_args}
  WINDOW_TITLE "Mega Man X4 Recomp UWP"
  EXE_NAME "MegaManX4"
  DEFAULT_GAME_CONFIG_PATH "game.toml"
  PRELOADED_MODS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/upstream/mods/preloaded"
  EXTRAS_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/upstream/src/mods/mmx4_damage_multiplier_plugin.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/upstream/src/mods/mmx4_fast_loading_plugin.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/upstream/src/mods/mmx4_frame_interpolation_plugin.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/upstream/src/mods/mmx4_widescreen_plugin.c")

get_target_property(link_flags mmx4 LINK_OPTIONS)
list(FILTER link_flags EXCLUDE REGEX "ENTRY:mainCRTStartup")
set_property(TARGET mmx4 PROPERTY LINK_OPTIONS "${link_flags}")
set_property(TARGET mmx4 PROPERTY WIN32_EXECUTABLE TRUE)
get_target_property(link_libs mmx4 LINK_LIBRARIES)
list(REMOVE_ITEM link_libs dbghelp comdlg32 iphlpapi ws2_32)
set_property(TARGET mmx4 PROPERTY LINK_LIBRARIES "${link_libs}")

target_link_libraries(mmx4 PRIVATE WindowsApp "${MMX4_UWP_DEPS}/x64/lib/libuwp.lib")
target_include_directories(mmx4 PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/uwp")
target_compile_options(mmx4 PRIVATE /bigobj /utf-8 /experimental:deterministic "/pathmap:${CMAKE_SOURCE_DIR}=.")
set_source_files_properties("${PSXRECOMP_ROOT}/runtime/src/main.cpp"
  PROPERTIES COMPILE_DEFINITIONS "main=mmx4_runtime_main")
set_source_files_properties("${PSXRECOMP_ROOT}/runtime/src/crash_trace.c"
  PROPERTIES COMPILE_DEFINITIONS "PSX_BUILD_REV=\"51f5f44-uwp-v0.0.5\"")

add_library(uwp_entry OBJECT uwp/winrt_main.cpp)
set_target_properties(uwp_entry PROPERTIES CXX_STANDARD 14)
target_compile_options(uwp_entry PRIVATE /ZW)
target_include_directories(uwp_entry PRIVATE ${SDL2_INCLUDE_DIRS})
target_sources(mmx4 PRIVATE uwp/launcher.cpp $<TARGET_OBJECTS:uwp_entry>)

target_sources(mmx4 PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/upstream/recomp-ui/src/common/recomp_runtime_ui.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/upstream/recomp-ui/src/common/recomp_runtime_settings.c")
target_include_directories(mmx4 PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/upstream/recomp-ui/src"
  "${CMAKE_CURRENT_SOURCE_DIR}/upstream/recomp-ui/src/common")
set(imgui "${CMAKE_CURRENT_SOURCE_DIR}/upstream/recomp-ui/src/third_party/imgui")
target_sources(mmx4 PRIVATE
  "${imgui}/imgui.cpp"
  "${imgui}/imgui_draw.cpp"
  "${imgui}/imgui_tables.cpp"
  "${imgui}/imgui_widgets.cpp"
  "${imgui}/backends/imgui_impl_sdl2.cpp"
  "${imgui}/backends/imgui_impl_opengl3.cpp")
target_include_directories(mmx4 PRIVATE "${imgui}" "${imgui}/backends")

target_link_directories(mmx4 BEFORE PRIVATE "$ENV{VCToolsInstallDir}/lib/x64/store")
target_link_options(mmx4 PRIVATE /APPCONTAINER /WINMD
  "/WINMDFILE:${CMAKE_BINARY_DIR}/MegaManX4.winmd"
  "/MAP:${CMAKE_BINARY_DIR}/MegaManX4.map")

foreach(f SDL2.dll libuwp.dll opengl32.dll libgallium_wgl.dll dxil.dll z-1.dll)
  configure_file("${MMX4_UWP_DEPS}/x64/bin/${f}" "${CMAKE_BINARY_DIR}/${f}" COPYONLY)
endforeach()
configure_file(upstream/game.toml "${CMAKE_BINARY_DIR}/game.toml" COPYONLY)

set(license_dir "${CMAKE_BINARY_DIR}/licenses")
file(MAKE_DIRECTORY "${license_dir}")
configure_file(LICENSE "${license_dir}/MegaManX4Recomp-LICENSE.txt" COPYONLY)
configure_file(upstream/psxrecomp-v4/LICENSE "${license_dir}/PSXRecomp-LICENSE.txt" COPYONLY)
configure_file(upstream/recomp-ui/LICENSE "${license_dir}/RecompUI-LICENSE.txt" COPYONLY)
configure_file(upstream/recomp-ui/src/third_party/imgui/LICENSE.txt "${license_dir}/ImGui-LICENSE.txt" COPYONLY)
configure_file("${CMAKE_BINARY_DIR}/_deps/psx_zlib-src/LICENSE" "${license_dir}/zlib-LICENSE.txt" COPYONLY)
foreach(f SDL-LICENSE.txt MESA-LICENSE.rst LIBUWP-LICENSE.txt DXIL-LICENSE.txt)
  configure_file("${MMX4_UWP_DEPS}/lic/${f}" "${license_dir}/${f}" COPYONLY)
endforeach()
