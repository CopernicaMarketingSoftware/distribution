ARG GO_VERSION=1.17

FROM golang:${GO_VERSION}-bullseye AS build

ENV GO111MODULE=auto
ENV DISTRIBUTION_DIR /go/src/github.com/distribution/distribution
ENV BUILDTAGS include_oss include_gcs

ARG GOOS=linux
ARG GOARCH=amd64
ARG GOARM=6
ARG VERSION
ARG REVISION

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update; apt-get -y install file

WORKDIR $DISTRIBUTION_DIR
COPY . $DISTRIBUTION_DIR
RUN CGO_ENABLED=0 make PREFIX=/go clean binaries && file ./bin/registry | grep "statically linked"

FROM debian:bullseye-slim

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update; apt-get -y install ca-certificates
RUN apt-get -y clean; apt-get -y autoclean; apt-get -y autoremove

COPY cmd/registry/config-dev.yml /etc/docker/registry/config.yml
COPY --from=build /go/src/github.com/distribution/distribution/bin/registry /bin/registry
VOLUME ["/var/lib/registry"]
EXPOSE 5000
ENTRYPOINT ["registry"]
CMD ["serve", "/etc/docker/registry/config.yml"]
