#!/usr/bin/env bash
version="$(cat .hugoversion)"
download_url="https://github.com/gohugoio/hugo/releases/download/v${version}/hugo_${version}_linux-64bit.tar.gz"

mkdir -p temp bin
curl "${download_url}" -o temp/hugo.tar.gz -L
pushd temp
    tar -xzvf hugo.tar.gz
    mv hugo ../bin/
popd

bin/hugo --minify

rm -rf temp/asasmoyo.github.io
git clone https://${PUBLISH_REPO_TOKEN}@github.com/asasmoyo/asasmoyo.github.io temp/asasmoyo.github.io

git config --global user.email "arba.sasmoyo@gmail.com"
git config --global user.name "Arba Sasmoyo"

rsync -av --delete --exclude '.git/' --exclude '.ssh/' "$(pwd)/public/" "$(pwd)/temp/asasmoyo.github.io"
pushd temp/asasmoyo.github.io
    # remove default icons
    rm -v *.png
    rm -v favicon.ico

    git add --all
    git commit -m "Some updates"
    git push origin master
popd
