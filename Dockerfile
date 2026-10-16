FROM ruby:3.4-slim AS build

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    RAILS_ENV=production

RUN apt-get update && apt-get install -y --no-install-recommends build-essential ca-certificates curl gnupg libpq-dev && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM ruby:3.4-slim AS runtime

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    RAILS_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    SOLID_QUEUE_IN_PUMA=true

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates libpq5 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app
EXPOSE 3000
CMD ["sh", "bin/docker-entrypoint"]