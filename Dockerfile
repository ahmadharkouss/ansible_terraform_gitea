FROM python:3.12.0-slim as builder

RUN apt update \
    && apt upgrade -y \
    && apt install -y ca-certificates curl gnupg jq \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo \
        "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt update \
    && apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    && pip3 install ansible && pip3 install ansible requests

# Multi staged, so it does not build ALL over again
FROM builder as app

WORKDIR /ansible

COPY requirements.yml .

RUN ansible-galaxy install -r requirements.yml --force

ENTRYPOINT [ "ansible-playbook" ]