#!/usr/bin/env bash
set -o errexit

bundle install

# Assets
bundle exec rake assets:precompile

# DB schema（queue & cable）
bundle exec rails db:migrate
bundle exec rails db:schema:load:queue
bundle exec rails db:schema:load:cable
