#!/usr/bin/env bash
set -exv

if [ $# -lt 1 ]; then
    echo "There must be at least one argument!"
    exit -1
fi

DUTS=$@

# Extract the x...y part of "The GitHub or Bitbucket URL to compare commits of a build."
COMMIT_RANGE=`basename $CIRCLE_COMPARE_URL`

# Run formal check only for PRs
if [ $CIRCLE_PULL_REQUEST = "" ]; then
  echo "Not a pull request, no formal check"
  exit 0
# Skip chisel tests if the commit message says to
elif git log --format=%B --no-merges $COMMIT_RANGE | grep '\[skip formal checks\]'; then
  echo "Commit message says to skip formal checks"
  exit 0
else
  # Unlike Travis, CircleCI doesn't directly indicate the destination branch
  #  of the pull request.
  # For the purposes of regression testing, it seems we lose nothing by
  #  testing against master.
#  REGRESSION_BRANCH=master
  if [ -n "$REGRESSION_BRANCH" ]; then
    NEW=$CIRCLE_BRANCH
    OLD=origin/$REGRESSION_BRANCH 
    git fetch origin $REGRESSION_BRANCH
  else
    # If we don't have an explicit regression branch, use the compare commits.
    eval `echo $COMMIT_RANGE | gawk -F'\\\.\\\.\\\.' '{print "OLD="$1, "NEW="$2}'`
  fi
  bash ./scripts/formal_equiv.sh $NEW $OLD $DUTS
fi
