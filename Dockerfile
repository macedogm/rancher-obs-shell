#!BuildTag: shell:latest

FROM opensuse/tumbleweed:latest
#FROM opensuse/bci/bci-base:latest

ARG user=shell
ARG userid=1000

ENV KUBECTL_VERSION 1.27
ENV K9S_VERSION 0.27.4
# TODO 
# - Need to add a more up to date package of Kustomize >= v5.1.1
# - Update its .spec to make build static, otherwise it might fail due to missing GLIBC versions  
ENV KUSTOMIZE_VERSION 4.5.7
ENV RANCHER_HELM_FORK_VERSION 3.12

# Install RPM of Rancher's Helm fork
ARG RANCHER_OBS_REPO=rancher-obs-repo
RUN zypper ar https://download.opensuse.org/repositories/home:gmacedo:rancher:deps/openSUSE_Tumbleweed/ "$RANCHER_OBS_REPO"
RUN zypper --gpg-auto-import-keys ref -f
RUN zypper -n in helm"$RANCHER_HELM_FORK_VERSION"

# Install RPMs already available in OpenSUSE
RUN zypper -n in -f k9s #-"$K9S_VERSION"
RUN zypper -n in -f kubernetes"$KUBECTL_VERSION"-client
RUN zypper -n in -f kustomize #-"$KUSTOMIZE_VERSION"

RUN zypper -n up
RUN zypper -n in --no-recommends bash-completion gzip jq tar unzip vim wget
RUN zypper clean -a && rm -rf /tmp/* /var/tmp/* /usr/share/doc/packages/* /usr/share/doc/manual/* /var/log/*

RUN useradd -m -u "$userid" -U "$user"

RUN echo '. /etc/profile.d/bash_completion.sh' >> /home/shell/.bashrc && \
    echo 'alias k="kubectl"' >> /home/shell/.bashrc && \
    echo 'alias ks="kubectl -n kube-system"' >> /home/shell/.bashrc && \
    echo 'source <(kubectl completion bash)' >> /home/shell/.bashrc && \
    echo 'complete -o default -F __start_kubectl k' >> /home/shell/.bashrc && \
    echo 'PS1="> "' >> /home/shell/.bashrc

RUN mkdir /home/shell/.kube && \
    chown -R shell /home/shell

RUN chmod 700 /run

COPY --chmod=755 package/helm-cmd /usr/local/bin/
COPY --chmod=755 package/welcome /usr/local/bin/
COPY --chmod=755 package/kustomize.sh /home/"$user"

USER "$userid"

WORKDIR /home/"$user"

CMD ["welcome"]
