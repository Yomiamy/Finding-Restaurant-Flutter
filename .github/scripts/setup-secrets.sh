#!/bin/bash

# GitHub Actions Secrets 設定輔助腳本
# 使用方式: ./setup-secrets.sh

set -e

echo "🔐 GitHub Actions Secrets 設定輔助工具"
echo "=========================================="
echo ""

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 取得專案根目錄
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ANDROID_DIR="${PROJECT_ROOT}/android"
LOCAL_PROPERTIES="${ANDROID_DIR}/local.properties"

# 檢查是否安裝 gh CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ 錯誤: 請先安裝 GitHub CLI (gh)${NC}"
    echo "安裝方式: brew install gh"
    exit 1
fi

# 檢查是否已登入
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  請先登入 GitHub CLI${NC}"
    gh auth login
fi

echo -e "${GREEN}✅ GitHub CLI 已就緒${NC}"
echo ""

# 函數: 從 local.properties 讀取值
read_local_property() {
    local key=$1
    local default=$2

    if [ -f "$LOCAL_PROPERTIES" ]; then
        local value=$(grep "^${key}=" "$LOCAL_PROPERTIES" 2>/dev/null | cut -d'=' -f2-)
        echo "${value:-$default}"
    else
        echo "$default"
    fi
}

# 函數: 設定 secret
set_secret() {
    local secret_name=$1
    local secret_value=$2

    if [ -z "$secret_value" ]; then
        echo -e "${YELLOW}⏭️  跳過 ${secret_name}${NC}"
        return
    fi

    echo "$secret_value" | gh secret set "$secret_name"
    echo -e "${GREEN}✅ 已設定 ${secret_name}${NC}"
}

# 函數: 從檔案設定 base64 secret
set_secret_from_file() {
    local secret_name=$1
    local file_path=$2

    if [ ! -f "$file_path" ]; then
        echo -e "${RED}❌ 找不到檔案: ${file_path}${NC}"
        return 1
    fi

    local base64_content=$(base64 -i "$file_path")
    set_secret "$secret_name" "$base64_content"
    return 0
}

# 讀取 local.properties 的配置
echo -e "${BLUE}📖 正在讀取 android/local.properties...${NC}"
if [ -f "$LOCAL_PROPERTIES" ]; then
    STORED_KEY_ALIAS=$(read_local_property "keyAlias")
    STORED_KEY_PASSWORD=$(read_local_property "keyPassword")
    STORED_STORE_FILE=$(read_local_property "storeFile")
    STORED_STORE_PASSWORD=$(read_local_property "storePassword")

    echo -e "${GREEN}✅ 找到現有配置:${NC}"
    echo "  - Key Alias: ${STORED_KEY_ALIAS}"
    echo "  - Store File: ${STORED_STORE_FILE}"
    echo ""
else
    echo -e "${YELLOW}⚠️  找不到 android/local.properties${NC}"
    echo ""
fi

echo "📱 Android Signing Secrets"
echo "------------------------"

# Keystore 檔案
if [ -n "$STORED_STORE_FILE" ]; then
    # 嘗試在 android 目錄找 keystore
    POTENTIAL_PATHS=(
        "${ANDROID_DIR}/${STORED_STORE_FILE}"
        "${ANDROID_DIR}/app/${STORED_STORE_FILE}"
        "${PROJECT_ROOT}/${STORED_STORE_FILE}"
    )

    FOUND_KEYSTORE=""
    for path in "${POTENTIAL_PATHS[@]}"; do
        if [ -f "$path" ]; then
            FOUND_KEYSTORE="$path"
            break
        fi
    done

    if [ -n "$FOUND_KEYSTORE" ]; then
        echo -e "${GREEN}🔍 自動找到 Keystore: ${FOUND_KEYSTORE}${NC}"
        read -p "使用此檔案? [Y/n]: " use_found
        if [[ "$use_found" =~ ^[Yy]?$ ]]; then
            keystore_path="$FOUND_KEYSTORE"
        fi
    fi
fi

if [ -z "$keystore_path" ]; then
    read -p "Keystore 檔案路徑 (例: ~/release.jks): " keystore_path
fi

if [ -n "$keystore_path" ]; then
    keystore_path="${keystore_path/#\~/$HOME}"
    if set_secret_from_file "ANDROID_KEYSTORE_BASE64" "$keystore_path"; then
        echo ""
    else
        echo -e "${RED}❌ Keystore 檔案設定失敗,請檢查路徑${NC}"
    fi
fi

# Keystore 密碼
if [ -n "$STORED_STORE_PASSWORD" ]; then
    echo -e "${BLUE}💡 在 local.properties 找到 storePassword${NC}"
    read -p "使用此密碼? [Y/n]: " use_stored_pass
    if [[ "$use_stored_pass" =~ ^[Yy]?$ ]]; then
        keystore_password="$STORED_STORE_PASSWORD"
    fi
fi

if [ -z "$keystore_password" ]; then
    read -p "Keystore 密碼: " -s keystore_password
    echo ""
fi
set_secret "KEYSTORE_PASSWORD" "$keystore_password"

# Key Alias
if [ -n "$STORED_KEY_ALIAS" ]; then
    echo -e "${BLUE}💡 在 local.properties 找到 keyAlias: ${STORED_KEY_ALIAS}${NC}"
    read -p "使用此 alias? [Y/n]: " use_stored_alias
    if [[ "$use_stored_alias" =~ ^[Yy]?$ ]]; then
        key_alias="$STORED_KEY_ALIAS"
    fi
fi

if [ -z "$key_alias" ]; then
    read -p "Key Alias: " key_alias
fi
set_secret "KEY_ALIAS" "$key_alias"

# Key 密碼
if [ -n "$STORED_KEY_PASSWORD" ]; then
    echo -e "${BLUE}💡 在 local.properties 找到 keyPassword${NC}"
    read -p "使用此密碼? [Y/n]: " use_stored_key_pass
    if [[ "$use_stored_key_pass" =~ ^[Yy]?$ ]]; then
        key_password="$STORED_KEY_PASSWORD"
    fi
fi

if [ -z "$key_password" ]; then
    read -p "Key 密碼: " -s key_password
    echo ""
fi
set_secret "KEY_PASSWORD" "$key_password"

echo ""
echo "🔥 Firebase App Distribution Secrets"
echo "-----------------------------------"

# 嘗試找到 Firebase credentials
FIREBASE_CREDS_DEFAULT="${ANDROID_DIR}/fastlane/findrestaurant_credentials.json"
if [ -f "$FIREBASE_CREDS_DEFAULT" ]; then
    echo -e "${GREEN}🔍 自動找到 Firebase credentials: ${FIREBASE_CREDS_DEFAULT}${NC}"
    read -p "使用此檔案? [Y/n]: " use_firebase
    if [[ "$use_firebase" =~ ^[Yy]?$ ]]; then
        firebase_creds_path="$FIREBASE_CREDS_DEFAULT"
    fi
fi

if [ -z "$firebase_creds_path" ]; then
    read -p "Firebase credentials JSON 檔案路徑: " firebase_creds_path
fi

if [ -n "$firebase_creds_path" ]; then
    firebase_creds_path="${firebase_creds_path/#\~/$HOME}"
    if set_secret_from_file "FIREBASE_CREDENTIALS_BASE64" "$firebase_creds_path"; then
        echo ""
    else
        echo -e "${RED}❌ Firebase credentials 設定失敗,請檢查路徑${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🎉 設定完成!${NC}"
echo ""
echo "已設定的 Secrets:"
echo "  ✅ ANDROID_KEYSTORE_BASE64"
echo "  ✅ KEYSTORE_PASSWORD"
echo "  ✅ KEY_ALIAS"
echo "  ✅ KEY_PASSWORD"
echo "  ✅ FIREBASE_CREDENTIALS_BASE64"
echo ""
echo "你可以到以下網址查看已設定的 secrets:"
echo "https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/settings/secrets/actions"
echo ""
echo -e "${YELLOW}⚠️  注意: 請確保這些敏感檔案不要提交到 Git!${NC}"
