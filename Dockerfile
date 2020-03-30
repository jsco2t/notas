FROM jupyter/minimal-notebook:latest AS base
LABEL maintainer="github.com/jsco2t"

# install dotnet
USER root
RUN wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm -f packages-microsoft-prod.deb && \
    #add-apt-repository universe && \
    apt update && \
    apt install -y apt-transport-https && \
    apt update && \
    apt install -y dotnet-sdk-3.1 && \
    apt autoremove -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# install dotnet kernels:
#RUN dotnet tool install -g --add-source "https://dotnet.myget.org/F/dotnet-try/api/v3/index.json" Microsoft.dotnet-interactive
RUN dotnet tool install --global Microsoft.dotnet-interactive
RUN export PATH=/home/jovyan/.dotnet:/home/jovyan/.dotnet/tools:/home/jovyan/.dotnet/tools/dotnet-interactive:$PATH && \
    dotnet interactive jupyter install

# install themes and extensions
RUN jupyter labextension install @mohirio/jupyterlab-horizon-theme @ijmbarr/jupyterlab_spellchecker && \
    rm -f -r /usr/local/share/.cache/* && \
    conda clean --all -f -y

# fixup permissions before moving back to the jovyan user
RUN fix-permissions /home/jovyan/.local/share/jupyter/ && \
    chown -R jovyan /home/jovyan/.local/share/jupyter && \
    chgrp -R users /home/jovyan/.local/share/jupyter

# switch back to jovian user:
USER $NB_UID

# entrypoint
ARG DEFAULT_JUPYTER_TOKEN="ganymede"
ENV PATH="/home/jovyan/.dotnet/tools:/home/jovyan/.dotnet/tools/dotnet-interactive:${PATH}" \
    JUPYTER_TOKEN=$DEFAULT_JUPYTER_TOKEN \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    NUGET_XMLDOC_MODE=skip \
    DOTNET_TRY_CLI_TELEMETRY_OPTOUT=false
COPY scripts/entrypoint.sh /home/jovyan/
RUN mkdir /home/jovyan/notebook
WORKDIR /home/jovyan
CMD ["./entrypoint.sh"]

# debug:
# 
# debug: building:
#   docker build -t "jsco2t/notas:0.0.1" .
#
# debug: running:
#   docker run -it --rm -p 8888:8888 --entrypoint "/bin/bash" jsco2t/notas:0.0.1
#   docker run -it --rm -p 8888:8888 jsco2t/notas:0.0.1
#
# running:
#   docker run -d -v --rm -p 8888:8888 jsco2t/notas:0.0.1
#   docker run -d -v /host/directory:/home/jovyan/notebook --rm -p 8888:8888 jsco2t/notas:0.0.1
#
# resources:
#   https://github.com/jupyter/docker-stacks/blob/master/minimal-notebook/Dockerfile