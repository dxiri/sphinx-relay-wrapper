FROM arm64v8/node:12-buster-slim AS builder

WORKDIR /relay
RUN mkdir /relay/.lnd
COPY . .

RUN apt-get update

RUN apt install -y make python-minimal
RUN apt install -y g++ gcc libmcrypt-dev
RUN apt-get -y install git

RUN rm ./sphinx-relay/package-lock.json

WORKDIR /relay/sphinx-relay
RUN npm install bcrypt
RUN npm install

RUN cp /relay/sphinx-relay/config/app.json /relay/sphinx-relay/dist/config/app.json
RUN cp /relay/sphinx-relay/config/config.json /relay/sphinx-relay/dist/config/config.json

FROM arm64v8/node:12-buster-slim

RUN apt-get update
RUN apt-get install wget -y
RUN wget https://github.com/mikefarah/yq/releases/download/v4.6.3/yq_linux_arm.tar.gz -O - | tar xz && mv yq_linux_arm /usr/bin/yq
RUN apt-get install jq curl simpleproxy -y

ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh
ADD ./check-interface.sh /usr/local/bin/check-interface.sh
RUN chmod a+x /usr/local/bin/check-interface.sh

WORKDIR /relay

COPY --from=builder /relay/sphinx-relay .

EXPOSE 3300

ENV NODE_ENV production
ENV NODE_SCHEME http
ENV PORT 3300

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]

