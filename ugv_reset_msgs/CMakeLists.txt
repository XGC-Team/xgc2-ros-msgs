cmake_minimum_required(VERSION 3.0.2)
project(ugv_reset_msgs)

find_package(catkin REQUIRED COMPONENTS
  geometry_msgs
  message_generation
  std_msgs
)

add_message_files(
  FILES
  ResetSession.msg
  ResetGrant.msg
  ResetResult.msg
  ResetFleetMember.msg
  ResetFleet.msg
)

generate_messages(
  DEPENDENCIES
  geometry_msgs
  std_msgs
)

catkin_package(
  CATKIN_DEPENDS geometry_msgs message_runtime std_msgs
)
