#!/bin/bash
# Handy script to completely reset the database

bundle exec rake db:drop && bundle exec rake db:create && bundle exec rake db:migrate
