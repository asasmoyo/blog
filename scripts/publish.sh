#!/usr/bin/env bash
mkdir -p temp
rm -rf temp/asasmoyo.github.io
git clone https://${PUBLISH_REPO_TOKEN}@github.com/asasmoyo/asasmoyo.github.io temp/asasmoyo.github.io

git config --global user.email "arba.sasmoyo@gmail.com"
git config --global user.name "Arba Sasmoyo"

rsync -av --delete --exclude '.git/' --exclude '.ssh/' "$(pwd)/public/" "$(pwd)/temp/asasmoyo.github.io"
pushd temp/asasmoyo.github.io
    git add --all
    git commit -m "Some updates"
    git push origin master
popd
