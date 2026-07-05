cmake_minimum_required(VERSION 3.0.2)
project(state_machine_msgs)

find_package(catkin REQUIRED COMPONENTS
  std_msgs
  message_generation
)

add_message_files(
  FILES
  StateMachineTrace.msg
  StateMachineTraceEvent.msg
)

generate_messages(
  DEPENDENCIES
  std_msgs
)

catkin_package(
  CATKIN_DEPENDS std_msgs message_runtime
)

install(DIRECTORY msg/
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/msg
  FILES_MATCHING PATTERN "*.msg"
)
