ARG RUBY_VERSION="2.6"
FROM ruby:${RUBY_VERSION} as ruby
ARG RUBY_VERSION
ENV RUBY_VERSION="${RUBY_VERSION}"
RUN rm -rf $GEM_HOME $BUNDLE_PATH $BUNDLE_BIN $BUNDLE_APP_CONFIG
RUN apt-get update && apt-get install -y cmake openssl libssl-dev
RUN sed -i'' -e 's/CipherString = DEFAULT@SECLEVEL=2/CipherString = DEFAULT@SECLEVEL=1/g' /etc/ssl/openssl.cnf
RUN sed -i'' -e 's/MinProtocol = TLSv1.2/MinProtocol = TLSv1/g' /etc/ssl/openssl.cnf

FROM scratch AS app
COPY --from=ruby / /
WORKDIR /app
ENV LANG="C.UTF-8"
COPY . .
#RUN gem install bundler -v 1.17.2
RUN script/bootstrap

CMD ["/app/script/cibuild"]
