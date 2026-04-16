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
ARG GITLEAKS_VERSION="8.30.1"
ARG CFN_GUARD_VERSION="3.2.0"
ARG SHELLCHECK_VERSION="v0.11.0"
ARG DIRENV_VERSION="v2.37.1"
ARG YQ_VERSION="v4.52.5"

ENV SCRIPTS_DIR=${SCRIPTS_DIR}
ENV CONTAINER_NAME=${CONTAINER_NAME}
ENV TARGETARCH=${TARGETARCH}
ENV SAM_VERSION=${SAM_VERSION}
ENV ASDF_VERSION=${ASDF_VERSION}
ENV GITLEAKS_VERSION=${GITLEAKS_VERSION}
ENV CFN_GUARD_VERSION=${CFN_GUARD_VERSION}
ENV SHELLCHECK_VERSION=${SHELLCHECK_VERSION}
ENV DIRENV_VERSION=${DIRENV_VERSION}
ENV YQ_VERSION=${YQ_VERSION}

COPY --chmod=755 scripts/lifecycle/*.sh ${SCRIPTS_DIR}/
COPY --chmod=755 scripts/root_install.sh ${SCRIPTS_DIR}/${CONTAINER_NAME}/root_install.sh
COPY --chmod=755 scripts/install_aws_sam_cli.sh ${SCRIPTS_DIR}/${CONTAINER_NAME}/install_aws_sam_cli.sh
COPY --chmod=755 scripts/install_asdf.sh ${SCRIPTS_DIR}/${CONTAINER_NAME}/install_asdf.sh
COPY --chmod=755 scripts/install_gitleaks.sh ${SCRIPTS_DIR}/${CONTAINER_NAME}/install_gitleaks.sh
COPY --chmod=755 scripts/install_cfn_guard.sh ${SCRIPTS_DIR}/${CONTAINER_NAME}/install_cfn_guard.sh
COPY --chmod=755 scripts/install_shellcheck.sh ${SCRIPTS_DIR}/${CONTAINER_NAME}/install_shellcheck.sh
COPY --chmod=755 scripts/install_direnv.sh ${SCRIPTS_DIR}/${CONTAINER_NAME}/install_direnv.sh
COPY --chmod=755 scripts/install_yq.sh ${SCRIPTS_DIR}/${CONTAINER_NAME}/install_yq.sh
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
