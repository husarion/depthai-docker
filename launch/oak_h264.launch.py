# Copyright 2026 Husarion sp. z o.o.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# The OAK's on-chip H.264 for a robot's Cockpit: depthai's camera as a component in a container.
#
#   <ns>/<name>/rgb/image_raw/compressed  ffmpeg_image_transport_msgs/FFMPEGPacket
#
# RGB only, encoded on the chip as H.264 baseline (profile 0, no B-frames), a keyframe every 30
# frames (one a second at 30 fps). No raw image, no IMU, no IR projector, and no description or
# transform: the robot's URDF places the OAK. The airlock of Husarion UGV OS (ros2-airlock 1.30.0
# and later) carries the FFMPEGPacket to the robot as it is.
#
#   ros2 launch /ros2_ws/launch/oak_h264.launch.py namespace:=panther ip:=10.15.20.6

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import ComposableNodeContainer
from launch_ros.descriptions import ComposableNode
from launch_ros.parameter_descriptions import ParameterValue


def generate_launch_description():
    namespace = LaunchConfiguration("namespace")
    name = LaunchConfiguration("name")
    ip = LaunchConfiguration("ip")
    bitrate = LaunchConfiguration("bitrate")

    args = [
        DeclareLaunchArgument("namespace", default_value="panther", description="Robot namespace"),
        DeclareLaunchArgument(
            "name", default_value="oak", description="The camera node's name; its topics follow it"
        ),
        DeclareLaunchArgument(
            "ip", default_value="10.15.20.6", description="The PoE OAK's address"
        ),
        DeclareLaunchArgument(
            "bitrate", default_value="3400000", description="The on-chip H.264 bitrate in bit/s"
        ),
    ]

    camera_params = {
        "camera.i_ip": ip,
        "camera.i_pipeline_type": "RGB",
        "camera.i_nn_type": "none",
        "camera.i_enable_imu": False,
        "pipeline_gen.i_enable_imu": False,
        "camera.i_enable_ir": False,
        "camera.i_publish_tf_from_calibration": False,
        "camera.i_restart_on_diagnostics_error": True,
        "rgb.i_fps": 30.0,
        "rgb.i_low_bandwidth": True,
        "rgb.i_low_bandwidth_profile": 0,
        "rgb.i_low_bandwidth_bitrate": ParameterValue(bitrate, value_type=int),
        "rgb.i_low_bandwidth_frame_freq": 30,
        "rgb.i_publish_compressed": True,
    }

    camera = ComposableNode(
        package="depthai_ros_driver",
        plugin="depthai_ros_driver::Camera",
        name=name,
        namespace=namespace,
        parameters=[camera_params],
    )

    container = ComposableNodeContainer(
        name=[name, "_container"],
        namespace=namespace,
        package="rclcpp_components",
        executable="component_container_mt",
        composable_node_descriptions=[camera],
        output="both",
    )

    return LaunchDescription(args + [container])
