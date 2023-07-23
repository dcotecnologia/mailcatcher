FROM ruby:3.2.2-slim-bullseye
LABEL org.opencontainers.image.source=https://github.com/dcotecnologia/mailcatcher
ARG ENVIRONMENT=production
ARG MAILCATCHER_AUTH_USER=
ARG MAILCATCHER_AUTH_PASSWORD=
ENV MAILCATCHER_ENV=$ENVIRONMENT
ENV RACK_ENV=$ENVIRONMENT
ENV MAILCATCHER_AUTH_USER=$MAILCATCHER_AUTH_USER
ENV MAILCATCHER_AUTH_PASSWORD=$MAILCATCHER_AUTH_PASSWORD
ENV GEM_HOME=/usr/local/lib/ruby/gems/3.2.0
ENV PATH=$PATH:/usr/local/bundle/bin
RUN apt-get update -qq
RUN apt-get install -qq -y --no-install-recommends \
    build-essential libpq-dev curl apt-transport-https imagemagick \
    libsqlite3-dev git shared-mime-info libffi-dev deborphan libreadline-dev
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash -
RUN apt install -qq -y --no-install-recommends nodejs && \
	npm install -g npm@latest \
	npm install --global yarn
RUN apt-get update -qq && apt-get full-upgrade -qq -y && apt-get autoclean -qq -y
WORKDIR /server
COPY ./server/Gemfile ./server/Gemfile.lock ./server/.ruby-version ./
RUN gem update --system
RUN if [ "$ENVIRONMENT" != "development" ]; then \
        bundle config set --local without 'development test lint'; \
    fi
RUN bundle check || bundle install --full-index --no-binstubs --jobs 6 --retry 3
COPY ./server/bin ./bin
COPY ./server/lib ./lib
COPY ./server/public ./public
RUN apt remove --purge deborphan -qq -y && apt autoremove -qq -y && apt autoclean -qq -y
EXPOSE 1025 1080

# Webapp

WORKDIR /webapp
ENV NEXT_TELEMETRY_DISABLED 1
COPY ./webapp/package.json ./webapp/package-lock.json ./
RUN npm install --production
COPY ./webapp/. ./
RUN npm run build
EXPOSE 3000
ENV PORT 3000

# Start servers process
WORKDIR /
RUN npm install -g foreman
COPY Procfile ./
CMD ["nf", "start"]
