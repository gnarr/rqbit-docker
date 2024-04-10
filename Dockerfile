# Build stage with Rust Alpine base image
FROM rust:alpine as builder

# Install build dependencies, including OpenSSL for static linking
RUN apk update && \
    apk add --no-cache curl wget grep build-base openssl-dev musl-dev

WORKDIR /usr/src/rqbit

# Download and extract the latest release of rqbit
RUN curl -s https://api.github.com/repos/ikatson/rqbit/releases/latest | \
    grep "tarball_url" | grep -Eo 'https://[^\"]*' | xargs wget -O source.tar.gz && \
    tar -xzvf source.tar.gz --strip-components=1
    
ENV OPENSSL_LIB_DIR=/usr/lib
ENV OPENSSL_INCLUDE_DIR=/usr/include
    
# Build the project
RUN cargo build --profile release-github

# Runtime stage with a minimal base image
FROM alpine:latest

RUN apk --no-cache add ca-certificates libgcc openssl-dev

# Copy the compiled binary from the builder stage
COPY --from=builder /usr/src/rqbit/target/release/rqbit /usr/local/bin/rqbit

# Make binary executable
RUN chmod +x /usr/local/bin/rqbit

WORKDIR /usr/local/bin

CMD ["rqbit", "--http-api-listen-addr", "0.0.0.0:3030", "server", "start", "/downloads"]
