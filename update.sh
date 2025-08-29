#!/bin/bash

# Update based on Project Type selected:
## Set up the update options
run_updates() {
    echo "Choose a project type:"
    OPTIONS=("Custom" "VPR" "Science" "Exit")

    select OPT in "${OPTIONS[@]}"; do
        case $REPLY in
            1)
                echo "✅ Updating custom modules..."
                # Update UBC Shared Modules
                composer require ubc-web-services/kraken ubc-web-services/ubc_add_to_calendar ubc-web-services/ubc_chosen_style_tweaks ubc-web-services/ubc_ckeditor_widgets ubc-web-services/ubc_d8_config_modules ubc-web-services/ws-recipes:dev-master
                return 0
                ;;
            2)
                echo "✅ Updating custom VPR modules..."
                # Update UBC VPR Modules
                composer require ubc-web-services/kraken-vpr:dev-master ubc-web-services/ubc_add_to_calendar ubc-web-services/ubc_chosen_style_tweaks ubc-web-services/ubc_ckeditor_widgets ubc-web-services/ubc_d8_config_modules ubc-web-services/ws-recipes:dev-master
                # Update child theme core version requirement
                INFO_FILE="web/themes/custom/vpr/vpr.info.yml"
                return 0
                ;;
            3)
                echo "✅ Updating custom Science modules..."
                # Update UBC Science Modules
                composer require ubc-web-services/kraken-science ubc-web-services/ubc_chosen_style_tweaks ubc-web-services/ubc_ckeditor_widgets ubc-web-services/ubc_d8_config_modules ubc-web-services/ws-recipes:dev-master ubc-web-services/ubc_science_shared_config
                # Update child theme core version requirement
                INFO_FILE="web/themes/custom/science/science.info.yml"
                return 0
                ;;
            4)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "❌ Invalid option. Please try again."
                ;;
        esac
  done
}

## Run updates
run_updates

# Update the core version requirement if we can
if [[ -f "$INFO_FILE" ]]; then
    sed -i '' "/^core_version_requirement:/{
        s/.*/core_version_requirement: '>=10'/
    }" "$INFO_FILE"
    echo "✅ Core version requirement updated"
else
  echo "❌ Please update the core_version_requirement value in the .info file manually. This is located in web/themes/custom/[custom-theme-name]. The correct value is '>=10'."
fi

# Add webform patch
COMPOSER_FILE="composer.json"
PATCH_KEY="drupal/webform"
PATCH_DESCRIPTION="Patches help key in node.type.webform to use null instead of empty value - required for installing via recipe"
PATCH_URL="https://raw.githubusercontent.com/ubc-web-services/patches/refs/heads/master/webform_node-help-value.patch"

## Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ jq is not installed."
    echo "Please install jq and run this again."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "On macOS, you can run: brew install jq"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "On Debian/Ubuntu: sudo apt install jq"
        echo "On RedHat/CentOS: sudo yum install jq"
    else
        echo "Visit https://stedolan.github.io/jq/download/ for instructions."
    fi

    exit 1
fi

## Check if the composer file exists
if [[ ! -f "$COMPOSER_FILE" ]]; then
    echo "❌ composer.json not found"
    exit 1
fi

## Check if the patch key is already present
if jq -e --arg key "$PATCH_KEY" '.extra.patches[$key]' "$COMPOSER_FILE" >/dev/null; then
    echo "✅ Patch for $PATCH_KEY already exists. No changes made."
    exit 0
fi

## Use jq to inject the patch
TMP_FILE=$(mktemp)

jq --arg key "$PATCH_KEY" \
   --arg desc "$PATCH_DESCRIPTION" \
   --arg url "$PATCH_URL" \
   'if .extra.patches == {} or (.extra.patches | type == "null")
    then .extra.patches = { ($key): { ($desc): $url } }
    else .extra.patches[$key] = { ($desc): $url }
    end' "$COMPOSER_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$COMPOSER_FILE"

echo "✅ Patch for $PATCH_KEY has been added."

# Update / Add dependencies
composer require drush/drush 'drupal/formtips:^1.11||^2.0' drupal/upgrade_status 'drupal/webform:^6.3@beta' 'drupal/linkit:^7.0' 'drupal/linkit_media_library:^2.0' 'drupal/image_widget_crop:^3.0' 'drupal/file_delete:^3.0'
lando drush pm:enable upgrade_status

echo "All done"