#!/usr/bin/env bash
version="$(cat .hugoversion)"
download_url="https://github.com/gohugoio/hugo/releases/download/v${version}/hugo_${version}_macOS-64bit.tar.gz"

binary='bin/hugo'
if [[ -f "${binary}" && "$($binary version)" =~ "${version}" ]]; then
    # current binary has expected version
    exit 0
fi

mkdir -p temp bin
curl "${download_url}" -o temp/hugo.tar.gz -L
pushd temp
    tar -xzvf hugo.tar.gz
    mv hugo ../bin/
popd

rm -rf temp
