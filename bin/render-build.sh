#!/usr/bin/env bash
set -o errexit

# Install PostgreSQL development libraries
apt-get update -qq && apt-get install -y libpq-dev

bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean
bundle exec rake db:migrate