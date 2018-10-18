#!/bin/bash
set -e

# setup ssh-agent and provide the GitHub deploy key
echo "test 1"
eval "$(ssh-agent -s)"
echo "test 2"
openssl aes-256-cbc -K $encrypted_be30558f84bc_key -iv $encrypted_be30558f84bc_iv -in .travis/id_rsa.enc -out id_rsa -d
echo "test 3"
chmod 600 id_rsa
echo "test 4"
ssh-add id_rsa
echo "test 5"

wget https://github.com/X1011/git-directory-deploy/raw/e37ac94cda4bfc5773c0f01d89d8c875a21ab4f9/deploy.sh
echo "test 6"
chmod +x deploy.sh
echo "test 7"
GIT_DEPLOY_DIR=book GIT_DEPLOY_BRANCH=gh-pages GIT_DEPLOY_REPO=git@github.com:sunrise-choir/spec ./deploy.sh
echo "test 8"
