# DEV - BASE
FROM golang:1.12 AS dev

WORKDIR /app

RUN apt update && \
    apt install \
    bash \
    inotify-tools

RUN go get github.com/m3ng9i/ran && \
    go install github.com/m3ng9i/ran

RUN mkdir -p /app/rootfs/bin
RUN printf "#!/bin/sh\necho 'Please mount repo into /app'" > /app/rootfs/bin/init-dev
RUN chmod +x /app/rootfs/bin/init-dev

VOLUME ["/data"]
VOLUME ["/go"]

EXPOSE 80

ENTRYPOINT ["/app/rootfs/bin/init-dev"]


# TEST'n'BUILD
## API
FROM dev AS builder

COPY src /app/src
WORKDIR /app/src

RUN CGO_ENABLED=1 GOOS=linux go test ./ $(ls -d local/*) && \
    CGO_ENABLED=1 GOOS=linux go build -ldflags "-s -w" -o dims


# PROD
FROM alpine:3.9 AS prod

RUN apk upgrade -U && \
    apk add --update --no-cache \
    bash \
    coreutils \
    libc6-compat

RUN mkdir -p /app/bin
WORKDIR /app

COPY /rootfs /
COPY --from=builder /app/src/dims .

ENTRYPOINT ["/bin/init"]
