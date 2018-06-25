#!/usr/bin/env bash
set -e

if [ $# -ne 1 ]; then
    echo "There must be exactly one argument!"
    exit -1
fi

DUT=$1

# Run formal check only for PRs
if $RUN_FORMAL_CHECKS ; then
  if [ $CIRCLE_PULL_REQUEST = "" ]; then
    echo "Not a pull request, no formal check"
    exit 0
  elif git log --format=%B --no-merges $CIRCLE_BRANCH..HEAD | grep '\[skip formal checks\]'; then
    echo "Commit message says to skip formal checks"
    exit 0
  else
    # $CIRCLE_BRANCH is branch targeted by PR
    # Checkout PR target so that we have it
    # Then return to previous branch so HEAD points to the commit we're testing
    git remote set-branches origin $CIRCLE_BRANCH && git fetch
    git checkout $CIRCLE_BRANCH
    git checkout -
    cp regress/$DUT.fir $DUT.fir
    ./scripts/formal_equiv.sh HEAD $CIRCLE_BRANCH $DUT
  fi
else
    echo "Not running formal check"
    exit 0
fi
