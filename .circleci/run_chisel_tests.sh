set -e
# Extract the x...y part of "The GitHub or Bitbucket URL to compare commits of a build."
COMMIT_RANGE=`basename $CIRCLE_COMPARE_URL`
# Skip chisel tests if the commit message says to
if git log --format=%B --no-merges $COMMIT_RANGE | grep '\[skip chisel tests\]'; then
  exit 0
else
  sbt assembly publishLocal
  git clone https://github.com/ucb-bar/chisel3.git
  mkdir -p chisel3/lib
  cp utils/bin/firrtl.jar chisel3/lib
  cd chisel3
  sbt "set concurrentRestrictions in Global += Tags.limit(Tags.Test, 2)" clean test
fi
