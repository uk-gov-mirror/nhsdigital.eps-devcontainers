FROM local_syft:latest AS syft-build
FROM local_grype:latest AS grype-build
FROM local_grant:latest AS grant-build
FROM local_zizmor:latest AS zizmor-build
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG SCRIPTS_DIR=/usr/local/share/eps
ARG CONTAINER_NAME
ARG IMAGE_TAG
ARG TARGETARCH
ARG SAM_VERSION="v1.158.0"
ARG ASDF_VERSION="v0.18.1"

ENV SCRIPTS_DIR=${SCRIPTS_DIR}
ENV CONTAINER_NAME=${CONTAINER_NAME}
ENV TARGETARCH=${TARGETARCH}
ENV SAM_VERSION=${SAM_VERSION}
ENV ASDF_VERSION=${ASDF_VERSION}

COPY --chmod=755 scripts/lifecycle/*.sh ${SCRIPTS_DIR}/
COPY --chmod=755 scripts/root_install.sh ${SCRIPTS_DIR}/${CONTAINER_NAME}/root_install.sh
COPY --chmod=755 scripts/install_aws_sam_cli.sh ${SCRIPTS_DIR}/${CONTAINER_NAME}/install_aws_sam_cli.sh
COPY --chmod=755 scripts/install_asdf.sh ${SCRIPTS_DIR}/${CONTAINER_NAME}/install_asdf.sh
COPY --chmod=755 Mk ${SCRIPTS_DIR}/Mk

WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
RUN ./root_install.sh

COPY --from=syft-build /syft /usr/local/bin/syft
COPY --from=grype-build /grype /usr/local/bin/grype
COPY --from=grant-build /grant /usr/local/bin/grant
COPY --from=zizmor-build /zizmor /usr/local/bin/zizmor
COPY --chmod=755 scripts/vscode_install.sh ${SCRIPTS_DIR}/${CONTAINER_NAME}/vscode_install.sh
USER vscode
COPY --chown=vscode:vscode .tool-versions /home/vscode/.tool-versions
COPY --chown=vscode:vscode .grant.yaml /home/vscode/.grant.yaml

ENV PATH="/home/vscode/.asdf/shims:/home/vscode/.guard/bin:$PATH"
WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
RUN ./vscode_install.sh

# Switch back to root to install the devcontainer CLI globally
USER root

ENV IMAGE_TAG=${IMAGE_TAG}

LABEL org.opencontainers.image.source=https://github.com/NHSDigital/eps-devcontainers
LABEL org.opencontainers.image.description="EPS devcontainer ${CONTAINER_NAME}:${IMAGE_TAG}"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.containerName=${CONTAINER_NAME}
LABEL org.opencontainers.image.authors="NHS England EPS Team"
LABEL org.opencontainers.image.base.image="mcr.microsoft.com/devcontainers/base:ubuntu-22.04"
