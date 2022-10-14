# Unstable version
FROM alpine:edge

# Add testing repo
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories

# Add bindfs
RUN apk add --no-cache bindfs

#
# Compile and install restrictive shell
#
RUN apk add --no-cache build-base 
COPY restrict.c /
RUN gcc restrict.c -o /usr/local/bin/restrict
RUN rm /restrict.c
RUN apk del build-base

# Install dependencies/programs
RUN apk add --no-cache openssh-server unison bash rsync shadow shadow-login

# Generate SSH keys
RUN ssh-keygen -A

# Create (external) users dir
RUN mkdir /users
RUN chmod 755 /users
RUN chown root:root /users

# Set up SSH server
COPY sshd_config /etc/ssh/sshd_config
RUN chmod 644 /etc/ssh/sshd_config
RUN chown root:root /etc/ssh/sshd_config

# Setup group
RUN groupadd -g 60 sshjail

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod 700 /entrypoint.sh
RUN chown root:root /entrypoint.sh

VOLUME /keys /etc/ssh /users

ENTRYPOINT ["/entrypoint.sh"]

