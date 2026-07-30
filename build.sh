#!/usr/bin/env bash

# 遇到错误时立即退出，避免构建失败后脚本仍继续执行：
# -e：任意命令返回非零状态时退出；
# -u：使用未定义变量时报错；
# -o pipefail：管道中任意命令失败时，整条管道都视为失败。
set -euo pipefail

# 解析脚本所在目录，使用户从任意工作目录调用本脚本时都能找到 ci 目录。
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# 本地构建统一使用 local 标签，不参与正式版本计算。
# IMAGE_NAME 和 IMAGE_TAG 只用于需要区分多个本地构建的高级场景，例如：
#   IMAGE_NAME=my-account/ci IMAGE_TAG=experiment ./build.sh
image_name="${IMAGE_NAME:-sloaix/ci}"
image_tag="${IMAGE_TAG:-local}"

# 不再接受位置参数，避免把本地临时标签误认为正式发布版本。
# 正式版本由 GitHub Actions 根据 patch/minor/major 选择自动生成。
if (( $# != 0 )); then
    echo "Usage: ./build.sh" >&2
    echo "Use IMAGE_TAG only when a custom local tag is required." >&2
    exit 1
fi

# 自定义本地标签仍需符合 Docker 标签格式。
if [[ ! "${image_tag}" =~ ^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$ ]]; then
    echo "Invalid Docker image tag: ${image_tag}" >&2
    exit 1
fi

# --pull 会检查并拉取 Dockerfile 中基础镜像标签对应的最新镜像。
build_options=(--pull)

# 默认禁用构建缓存，确保 apk add 从 Alpine 仓库安装当前可用版本。
# 开发期间如果 Dockerfile 没有变化，可以设置 USE_CACHE=1 加速重复构建：
#   USE_CACHE=1 ./build.sh
if [[ "${USE_CACHE:-0}" != "1" ]]; then
    build_options+=(--no-cache)
fi

# 使用项目中的 ci 目录作为构建上下文，并生成“镜像名:标签”形式的本地镜像。
# 数组展开会保留每个参数的边界，避免镜像名或选项被错误拆分。
docker build "${build_options[@]}" --tag "${image_name}:${image_tag}" "${script_dir}/ci"

# 构建成功后立即调用统一的冒烟测试脚本。
# 测试失败会通过严格模式终止 build.sh，避免未验证镜像进入后续提交流程。
"${script_dir}/ci/test.sh" "${image_name}:${image_tag}"

# 构建与测试全部通过后输出结果。
echo
echo "Build and smoke test passed: ${image_name}:${image_tag}"
echo "Next step: ./submit.sh \"chore: describe your change\""
