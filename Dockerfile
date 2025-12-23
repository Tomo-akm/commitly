# syntax=docker/dockerfile:1.4
FROM public.ecr.aws/docker/library/ruby:3.3.5

ENV TZ=Asia/Tokyo

# Build-time knobs (override for local/dev builds via --build-arg).
ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV}
ARG BUNDLE_DEPLOYMENT=true
ENV BUNDLE_DEPLOYMENT=${BUNDLE_DEPLOYMENT}
ARG BUNDLE_WITHOUT="development test"
ENV BUNDLE_WITHOUT=${BUNDLE_WITHOUT}
ENV BUNDLE_PATH=/usr/local/bundle

ARG RUBYGEMS_VERSION=3.5.23

# Install system dependencies (Ruby, Node.js, Yarn, PostgreSQL client, libvips for image processing)
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
RUN set -uex && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg \
      libpq-dev \
      postgresql-client \
      libvips \
      vim && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    NODE_MAJOR=18 && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends nodejs yarn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /webapp

# Install Ruby gems
COPY Gemfile Gemfile.lock ./
RUN gem update --system ${RUBYGEMS_VERSION}
RUN bundle install

# Install foreman for bin/dev (only used in non-production runs)
RUN gem install foreman

# Copy application code
COPY . .

# Install JS deps when present
RUN if [ -f package.json ]; then yarn install; fi

# Precompile assets in production only (requires RAILS_MASTER_KEY via BuildKit secret)
RUN --mount=type=secret,id=RAILS_MASTER_KEY,required=false \
    if [ "$RAILS_ENV" = "production" ]; then \
      if [ -f /run/secrets/RAILS_MASTER_KEY ]; then \
        RAILS_MASTER_KEY="$(cat /run/secrets/RAILS_MASTER_KEY)" bundle exec rails assets:precompile; \
      else \
        echo "RAILS_MASTER_KEY is required for production assets precompile" >&2; \
        exit 1; \
      fi; \
    else \
      echo "Skipping assets:precompile for RAILS_ENV=$RAILS_ENV"; \
    fi

# Entry point
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

# Default to Puma in production; override with `command: bin/dev` in docker-compose for dev.
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
