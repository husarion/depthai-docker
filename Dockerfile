ARG ROS_DISTRO=jazzy
ARG PREFIX=

# Stock depthai-ros from the ROS apt repository, pinned per distro, built for amd64 and arm64.
# Nothing is compiled: the release packages of the ROS buildfarm are installed as they are.
#
# A pin that the apt repository no longer carries fails the build loudly rather than installing
# another version. To move a pin, change the version below and check the parameter names the
# compose files use (e.g. `rgb.i_low_bandwidth`, `rgb.i_publish_compressed`).
#
#   jazzy:  depthai-ros 2.13.0 (depthai core 2.33.0)
#   humble: depthai-ros 2.12.2 (depthai core 2.31.1)

FROM husarnet/ros:${PREFIX}${ROS_DISTRO}-ros-core

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
    apt-get install -y --no-install-recommends \
        $(pkg depthai "$DEPTHAI_CORE_VERSION") \
        $(pkg depthai-bridge "$DEPTHAI_ROS_VERSION") \
        $(pkg depthai-descriptions "$DEPTHAI_ROS_VERSION") \
        $(pkg depthai-ros-driver "$DEPTHAI_ROS_VERSION") \
        $(pkg depthai-ros-msgs "$DEPTHAI_ROS_VERSION") \
        ros-${ROS_DISTRO}-ffmpeg-image-transport-msgs \
        ros-${ROS_DISTRO}-rmw-cyclonedds-cpp && \
    echo "$DEPTHAI_ROS_VERSION" > /version.txt && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
