ARG ROS_DISTRO=jazzy
ARG PREFIX=

# Stock depthai-ros from the ROS apt repository, pinned per distro, built for amd64 and arm64,
# plus one small package of ours: the H.264 relay in relay/husarion_ugv_video_relay, which copies
# the OAK's FFMPEGPacket into a foxglove_msgs/CompressedVideo (see the README). Nothing of
# depthai-ros is compiled: the release packages of the ROS buildfarm are installed as they are.
# Only the relay is compiled, in the `relay-build` stage, against the very packages the final
# image carries, and only its install tree is copied over.
#
# `apt-get upgrade` first: the base image can lag the ROS apt repository, and packages built
# against a newer core library then fail at run time (e.g. ffmpeg_image_transport_msgs 1.3.0's
# Fast DDS type support needs a newer ros-jazzy-fastcdr than 2.2.5: `undefined symbol
# _ZN8eprosima7fastcdr3Cdr9serializeEm` on the first FFMPEGPacket).
#
# A pin that the apt repository no longer carries fails the build loudly rather than installing
# another version. To move a pin, change the version below and check the parameter names that
# launch/oak_h264.launch.py sets (e.g. `rgb.i_low_bandwidth`, `rgb.i_publish_compressed`).
#
#   jazzy:  depthai-ros 2.13.0 (depthai core 2.33.0)
#   humble: depthai-ros 2.12.2 (depthai core 2.31.1)
#
# The relay's tests are built only in the `relay-test` stage, which the image does not depend on,
# and they run in a container from it, not in the image build:
#   docker build --target relay-test -t depthai-relay-test .
#   docker run --rm depthai-relay-test bash -c "source /opt/ros/\$ROS_DISTRO/setup.bash && \
#     cd /relay_ws && colcon test --event-handlers console_direct+ && colcon test-result --verbose"

FROM husarnet/ros:${PREFIX}${ROS_DISTRO}-ros-core AS base

ARG PREFIX
ENV PREFIX_ENV=$PREFIX

# select bash as default shell
SHELL ["/bin/bash", "-c"]

RUN case "$ROS_DISTRO" in \
        jazzy)  DEPTHAI_ROS_VERSION=2.13.0; DEPTHAI_CORE_VERSION=2.33.0 ;; \
        humble) DEPTHAI_ROS_VERSION=2.12.2; DEPTHAI_CORE_VERSION=2.31.1 ;; \
        *) echo "no depthai-ros pin for ROS_DISTRO=$ROS_DISTRO" >&2; exit 1 ;; \
    esac && \
    pkg() { echo "ros-${ROS_DISTRO}-$1=$2-*"; } && \
    apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends \
        $(pkg depthai "$DEPTHAI_CORE_VERSION") \
        $(pkg depthai-bridge "$DEPTHAI_ROS_VERSION") \
        $(pkg depthai-descriptions "$DEPTHAI_ROS_VERSION") \
        $(pkg depthai-ros-driver "$DEPTHAI_ROS_VERSION") \
        $(pkg depthai-ros-msgs "$DEPTHAI_ROS_VERSION") \
        ros-${ROS_DISTRO}-ffmpeg-image-transport-msgs \
        ros-${ROS_DISTRO}-foxglove-msgs \
        ros-${ROS_DISTRO}-rclcpp-components \
        ros-${ROS_DISTRO}-rmw-cyclonedds-cpp && \
    echo "$DEPTHAI_ROS_VERSION" > /version.txt && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# The relay, compiled against the base stage's message packages; the final image takes its install
# tree only.
FROM base AS relay-build

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        python3-colcon-common-extensions \
        ros-${ROS_DISTRO}-ament-cmake \
        ros-${ROS_DISTRO}-ament-cmake-gtest && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY relay /relay_ws/src

RUN source /opt/ros/$ROS_DISTRO/setup.bash && \
    cd /relay_ws && \
    MAKEFLAGS=-j2 colcon build \
        --merge-install \
        --install-base /ros2_ws/install \
        --event-handlers console_direct+ \
        --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF

# The relay again, with its tests (see the top of this file). Not part of the image.
FROM relay-build AS relay-test

RUN source /opt/ros/$ROS_DISTRO/setup.bash && \
    cd /relay_ws && \
    MAKEFLAGS=-j2 colcon build \
        --merge-install \
        --install-base /ros2_ws/install \
        --event-handlers console_direct+ \
        --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON

FROM base

# The image's entrypoint sources /ros2_ws/install/setup.bash when it exists.
COPY --from=relay-build /ros2_ws/install /ros2_ws/install
COPY launch /ros2_ws/launch
