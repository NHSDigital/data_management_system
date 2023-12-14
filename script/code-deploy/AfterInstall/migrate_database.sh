#!/bin/bash

export RAILS_ENV=production
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:drop 
bin/rails db:setup
bin/rails db:migrate
# bin/rails db:seed dummy_data=true
