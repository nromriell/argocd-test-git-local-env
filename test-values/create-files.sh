#!/bin/bash

TEST_APP_COUNT=${1:-10}

for i in $(seq 1 $TEST_APP_COUNT); do
  echo -e "configmapValues:\n  dataFrom$i: '$i'" > values-$i.yaml
done

