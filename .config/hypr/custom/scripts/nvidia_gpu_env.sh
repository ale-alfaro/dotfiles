#!/bin/bash

if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU Information:"
    source  "nvidia_gpu.conf"
else
    echo "NVIDIA drivers or nvidia-smi not found."
fi
