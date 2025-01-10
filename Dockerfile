FROM hashicorp/terraform:latest

# Install AWS CLI and dependencies using apk
RUN apk add --no-cache \
    python3 \
    py3-pip \
    aws-cli \
    ansible \
    openssh-client \
    py3-boto3 \
    bash \
    curl \
    openssl \
    py3-kubernetes \
    py3-yaml \
    py3-jinja2 \
    py3-cryptography


# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install Helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod +x get_helm.sh && \
    ./get_helm.sh && \
    rm get_helm.sh

WORKDIR /workspace

# Override the default terraform entrypoint to allow shell access
ENTRYPOINT []
CMD ["/bin/bash"]