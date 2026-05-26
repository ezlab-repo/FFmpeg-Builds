#!/bin/bash

default_dl() {
    echo "git-mini-clone \"$SCRIPT_REPO\" \"$SCRIPT_COMMIT\" \"$1\""
}

ffbuild_dockerdl() {
    default_dl .
}

# ezLab: provide ffbuild_ffver for the download.sh container.
# vars.sh (where ffbuild_ffver is normally defined) is not mounted into the
# docker container that runs each stage script, so libraries with version
# guards like '(( $(ffbuild_ffver) > 404 )) || return -1' would otherwise
# return -1 and get skipped from the cache. We always build master (no
# release-branch addins), so 99999999 is correct.
ffbuild_ffver() {
    echo 99999999
}
