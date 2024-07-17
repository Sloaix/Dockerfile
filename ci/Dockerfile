FROM alpine:3.20.1

#定义时区环境变量
ENV  TIME_ZONE=Asia/Shanghai

# 添加edge软件源
RUN \
    echo -e 'https://dl-cdn.alpinelinux.org/alpine/edge/main\nhttps://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    # 替换成国内镜像源,使用github action构建的时候注释掉,在本地构建验证的时候可以反注释
    # && sed -i 's/dl-cdn.alpinelinux.org/mirrors.cloud.tencent.com/g' /etc/apk/repositories \
    # 更新软件源
    && apk update \
    # 安装最新版本的软件
    && apk --no-cache add \
    'postgresql16-client>16' \
    'deno>=1.43.5' \
    'deno-bash-completion>=1.43.5' \
    'deno-fish-completion>=1.43.5' \
    'fish>3.3' \
    'nodejs>18' \
    'go>1.20' \
    'ffmpeg>5.0' \
    sshpass \
    tzdata \
    docker \
    npm \
    yarn \
    openjdk17 \
    python3 \
    py3-pip \
    gradle \
    maven \
    git \
    curl \
    wget \
    bash \
    rsync \
    && echo "apk install successed" \
    # 安装pnpm
    && npm i -g pnpm \
    && echo "pnpm install successed" \
    # 软链接到/usr/local/bin
    && ln -s /usr/bin/pg_dump /usr/local/bin/pg_dump \
    && echo "ln -s pg_dump successed" \
    # 配置npm使用国内镜像源
    && npm i -g nrm && nrm use taobao \
    && echo "npm config successed" \
    # 配置go使用国内镜像源
    && go env -w GO111MODULE=on && go env -w GOPROXY=https://goproxy.cn,direct \
    # 配置python国内镜像源
    && pip3 config set global.index-url https://mirrors.cloud.tencent.com/pypi/simple \
    # python3最新版本已经不允许直接在系统目录下安装库,需要配置pip.conf
    # see https://stackoverflow.com/questions/75608323/how-do-i-solve-error-externally-managed-environment-everytime-i-use-pip3
    && echo -e '[global]\nbreak-system-packages = true' > ~/.config/pip/pip.conf \
    # 安装python需要使用到的库
    && pip3 install requests arrow \
    # 配置时区
    && echo "${TIME_ZONE}" > /etc/timezone && ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime && date 
CMD [ "/bin/bash" ]