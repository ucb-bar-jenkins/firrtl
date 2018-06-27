#!/usr/bin/env bash
set -e

if [ $# -lt 1 ]; then
    echo "There must be at least one argument!"
    exit -1
fi

DUTS=$@

# Extract the x...y part of "The GitHub or Bitbucket URL to compare commits of a build.",
#  and convert it to two-dot range notation.
COMMIT_RANGE=`basename $CIRCLE_COMPARE_URL | sed -e 's/\.\.\./../'`

# Run formal check only for PRs
if [ "$CIRCLE_PULL_REQUEST" = "" ]; then
  echo "Not a pull request, no formal check"
  exit 0
# Skip formal tests if the commit message says to
elif git log --format=%B --no-merges $COMMIT_RANGE | grep '\[skip formal checks\]'; then
  echo "Commit message says to skip formal checks"
  exit 0
else
  # Verify we can find all the tests.
  # NOTE: We assume the current commit will be the one providing the regression test sources.
  fail=false
  for DUT in $DUTS; do
    firrtl=regress/$DUT.fir
    if [ -r $firrtl -a -s $firrtl ] ; then : ; else echo "$firrtl does not exist"; fail=true; fi
  done

  if $fail ; then exit 1; fi

  # Unlike Travis, CircleCI doesn't directly indicate the destination branch
  #  of the pull request.
  # For the purposes of regression testing, it seems we lose nothing by
  #  testing against master.
  REGRESSION_BRANCH=master
  if [ -n "$REGRESSION_BRANCH" ]; then
    NEW=$CIRCLE_BRANCH
    OLD=origin/$REGRESSION_BRANCH 
    git fetch origin $REGRESSION_BRANCH
  else
    # If we don't have an explicit regression branch, use the compare commits.
    eval `echo $COMMIT_RANGE | gawk -F'\\\.\\\.' '{print "OLD="$1, "NEW="$2}'`
  fi
  # The second sha/branch will be the one that provides the regression test sources.
  # Typically, it will be the new code.
  bash ./.circleci/formal_equiv.sh $OLD $NEW $DUTS
fi
