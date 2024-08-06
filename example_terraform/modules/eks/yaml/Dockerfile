FROM alpine:latest
LABEL maintainer="whitewhale1075 tgja1075@gmail.com"
RUN mkdir /lib64 && \
ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
mkdir /etc/config
COPY ./urmyserver /root
COPY ./config /etc/config
EXPOSE 3010
WORKDIR /root
ENTRYPOINT ["/bin/sh", "-c"]
CMD ["./urmyserver"]