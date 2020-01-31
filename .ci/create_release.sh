#!/usr/bin/env bash

set -e

GIT_TAG="${1}"
GIT_MESSAGE="${2:-"Release ${GIT_TAG}"}"
GH_TOKEN=${GH_TOKEN}

# update the python version to match the provided tag
function update_version
{
    echo "tba..."
}

# updates the changelog up to the current tag and commits changes
function update_changelog
{
    echo "creating changelog..."
    github_changelog_generator -t "${GH_TOKEN}" --future-release "${GIT_TAG}"

    git add CHANGELOG.md
    git commit --amend --no-verify
}

# creates the tag
function create_tag
{
    echo "creating ${GIT_TAG}: ${GIT_MESSAGE}"
    git tag -m "${GIT_MESSAGE}" "${GIT_TAG}"
}

function _main
{
    if [[ ! -z "${GH_TOKEN}" ]]
    then
        update_changelog
        create_tag
        echo "done"
    else
        echo "please provide GH token for changelog generation"
    fi
}

_main
