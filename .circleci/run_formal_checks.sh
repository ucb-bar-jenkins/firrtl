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
# Extract the x...y part of "The GitHub or Bitbucket URL to compare commits of a build."
COMMIT_RANGE=`basename $CIRCLE_COMPARE_URL`
# Skip chisel tests if the commit message says to
elif git log --format=%B --no-merges $COMMIT_RANGE | grep '\[skip formal checks\]'; then
  echo "Commit message says to skip formal checks"
  exit 0
else
  # Unlike Travis, CircleCI doesn't directly indicate the destination branch
  #  of the pull request.
  # For the purposes of regression testing, it seems we lose nothing by
  #  testing against master.
  REGRESSION_BRANCH=master
  git fetch origin $REGRESSION_BRANCH
  cp regress/$DUT.fir $DUT.fir
  bash -xv ./scripts/formal_equiv.sh $CIRCLE_BRANCH $REGRESSION_BRANCH $DUT
fi
