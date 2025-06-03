#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install

# Install JavaScript dependencies
yarn install

# Clean existing assets
bundle exec rails assets:clobber

# Precompile assets
RAILS_ENV=production bundle exec rails assets:precompile

# Run database migrations
bundle exec rails db:migrate