#!/usr/bin/env bash

set -e

source /etc/profile
BASE_PATH=$(cd $(dirname $0) && pwd)

Dev=$1

CONFIG_FILE="$BASE_PATH/deconfig/$Dev.config"
INI_FILE="$BASE_PATH/compilecfg/$Dev.ini"

if [[ ! -f $CONFIG_FILE ]]; then
    echo "Config not found: $CONFIG_FILE"
    exit 1
fi

if [[ ! -f $INI_FILE ]]; then
    echo "INI file not found: $INI_FILE"
    exit 1
fi

read_ini_by_key() {
    local key=$1
    awk -F"=" -v key="$key" '$1 == key {print $2}' "$INI_FILE"
}

REPO_URL=$(read_ini_by_key "REPO_URL")
REPO_BRANCH=$(read_ini_by_key "REPO_BRANCH")
REPO_BRANCH=${REPO_BRANCH:-master}  # 修改默认分支为 master
BUILD_DIR="$BASE_PATH/action_build"

echo "Cloning $REPO_URL (Branch/Tag: $REPO_BRANCH)"
echo "$REPO_URL/$REPO_BRANCH" >"$BASE_PATH/repo_flag"

# 智能识别分支/标签
if [[ $REPO_BRANCH == v* ]]; then
  echo "Detected tag, cloning with refs/tags/ prefix..."
  git clone --depth 1 -b "refs/tags/$REPO_BRANCH" "$REPO_URL" "$BUILD_DIR"
else
  echo "Cloning branch..."
  git clone --depth 1 -b "$REPO_BRANCH" "$REPO_URL" "$BUILD_DIR"
fi

# 检查克隆是否成功
if [ $? -ne 0 ]; then
  echo "Error: Clone failed! Please check REPO_BRANCH ($REPO_BRANCH) exists."
  exit 1
fi
# GitHub Action 移除国内下载源
PROJECT_MIRRORS_FILE="$BUILD_DIR/scripts/projectsmirrors.json"

if [ -f "$PROJECT_MIRRORS_FILE" ]; then
    sed -i '/.cn\//d; /tencent/d; /aliyun/d' "$PROJECT_MIRRORS_FILE"
fi
