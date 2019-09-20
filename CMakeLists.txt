cmake_minimum_required (VERSION 3.9.0)



project(RayTracer)

set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set (CMAKE_CXX_FLAGS "-ldl -D_GLIBCXX_DEBUG")
set(CMAKE_BUILD_TYPE Debug)

set(CMAKE_MODULE_PATH /usr/share/cmake/)
#include_directories(glad)
find_package(glfw3)
find_package(glm REQUIRED)
#add_subdirectory(glfw-3.2.1)

add_executable(main 
    src/main.cpp 
    src/glad.c 
	src/rayTracer.cpp
	src/render.cpp
	src/shader.cpp
)
include_directories(${GLFW_INCLUDE_DIRS} )
include_directories(${GLM_INCLUDE_DIRS})

target_link_libraries(main glfw glm)

#target_link_libraries(main ${GLFW_LIBRARIES})
