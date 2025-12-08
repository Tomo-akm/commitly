# syntax=docker/dockerfile:1.4
FROM public.ecr.aws/docker/library/ruby:3.3.5

ENV TZ=Asia/Tokyo
ENV RAILS_ENV=production
ENV BUNDLE_DEPLOYMENT=true
ENV BUNDLE_WITHOUT="development test"
ENV BUNDLE_PATH=/usr/local/bundle

ARG RUBYGEMS_VERSION=3.5.23

# Install system dependencies
RUN set -uex && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      gnupg \
      libpq-dev \
      postgresql-client \
      nodejs \
      yarn \
      vim && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /rails

# Install Ruby gems
COPY Gemfile Gemfile.lock ./
RUN gem update --system ${RUBYGEMS_VERSION}
RUN bundle install

# Copy application code
COPY . .

# Precompile assets（requires RAILS_MASTER_KEY as a BuildKit secret from Kamal）
RUN --mount=type=secret,id=RAILS_MASTER_KEY \
    RAILS_MASTER_KEY="$(cat /run/secrets/RAILS_MASTER_KEY)" \
    bundle exec rails assets:precompile

# Remove dev-only bin
RUN rm -f bin/dev

# Expose port
EXPOSE 3000

# Entrypoint
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# Run production server (Puma)
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
