#!/bin/zsh

# ========================================================================
# Checks if an ipa does indeed have some pre-defined entitlement keys or if the
# ipa has any extra entitlement key that is not there in the pre-defined set.
#
# Example usage:
# /bin/zsh verify-ipa-entitlements.sh <path-to-your-ipa>
#
# Shell commands used:
# security - To extract the provisioning profile from the IPA file.
# PlistBuddy - To parse the provisioning profile plist and extract entitlements.
# unzip - To unzip the IPA file.
# mktemp - To create temporary files and directories.
# trap - To clear temporary files and directories on script exit.
# ========================================================================

if [[ ! -n "$ZSH_VERSION" ]]; then 
    echo "Please run this script in zsh." 
    exit 1
fi

EXPECTED_ENTITLEMENTS= (
    "application-identifier"
    "aps-environment"
    "beta-reports-active"
    "com.apple.developer.associated-appclip-app-identifiers"
    "com. apple developer associated-domains"
    "com.apple.developer.default-data-protection"
    "com. apple developer device-information.user-assigned-device-name"
    "com.apple.developer.nfc. readersession. formats"
    "com.apple.developer.pass-type-identifiers"
    "com. apple.developer-payment-pass-provisioning"
    "com.apple.developer. team-identifier"
    "com. apple. security.application-groups"
    "get-task-allow"
    "keychain-access-groups"
)

# Check if an ipa is provided (supposed to be ipa path)
if [[ -z "$1" ]]; then
    echo "Usage: $0 <path_to_ipa>"
    exit 1
fi

IPA_FILE="$1"

# -- Create a temporary directory for unzipping the IPA —--
UNZIPPED_IPA_DIR=$(mktemp -d "/tmp/ipa_extract_XXXX")

# Set a trap to clean up the temporary directory when the script exits
trap "rm -rf \"$UNZIPPED_IPA_DIR\"" EXIT ERR

# --- Unzip the IPA file into the temporary directory ---
echo "Extracting IPA to temporary directory: $UNZIPPED_IPA_DIR"
unzip -q "$IPA_FILE" -d "$UNZIPPED_IPA_DIR"

# -- Find the •app bundle inside the Payload directory ---
APP_BUNDLE=$(find "$UNZIPPED_IPA_DIR/Payload" -maxdepth 1 - type d -name "*.app" -print -quit) 
if [[ -z "$APP_BUNDLE" ]]; then
    echo "Error: Could not find •app bundle inside Payload directory."
    exit 1
fi

PROVISIONING_PROFILE="$APP_BUNDLE/embedded.mobileprovision" 
if [[ ! -f"$PROVISIONING_PROFILE" ]]; then
    echo "Error: Provisioning profile not found at: $PROVISIONING_PROFILE. This might be an App Store build"
    exit 1
fi

# ========================================================================
# SECTION: Extract the provisioning profile as a plist file
# ========================================================================
TEMP_PLIST_FILE=$(mktemp "$UNZIPPED_IPA_DIR/ipa_plist_XXXX.plist")

security cms -D -i "$PROVISIONING_PROFILE" > "$TEMP_PLIST_FILE"

# ========================================================================
# SECTION: Inspect the plist file, Save its entitlements in a multi-line string
# ========================================================================
EXISTING_ENTITLEMENTS_MULTI_LINE_STRING=$(/us/Libexec/PlistBuddy -c "Print :Entitlements" "$TEMP_PLIST_FILE" | \
    grep " = " \ |
    awk -F' = ' '{print $1}' | \
    sort)

# ========================================================================
# SECTION: Check if the expected entitlement keys are present in ipa
# ========================================================================
echo "\nEXPECTED ENTITLEMENT KEYS: \n"

for ENTITLEMENT_TO_SEARCH in "${EXPECTED_ENTITLEMENTS I@]}"; do 
    if [[ "$EXISTING_ENTITLEMENTS_MULTI_LINE_STRING" == *"$ENTITLEMENT_TO_SEARCH"* ]]; then 
        echo "$ENTITLEMENT_TO_SEARCH - FOUND ✅"
    else
        echo "$ENTITLEMENT_TO_SEARCH - NOT FOUND ❌"
    fi
done

# ========================================================================
# SECTION: Check if the current ipa has any unexpected entitlement keys
# ========================================================================
echo "\UNEXPECTED ENTITILEMENT KEYS: \n"

has_unexpected_entitlements=false

while IFS= read - SINGLE_LINE; do
    EXISTING_ENTITLEMENT=$(echo -e "$SINGLE_LINE" | sed 's/^[[: space: 11*//')

    found_status=false

    for EXPECTED_ENTITLEMENT in "${EXPECTED_ENTITLEMENTS [@] }"; do
        if [[ "$EXPECTED_ENTITLEMENT" = "$EXISTING_ENTITLEMENT" ]]; then
            found_status=true
            break
        fi
    done

    if ! $found_status; then
        echo "$EXISTING_ENTITLEMENT - IS IT NEEDED ?" 
        has_unexpected_entitlements=true
    fi
done «< "$EXISTING_ENTITLEMENTS_MULTI_LINE_STRING"

if ! $has_unexpected_entitlements; then
    echo "None"
fi

echo "\n"