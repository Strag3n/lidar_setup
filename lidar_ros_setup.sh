#!/bin/bash

# Exit on error
set -e
set -x

if grep -q Raspberry /proc/cpuinfo; then
    echo "Running on a Raspberry Pi"
else
    echo "Not running on a Raspberry Pi. Use at your own risk!"
fi

echo "Updating sources list"
sudo sed -i 's!^deb http://raspbian.raspberrypi.org/raspbian/.*$!deb http://mirrors.ustc.edu.cn/raspbian/raspbian/ buster main contrib non-free rpi!g' /etc/apt/sources.list 

echo "Installing Dependencies"
sudo apt update
sudo apt install -y build-essential cmake python3-rosdep python3-rosinstall-generator python3-wstool python3-rosinstall

echo "Initializing rosdep"
sudo rm -rf /etc/ros/rosdep/sources.list.d/*
sudo rosdep init
rosdep update || echo "rosdep update failed, check network"

echo "Creating workspace"
WORK_DIR="$HOME/ros_catkin_ws"
mkdir -p $WORK_DIR/src
cd $WORK_DIR

echo "Generating Noetic source list (recommended for Raspberry Pi)"
rosinstall_generator desktop --rosdistro noetic --deps --tar > noetic-desktop-wet.rosinstall
wstool init -j4 src noetic-desktop-wet.rosinstall

echo "Installing dependencies"
rosdep install --from-paths src --ignore-src --rosdistro noetic -y

echo "Building ROS (this may take a long time)"
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release --install-space /opt/ros/noetic -j1

echo "Cleaning up swap"
sudo swapoff /swapfile
sudo rm /swapfile

echo "Setting up ROS environment"
if [ -f /opt/ros/noetic/setup.bash ]; then
    echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
fi

echo "Installation complete. Reboot and test with: roscore"
