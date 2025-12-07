FROM public.ecr.aws/docker/library/ruby:3.3.5

ENV TZ=Asia/Tokyo
ARG RUBYGEMS_VERSION=3.5.23

# Install system dependencies
RUN set -uex && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg \
      libpq-dev \
      postgresql-client \
      vim \
      nodejs \
      yarn && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /rails

# Install Ruby gems
COPY Gemfile Gemfile.lock ./
RUN gem update --system ${RUBYGEMS_VERSION}
RUN bundle install --without development test

# Copy application code
COPY . .

# Precompile assets (重要)
RUN bundle exec rails assets:precompile

# Remove dev-only bins (optional)
RUN rm -f bin/dev

# Expose
EXPOSE 3000

# Entrypoint
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# Run production server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
