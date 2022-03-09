#!/bin/bash

if [ $# = 0 ]; then
    echo Syntax: `basename "$0"` new_rails_version
    echo
    echo Updates the bundled rails version to new_rails_version
    echo and provides instructions for committing changes.
    exit 1
fi

cd "`dirname $0`/.." # Change to working copy home directory

if [ ! -e '.git' ]; then
    echo Error: Requires a git working copy. Aborting.
    exit 1
fi

NEW_RAILS_VERSION="$1"
OLD_RAILS_VERSION=`egrep "gem 'rails', '(~> )?[0-9.]*'" Gemfile | egrep -o '[0-9.]+'`
if [ "$OLD_RAILS_VERSION" = "" ]; then
    echo Error: cannot find old Rails version from Gemfile
    exit 1
fi

echo Old Rails version from Gemfile: $OLD_RAILS_VERSION

# Check out a fresh branch, if a git working copy (but not git-svn)
GIT_SVN=`git svn find-rev HEAD`
BRANCH_NAME="`echo rails_$NEW_RAILS_VERSION | tr . _`"
if [ -z "$GIT_SVN" ]; then
    # Not a git-svn working copy
    git checkout -b "$BRANCH_NAME" # Create a new git branch
fi

if ! bundle check 2> /dev/null; then
    echo Error: bundle check fails before doing anything.
    echo Please clean up the Gemfile before running this. Aborting.
    exit 1
fi

# If necessary, prompt to put activemodel-caution gem in place
if grep -q "^ *gem 'activemodel-caution'" Gemfile; then
    if ! ls "vendor/cache/activemodel-caution-$NEW_RAILS_VERSION"*.gem > /dev/null; then
        echo
        echo "Error: missing activemodel-caution-$NEW_RAILS_VERSION*.gem file in vendor/cache"
        echo Copy this file to vendor/cache, then run this command again.
        exit 1
    fi
fi



RELATED_GEMS=`bundle exec gem list|grep -F "$OLD_RAILS_VERSION" | cut -d' ' -f1`
echo Gems to update: $RELATED_GEMS

echo Tweaking Gemfile for new Rails version
sed -i '' -E -e "s/(gem '(rails|activemodel-caution)', '(~> )?)$OLD_RAILS_VERSION(')/\1$NEW_RAILS_VERSION\4/" Gemfile

git diff Gemfile

echo Running: bundle update --conservative --patch $RELATED_GEMS
bundle update --conservative --patch $RELATED_GEMS

if ! bundle check 2> /dev/null; then
    echo Error: bundle check fails after trying to update Rails version. Aborting.
    echo You will need to check your working copy, especially Gemfile, Gemfile.lock, vendor/cache
    exit 1
fi

echo Looking for changed files using git status
echo
FILES_TO_GIT_RM=`git status vendor/cache/|grep 'deleted: ' |grep -o ': .*' | sed -e 's/^: *//'`
FILES_TO_GIT_ADD1=`git status Gemfile Gemfile.lock|grep 'modified: ' |grep -o ': .*' | sed -e 's/^: *//'`
FILES_TO_GIT_ADD2=`git status vendor/cache|expand|grep '^\s*vendor/cache' | sed -e 's/^ *//'`
echo 'Gemfile updated. Please use "git status" and "git diff" to check the local changes,'
echo re-run tests locally, then run the following to commit the changes:
echo
echo "$ git rm" $FILES_TO_GIT_RM
echo "$ git add" $FILES_TO_GIT_ADD1 $FILES_TO_GIT_ADD2
echo "$ git commit -m '# Bump Rails to $NEW_RAILS_VERSION'"
