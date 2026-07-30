# 固定 Alpine 补丁版本，使基础系统升级成为显式、可审查的代码变更。
# Dependabot 会定期检查该标签是否有更新。
FROM alpine:3.24.1

# 使用 OCI 标准标签描述镜像，便于 Docker Hub 和镜像扫描工具识别其用途与源码。
LABEL org.opencontainers.image.title="sloaix/ci" \
      org.opencontainers.image.description="General-purpose CI toolchain based on Alpine Linux" \
      org.opencontainers.image.source="https://github.com/Sloaix/Dockerfile"

# 这些参数允许在 docker build 时覆盖默认时区和软件源，例如：
#   docker build --build-arg TIMEZONE=UTC --build-arg GO_PROXY=https://proxy.golang.org,direct .
ARG TIMEZONE=Asia/Shanghai
ARG GO_PROXY=https://goproxy.cn,direct
ARG NPM_REGISTRY=https://registry.npmmirror.com
ARG PIP_INDEX_URL=https://mirrors.cloud.tencent.com/pypi/simple

# 将构建参数保存为运行时环境变量：
# - TZ 供系统工具和应用确定时区；
# - GOPROXY、NPM_CONFIG_REGISTRY 和 PIP_INDEX_URL 分别供 Go、npm/pnpm 和 pip 使用。
ENV TZ="${TIMEZONE}" \
    GOPROXY="${GO_PROXY}" \
    NPM_CONFIG_REGISTRY="${NPM_REGISTRY}" \
    PIP_INDEX_URL="${PIP_INDEX_URL}"

# 使用 Alpine 3.24 稳定仓库中的当前版本，避免 stable/edge 混源造成依赖漂移。
# apk add --no-cache 不会把软件包索引保留在镜像层中，可以减少最终镜像体积。
# build-base 提供 GCC、G++、Make、标准库头文件和常用链接工具，用于 Go cgo、
# JNI 以及 node-gyp 等需要编译原生扩展的 JavaScript/TypeScript 依赖。
# CMake、Samurai（提供 Ninja 兼容命令）和 pkgconf 补齐现代跨语言项目
# 常用的原生构建链。Alpine 的 ninja-build 不会把 ninja 放入默认 PATH，
# 因此使用更轻量且命令兼容的 samurai。
# protoc 只提供跨语言 Protobuf 编译器；各语言插件仍由具体项目锁定版本。
# docker-cli 只安装客户端；docker-cli-buildx 提供现代 docker buildx 命令，
# 不在 CI 工具箱中安装并运行不必要的 Docker daemon。
# Python 的 arrow 和 requests 直接使用 Alpine 包，避免绕过系统包管理器执行 pip 安装。
RUN apk add --no-cache \
        bash \
        build-base \
        ca-certificates \
        cmake \
        coreutils \
        curl \
        deno \
        deno-bash-completion \
        deno-fish-completion \
        docker-cli \
        docker-cli-buildx \
        ffmpeg \
        findutils \
        fish \
        gcompat \
        git \
        go \
        gradle \
        jq \
        maven \
        samurai \
        nodejs \
        npm \
        openjdk21 \
        openssh-client-default \
        pkgconf \
        pnpm \
        postgresql18-client \
        protoc \
        py3-arrow \
        py3-pip \
        py3-requests \
        python3 \
        rsync \
        sshpass \
        tar \
        tzdata \
        unzip \
        wget \
        yq-go \
        yarn \
        zip \
    # pg_dump 本身位于 /usr/bin；保留旧镜像提供过的 /usr/local/bin 路径以兼容现有脚本。
    && ln -sf /usr/bin/pg_dump /usr/local/bin/pg_dump \
    # 写入系统时区配置，并让 /etc/localtime 指向 tzdata 提供的目标时区。
    && echo "${TZ}" > /etc/timezone \
    && ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime

# 直接运行镜像时进入 Bash；在 CI 中也可以通过 docker run 传入其他命令覆盖它。
CMD ["/bin/bash"]
