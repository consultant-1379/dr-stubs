#!/bin/bash
set -x

helm-package \
--folder charts/$ARTIFACT_NAME \
--workdir .bob --output .bob/$ARTIFACT_NAME-internal \
--version $VERSION \

chart=$(find charts/ -name Chart.yaml -print)
chart_version=$(cat ${chart} | yq -r .version)
echo "Current chart version is $chart_version"

sed -i "s/$chart_version/$VERSION/g" $chart
echo "Chart version updated to $VERSION"

git add $chart