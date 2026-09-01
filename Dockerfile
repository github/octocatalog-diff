ARG RUBY_VERSION="3.2.11"

FROM ruby:${RUBY_VERSION} as ruby
ARG RUBY_VERSION
ENV RUBY_VERSION="${RUBY_VERSION}"
RUN rm -rf $GEM_HOME $BUNDLE_PATH $BUNDLE_BIN $BUNDLE_APP_CONFIG
RUN apt-get update && apt-get install -y cmake openssl libssl-dev
RUN sed -i 's/\[openssl_init\]/# [openssl_init]/' /etc/ssl/openssl.cnf && \
    printf "\n[openssl_init]\nproviders = provider_sect\nssl_conf = ssl_configuration\n\n[provider_sect]\ndefault = default_sect\nlegacy = legacy_sect\n\n[default_sect]\nactivate = 1\n\n[legacy_sect]\nactivate = 1\n\n[ssl_configuration]\nsystem_default = tls_system_default\n\n[tls_system_default]\nMinProtocol = TLSv1\nCipherString = DEFAULT@SECLEVEL=0\n" >> /etc/ssl/openssl.cnf

FROM scratch AS app
ARG PUPPET_VERSION
ENV PUPPET_VERSION="${PUPPET_VERSION}"
COPY --from=ruby / /
WORKDIR /app
ENV LANG="C.UTF-8"
COPY . .
RUN script/bootstrap

CMD ["/app/script/cibuild"]
