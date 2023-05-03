FROM ruby:3.0.4 as build

ARG ENV production

ARG DATABASE_URL 

RUN \
  apt-get update && \
  apt-get install -y cmake && \
  apt-get install -y postgresql-client && \
  apt-get install -y nodejs

RUN export PATH=$PATH:$HOME/.local/bin:$HOME/bin:$HOME/.rbenv/bin:/usr/local/bin

RUN echo $PATH

RUN eval "$(rbenv init -)"

ENV RAILS_ENV ${ENV}

WORKDIR /app

COPY . /app

ARG APP_USER=mbis_app

ENV DEPLOYER=${APP_USER}
ENV DATABASE_URL=${DATABASE_URL}

COPY Gemfile Gemfile.lock ./

RUN sed -i.bak '/mini_racer (0.6.2-x86_64-linux/,+1d' Gemfile.lock

RUN bundle install --local

RUN ruby -ryaml -e "puts YAML.dump('production' => { 'secret_key_base' => 'compile_me' })" > config/secrets.yml

COPY config/database.yml.sample database.yml
COPY config/special_users.development.yml.sample special_users.${RAILS_ENV}.yml
COPY config/smtp_settings.yml.sample smtp_settings.yml
COPY config/odr_users.yml.sample odr_users.yml
COPY config/admin_users.yml.sample admin_users.yml
COPY config/user_yubikeys.yml.sample user_yubikeys.yml

COPY script/start_server.sh.sample start_server.sh

RUN echo $PWD && ls -alh $PWD/

CMD ["/bin/sh", "./start_server.sh"]

EXPOSE 5001



