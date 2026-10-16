cmake_minimum_required(VERSION 3.0.2)
project(xgc2_geometry_msgs)

find_package(catkin REQUIRED COMPONENTS
  geometry_msgs
  message_generation
  std_msgs
)

add_message_files(
  FILES
  SceneGeometry.msg
  ScenePart.msg
  SceneObstacle.msg
  SceneGround.msg
  SceneSnapshot.msg
  SceneObstacleState.msg
  SceneState.msg
)

generate_messages(
  DEPENDENCIES
  geometry_msgs
  std_msgs
)

catkin_package(
  CATKIN_DEPENDS geometry_msgs message_runtime std_msgs
)

if(CATKIN_ENABLE_TESTING)
  catkin_add_nosetests(test/geometry_wire_test.py)
  catkin_add_nosetests(test/ground_wire_test.py)
endif()
