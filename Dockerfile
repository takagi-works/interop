# Dockerfile for Takagi CoAP Interoperability Tests
# Includes all CoAP client implementations for comprehensive testing

FROM ruby:3.0-slim

LABEL maintainer="takagi-team"
LABEL description="CoAP Interoperability Testing Environment"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    git \
    curl \
    wget \
    # libcoap dependencies
    autoconf \
    automake \
    libtool \
    pkg-config \
    libssl-dev \
    # Python and pip
    python3 \
    python3-pip \
    python3-dev \
    # Node.js and npm
    nodejs \
    npm \
    # Java (for Californium) - optional
    # openjdk-11-jre-headless \
    # Utilities
    netcat-openbsd \
    lsof \
    && rm -rf /var/lib/apt/lists/*

# Install libcoap from source (latest version)
RUN cd /tmp && \
    git clone --depth 1 https://github.com/obgm/libcoap.git && \
    cd libcoap && \
    ./autogen.sh && \
    ./configure --disable-documentation --disable-tests && \
    make && \
    make install && \
    ldconfig && \
    cd / && rm -rf /tmp/libcoap

# Install aiocoap (Python CoAP client)
RUN pip3 install --no-cache-dir 'aiocoap[all]'

# Install node-coap (JavaScript CoAP client)
RUN npm install -g coap-cli

# Optional: Install Californium CLI client (Java)
# Uncomment if needed for testing
# RUN mkdir -p /opt/californium && \
#     cd /opt/californium && \
#     wget https://repo.eclipse.org/content/repositories/californium-releases/org/eclipse/californium/cf-plugtest-client/3.8.0/cf-plugtest-client-3.8.0.jar \
#     -O cf-client.jar

# Create app directory
WORKDIR /app

# Copy Gemfile first for better caching
COPY Gemfile Gemfile.lock* ./

# Install Ruby dependencies
RUN bundle install

# Copy application code
COPY . .

# Environment variables
ENV COAP_PORT=5683
ENV COAP_TIMEOUT=5
ENV VERBOSE=0

# Expose CoAP ports
EXPOSE 5683/udp
EXPOSE 5683/tcp

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD coap-client -m get coap://localhost:5683/ping || exit 1

# Default command - run tests
CMD ["bundle", "exec", "rspec", "--format", "documentation"]

# Alternative commands:
# Run specific suite:
#   docker run takagi-interop-tests bundle exec rspec spec/rfc7252_core/
#
# Start server only:
#   docker run -p 5683:5683/udp takagi-interop-tests ruby takagi_app/server.rb
#
# Interactive shell:
#   docker run -it takagi-interop-tests bash
#
# Run with specific client:
#   docker run -e COAP_CLIENTS=libcoap takagi-interop-tests
