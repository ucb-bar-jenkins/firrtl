#!/usr/bin/env bash
# This script is for formally comparing the Verilog emitted by different git revisions
# There must be two valid git revision arguments
set -e

if [ $# -lt 3 ]; then
    echo "There must be at least three arguments!"
    exit -1
fi

HASH1=`git rev-parse $1`
HASH2=`git rev-parse $2`
shift
shift

DUTS=$@

echo "Comparing git revisions $HASH1 and $HASH2 on $DUTS"

if [ $HASH1 = $HASH2 ]; then
    echo "Both git revisions are the same! Nothing to do!"
    exit 0
fi

make_firrtl () {
    local HASH=$1
    git checkout $HASH
    sbt $SBT_ARGS clean assembly
    mv utils/bin/firrtl.jar utils/bin/firrtl.$HASH.jar
}

make_verilog () {
    local HASH=$1
    shift
    for dut in $@; do
      local filename="$dut.$HASH.v"
      java -jar utils/bin/firrtl.$HASH.jar -i regress/$dut.fir -o $filename -X verilog
    done
}

# Checkout and build a firrtl jar for the first hash
make_firrtl $HASH1
# Checkout and build a firrtl jar for the second hash, leaving that commit
#  as the source for regression tests.
make_firrtl $HASH2

# Generate Verilog to compare
make_verilog $HASH1 $DUTS

make_verilog $HASH2 $DUTS

# Compare generated verilog
for DUT in $DUTS; do
  FILE1="$DUT.$HASH1.v"
  FILE2="$DUT.$HASH2.v"
  echo "Comparing $FILE1 and $FILE2"

  if cmp -s $FILE1 $FILE2; then
    echo "File contents are identical!"
  else
    echo "Running equivalence check using Yosys"
    yosys -q -p "
      read_verilog $FILE1
      rename $DUT top1
      proc
      memory
      flatten top1
      hierarchy -top top1

      read_verilog $FILE2
      rename $DUT top2
      proc
      memory
      flatten top2

      equiv_make top1 top2 equiv
      hierarchy -top equiv
      clean -purge
      equiv_simple
      equiv_induct
      equiv_status -assert
    "
  fi
done
