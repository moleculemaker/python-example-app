# Start with an existing Docker image
FROM jupyter/base-notebook

MAINTAINER Sara Lambert <lambert8@illinois.edu>

# Set UID / GID of user within the container
ENV UID ${NB_UID:-1000}
ENV GID 100

# Copy files from the host into the container
COPY --chown=$UID:$GID . $HOME

# Change to non-root user within the container
USER $NB_UID

# Change our working directory within the container
WORKDIR $HOME

