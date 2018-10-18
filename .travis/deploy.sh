#!/bin/sh
set -e

# setup ssh-agent and provide the GitHub deploy key
eval "$(ssh-agent -s)"
openssl aes-256-cbc -K $encrypted_be30558f84bc_key -iv $encrypted_be30558f84bc_iv -in .travis/id_rsa.enc -out id_rsa -d
chmod 600 id_rsa
ssh-add id_rsa

wget https://github.com/X1011/git-directory-deploy/raw/e37ac94cda4bfc5773c0f01d89d8c875a21ab4f9/deploy.sh
chmod +x deploy.sh
GIT_DEPLOY_DIR=book GIT_DEPLOY_BRANCH=gh-pages GIT_DEPLOY_REPO=sunrise-choir/spec ./deploy.sh
