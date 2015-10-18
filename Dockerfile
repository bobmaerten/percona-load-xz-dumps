FROM percona:5.6.26

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -yqq pv xz-utils --no-install-recommends && \
    apt-get clean && \
    cd /var/lib/apt/lists && rm -fr *Release* *Sources* *Packages* && \
    truncate -s 0 /var/log/*log
