FROM ubuntu:focal

LABEL org.opencontainers.image.source https://github.com/mcfeasome/swiss-army-devops

# Hashicorp Products
ARG VAULT_VERSION=1.10.2
ARG TERRAFORM_VERSION=1.1.9
ARG CONSUL_VERSION=1.12.0
ARG BOUNDARY_VERSION=0.8.0

# Argo
ARG ARGOCD_VERSION=v2.3.3
ARG ARGOWORKFLOWS_VERSION=v3.3.5

# Github
ARG GITHUB_CLI_VERSION=2.9.0

# EKSCTL
ARG EKSCTL_VERSION="v0.97.0-rc.0"

# Some base envvars
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="Etc/UTC"

# Install stuff with apt-get
RUN apt-get update \
    && apt-get install -y gnupg \
    software-properties-common curl \
    bash wget unzip gzip git python3 \
    python3-pip vim ruby-full

# Install bundler
RUN gem install bundler

# Install emrichen (https://github.com/con2/emrichen)
RUN pip3 install emrichen

# Create a temporary working directory to make cleanup easier
RUN mkdir /setup
WORKDIR /setup

# Install Vault (https://www.vaultproject.io/)
RUN wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip
RUN unzip vault_${VAULT_VERSION}_linux_amd64.zip
RUN mv vault /usr/local/bin

# Install Terraform (https://www.terraform.io/)
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN mv terraform /usr/local/bin

# Install Consul (https://www.hashicorp.com/products/consul)
RUN wget https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
RUN unzip consul_${CONSUL_VERSION}_linux_amd64.zip
RUN mv consul /usr/local/bin

# Install Boundary (https://www.boundaryproject.io/)
RUN wget https://releases.hashicorp.com/boundary/${BOUNDARY_VERSION}/boundary_${BOUNDARY_VERSION}_linux_amd64.zip
RUN unzip boundary_${BOUNDARY_VERSION}_linux_amd64.zip
RUN mv boundary /usr/local/bin

# Install ArgoCD CLI (https://argoproj.github.io/)
RUN wget https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64
RUN mv argocd-linux-amd64 /usr/local/bin/argocd

# Install Argo Workflows CLI (https://argoproj.github.io/)
RUN wget https://github.com/argoproj/argo-workflows/releases/download/${ARGOWORKFLOWS_VERSION}/argo-linux-amd64.gz
RUN gzip -d argo-linux-amd64.gz
RUN mv argo-linux-amd64 /usr/local/bin/argo

# Install eksctl (https://eksctl.io/)
RUN curl --silent --location https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_amd64.tar.gz | tar xz -C /tmp
RUN mv /tmp/eksctl /usr/local/bin

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
RUN echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
RUN mv ./kubectl /usr/local/bin

# Argo Rollouts Kubectl Plugin (https://argoproj.github.io/)
RUN wget https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
RUN chmod +x ./kubectl-argo-rollouts-linux-amd64
RUN mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# Install Flux CLI (https://fluxcd.io/)
RUN curl -s https://fluxcd.io/install.sh | bash

# Install OPA CLI (https://openpolicyagent.org/)
RUN curl -L -o opa https://openpolicyagent.org/downloads/v0.40.0/opa_linux_amd64_static
RUN chmod 755 ./opa
RUN mv opa /usr/local/bin

# Install Github CLI (https://github.com/cli)
RUN wget https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_amd64.tar.gz
RUN tar -xf gh_${GITHUB_CLI_VERSION}_linux_amd64.tar.gz
RUN mv gh_${GITHUB_CLI_VERSION}_linux_amd64/bin/gh /usr/local/bin

# Install bats-core
RUN git clone https://github.com/bats-core/bats-core.git
RUN /setup/bats-core/install.sh /usr/local

RUN rm -rf /setup
RUN mkdir /work
WORKDIR /work

# Create a "devops" user
RUN useradd -Ums /bin/bash devops
ADD --chown=devops:devops files/bashrc /home/devops/.bashrc
ADD files/Gemfile /work/Gemfile
ADD files/bundle-install.sh /work/bundle-install.sh

# Final Permission Changes
RUN chown -R devops:devops /work
RUN chmod -R a+rx /usr/local/bin

USER devops

# Install bats detik
RUN mkdir -p /home/devops/bats/lib
ADD --chown=devops:devops files/*.bash /home/devops/bats/lib/

RUN /work/bundle-install.sh

ENTRYPOINT /bin/bash
