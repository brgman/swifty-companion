FROM ubuntu:22.04 as build
ARG FLUTTER_VERSION=3.41.6
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*


RUN git clone https://github.com/flutter/flutter.git /opt/flutter \
    && cd /opt/flutter \
    && git checkout ${FLUTTER_VERSION}

ENV PATH="opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web --release || echo "expected fail (build triggered to preload web page)"

# runtime stage

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html