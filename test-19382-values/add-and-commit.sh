#!/bin/bash

cat <<EOF > values.yaml
cmData:
  test: baseDataOverwrite
EOF
while true; do
REVISION="$(git rev-parse HEAD)"
TIMESTAMP="$(date +%s)"
echo "  '$TIMESTAMP': $REVISION" >> values.yaml 
git add -A
git commit -m "chore: update $TIMESTAMP"
git push origin main
sleep 5
done
