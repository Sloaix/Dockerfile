#!/usr/bin/env bash

# 使用严格模式，让缺失命令、未定义变量或管道错误立即导致测试失败：
# -e：命令失败时退出；
# -u：使用未定义变量时报错；
# -o pipefail：管道中任意命令失败时，整条管道都视为失败。
set -euo pipefail

# 第一个位置参数是待测试的镜像；未传入时验证默认的本地镜像。
# 示例：
#   ./ci/test.sh sloaix/ci:local
image="${1:-sloaix/ci:local}"

# 启动一次性容器执行全部检查：
# --rm 会在测试结束后自动删除容器；
# 容器内同样启用 Bash 严格模式，任何一项检查失败都会返回非零状态；
# 外层脚本会继承 docker run 的退出状态，因此 CI 能正确识别失败。
docker run --rm "${image}" bash -euo pipefail -c '
# 列出镜像承诺提供的主要可执行文件。
# 这里只验证命令是否可调用，不启动 Docker daemon、数据库等后台服务。
commands=(
    bash cmake curl deno docker ffmpeg find fish g++ gcc git go gradle
    java jq make mvn ninja node npm pg_dump pip3 pkgconf pnpm protoc
    python3 rsync ssh sshpass tar unzip wget yarn yq zip
)

# command -v 不执行程序，只检查命令能否通过 PATH 找到。
# 缺少命令时打印具体名称，方便从本地或 Actions 日志直接定位问题。
for command in "${commands[@]}"; do
    if ! command -v "${command}" >/dev/null; then
        echo "Missing required command: ${command}" >&2
        exit 1
    fi
done

# 确认通过 Alpine 包安装的 Python 第三方模块可以正常导入。
python3 -c "import arrow, requests"

# 确认 Go、npm 和 pip 的软件源配置存在且使用 HTTP(S) 地址。
# 这里只检查配置结构，不绑定默认国内源，因此使用自定义构建参数的镜像也能通过。
[[ "$(go env GOPROXY)" == http* ]]
[[ "$(npm config get registry)" == http* ]]
[[ "${PIP_INDEX_URL}" == http* ]]

# 确认 TZ 指向的时区数据已经由 tzdata 正确安装。
test -e "/usr/share/zoneinfo/${TZ}"

# 输出核心组件的实际版本。这些信息会保留在本地终端或 GitHub Actions
# 日志中，便于确认一次发布究竟包含了哪些软件版本。
go version
node --version
deno --version
python3 --version
java -version
pg_dump --version
docker --version
docker buildx version
cmake --version | sed -n "1p"
ninja --version
protoc --version
jq --version
yq --version

# FFmpeg、Gradle 和 Maven 的版本命令会输出多行内容，只保留最有用的前几行，
# 同时使用 sed（而不是提前关闭管道的 head）以兼容 pipefail 严格模式。
ffmpeg -version | sed -n "1p"
gradle --version | sed -n "1,4p"
mvn --version | sed -n "1,3p"
'

# 只有 docker run 及容器内所有检查都成功后，脚本才会执行到这里。
echo "Smoke test passed: ${image}"
