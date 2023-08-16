#!/usr/bin/env bash

# 删除之前缓存的镜像
docker rmi sloaix/ci:latest

# 使用sloaix/ci:latest作为 docker tag
docker build -t sloaix/ci:latest ./ci
