#!/usr/bin/env bash
set -e

if [ $# -ne 1 ]; then
    echo "There must be exactly one argument!"
    exit -1
fi

DUT=$1

# Run formal check only for PRs
if [ $CIRCLE_PULL_REQUEST = "" ]; then
  echo "Not a pull request, no formal check"
  exit 0
elif git log --format=%B --no-merges $CIRCLE_BRANCH..HEAD | grep '\[skip formal checks\]'; then
  echo "Commit message says to skip formal checks"
  exit 0
else
  # Unlike Travis, CircleCI doesn't directly indicate the destination branch
  #  of the pull request.
  # For the purposes of regression testing, it seems we lose nothing by
  #  testing against master.
  # Checkout master branch so that we have it
  # Then return to previous branch so HEAD points to the commit we're testing
  REGRESSION_BRANCH=master
  git remote set-branches origin $REGRESSION_BRANCH && git fetch
  git checkout $REGRESSION_BRANCH
  git checkout -
  cp regress/$DUT.fir $DUT.fir
  ./scripts/formal_equiv.sh HEAD $REGRESSION_BRANCH $DUT
fi
