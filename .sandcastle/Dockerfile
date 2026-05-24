FROM node:24-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
  git \
  curl \
  jq \
  luajit \
  lua5.4 \
  && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && apt-get update && apt-get install -y gh \
  && rm -rf /var/lib/apt/lists/*

# Build-args for UID/GID alignment: sandcastle docker build-image
# defaults these to the host user's UID/GID so image-built files
# and bind-mounted files share an owner without runtime chown.
ARG AGENT_UID=1000
ARG AGENT_GID=1000

# Rename the base image's "node" user to "agent" and align UID/GID.
# On macOS the host user's primary GID is often 20, which already exists in
# Debian-based images (usually as "dialout"). Reuse that group when present.
RUN set -eux; \
  if getent group "$AGENT_GID" >/dev/null; then \
    AGENT_GROUP="$(getent group "$AGENT_GID" | cut -d: -f1)"; \
  else \
    groupmod -g "$AGENT_GID" node; \
    AGENT_GROUP=node; \
  fi; \
  usermod -u "$AGENT_UID" -g "$AGENT_GROUP" -d /home/agent -m -l agent node

# Install pi coding agent (run as root before USER agent)
RUN npm install -g @mariozechner/pi-coding-agent

# Pi may install optional tool packages at runtime. Give the non-root agent user
# a writable global npm prefix so those installs don't try to write /usr/local.
ENV NPM_CONFIG_PREFIX=/home/agent/.npm-global
ENV PATH=/home/agent/.npm-global/bin:$PATH
RUN mkdir -p /home/agent/.npm-global /home/agent/.npm && chown -R ${AGENT_UID}:${AGENT_GID} /home/agent/.npm-global /home/agent/.npm

USER ${AGENT_UID}:${AGENT_GID}

WORKDIR /home/agent

# In worktree sandbox mode, Sandcastle bind-mounts the git worktree at /home/agent/workspace
# and overrides the working directory to /home/agent/workspace at container start.
# Structure your Dockerfile so that /home/agent/workspace can serve as the project root.
ENTRYPOINT ["sleep", "infinity"]
