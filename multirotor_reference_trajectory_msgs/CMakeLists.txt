cmake_minimum_required(VERSION 3.0.2)
project(multirotor_reference_trajectory_msgs)

find_package(catkin REQUIRED COMPONENTS
  geometry_msgs
  message_generation
  std_msgs
)

add_message_files(
  FILES
  AnalyticReference.msg
  FlatReferencePoint.msg
  ReferenceStatus.msg
  SampledReference.msg
)

generate_messages(
  DEPENDENCIES
  geometry_msgs
  std_msgs
)

catkin_package(
  CATKIN_DEPENDS geometry_msgs message_runtime std_msgs
)

install(DIRECTORY msg/
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/msg
  FILES_MATCHING PATTERN "*.msg"
)
