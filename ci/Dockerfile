FROM openjdk:17-jdk-alpine3.14 

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && apk update && apk upgrade
RUN apk --no-cache add ca-certificates postgresql-client fish git curl tar gzip nodejs yarn go bash
# 软链接到/usr/local/bin
RUN ln -s /usr/bin/pg_dump /usr/local/bin/pg_dump
CMD [ "/bin/bash" ]