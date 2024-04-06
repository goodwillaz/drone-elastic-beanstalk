FROM --platform=linux/amd64 node:20

RUN curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.15.30.zip" -o "/tmp/awscliv2.zip" \
    && unzip /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli \
    && rm -rf /tmp/awscliv2.zip /tmp/aws \
    && npm install -g aws-cdk@2.133.0

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
