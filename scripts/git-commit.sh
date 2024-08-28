#!/bin/bash
set -x

git config --global user.name "LCI user access"
git config --global user.email alma.carney@ericsson.com

git status
commit_msg="Setting release version to $1"
git add charts/eric-bos-dr-stub/Chart.yaml
git commit -m "${commit_msg}"
git status
git log -3
git push origin HEAD:master
