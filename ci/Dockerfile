FROM alpine:3.14

#定义时区环境变量
ENV  TIME_ZONE Asia/Shanghai

# 添加edge软件源
RUN echo -e 'https://dl-cdn.alpinelinux.org/alpine/edge/main\nhttps://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    # 替换成国内镜像源,使用github action构建的时候注释掉,在本地构建验证的时候可以反注释
    # && sed -i 's/dl-cdn.alpinelinux.org/mirrors.cloud.tencent.com/g' /etc/apk/repositories \
    # 更新软件源
    && apk update \
    # 安装最新版本的软件
    && apk --no-cache add \
    'postgresql14-client>14' \
    'fish>3.3' \
    'nodejs>14' \
    'go>1.17' \
    'ffmpeg>4.4' \
    tzdata \
    npm \
    yarn \
    openjdk17 \
    python3 \
    py3-pip \
    git \
    curl \
    wget \
    bash \
    rsync \
    # 软链接到/usr/local/bin
    && ln -s /usr/bin/pg_dump /usr/local/bin/pg_dump \
    # 配置npm使用国内镜像源
    && npm i -g nrm && nrm use tencent \
    # 配置go使用国内镜像源
    && go env -w GO111MODULE=on && go env -w GOPROXY=https://goproxy.cn,direct \
    # 配置python国内镜像源
    && pip3 config set global.index-url https://mirrors.cloud.tencent.com/pypi/simple \
    # 配置时区
    && echo "${TIME_ZONE}" > /etc/timezone && ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime && date
CMD [ "/bin/bash" ]