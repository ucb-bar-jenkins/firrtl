set -e
# Extract the x...y part of "The GitHub or Bitbucket URL to compare commits of a build.",
#  and convert it to two-dot range notation.
COMMIT_RANGE=`basename $CIRCLE_COMPARE_URL | sed -e 's/\.\.\./../'`
# Skip chisel tests if the commit message says to
if git log --format=%B --no-merges $COMMIT_RANGE | grep '\[skip chisel tests\]'; then
  exit 0
else
  # We assume the following has been done elsewhere
  #  sbt $SBT_ARGS assembly publishLocal
  git clone https://github.com/ucb-bar/chisel3.git
  mkdir -p chisel3/lib
  ls -l . utils/bin/firrtl.jar
  cp utils/bin/firrtl.jar chisel3/lib
  cd chisel3
  sbt $SBT_ARGS "set concurrentRestrictions in Global += Tags.limit(Tags.Test, 2)" clean test
fi
