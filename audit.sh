#!/usr/bin/env bash
# project_info.sh
# Summarizes key Drupal project info:
#  1. .platform/services.yaml types
#  2. Custom module directories
#  3. Composer require dependencies (excluding specific packages)
#  4. Composer extra.patches list (if present)
# Writes output to project_summary.md

set -euo pipefail

SERVICES_FILE=".platform/services.yaml"
CUSTOM_MODULES_DIR="web/modules/custom"
COMPOSER_FILE="composer.json"
OUTPUT_FILE="project_summary.md"

# Start fresh Markdown file
echo "# Project Summary" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Helper function to echo to stdout and append to markdown
echo_md() {
  printf "%s\n" "$1" | tee -a "$OUTPUT_FILE"
}

#####################################
# 1. Check and output service types #
#####################################

echo_md "## Platform Service Types"

if [[ -f "$SERVICES_FILE" ]]; then
  if ! command -v yq >/dev/null 2>&1; then
    echo_md "Error: yq is required but not installed."
    exit 1
  fi

  top_keys=$(yq eval 'keys | .[]' "$SERVICES_FILE")
  for key in $top_keys; do
    type=$(yq eval ".\"$key\".type" "$SERVICES_FILE")
    echo_md "- **$key**: $type"
  done
else
  echo_md "No .platform/services.yaml file found."
fi

echo_md ""

#####################################
# 2. Output custom module directories #
#####################################

echo_md "## Custom Modules"

if [[ -d "$CUSTOM_MODULES_DIR" ]]; then
  modules=$(find "$CUSTOM_MODULES_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
  if [[ -n "$modules" ]]; then
    for mod in $modules; do
      echo_md "- $(basename "$mod")"
    done
  else
    echo_md "No custom modules found in $CUSTOM_MODULES_DIR."
  fi
else
  echo_md "No custom modules directory found at $CUSTOM_MODULES_DIR."
fi

echo_md ""

#####################################
# 3. Composer require dependencies  #
#####################################

echo_md "## Composer Dependencies (require)"

if [[ -f "$COMPOSER_FILE" ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    echo_md "Error: jq is required but not installed."
    exit 1
  fi

  EXCLUDE_KEYS='[
    "composer/installers",
    "cweagans/composer-patches",
    "drupal/address",
    "drupal/admin_toolbar",
    "drupal/allowed_formats",
    "drupal/antibot",
    "drupal/auto_entitylabel",
    "drupal/better_exposed_filters",
    "drupal/block_exclude_pages",
    "drupal/chosen",
    "drupal/ckeditor5_fullscreen",
    "drupal/ckeditor5_plugin_pack",
    "drupal/conditional_fields",
    "drupal/config_filter",
    "drupal/config_ignore",
    "drupal/core-composer-scaffold",
    "drupal/core-project-message",
    "drupal/core-recommended",
    "drupal/crop",
    "drupal/date_popup",
    "drupal/datetimehideseconds",
    "drupal/default_content",
    "drupal/devel",
    "drupal/dropzonejs",
    "drupal/easy_breadcrumb",
    "drupal/editor_advanced_link",
    "drupal/entity_reference_revisions",
    "drupal/entityqueue",
    "drupal/field_group",
    "drupal/file_delete",
    "drupal/file_to_media",
    "drupal/focal_point",
    "drupal/formtips",
    "drupal/fullcalendar_view",
    "drupal/gin",
    "drupal/gin_login",
    "drupal/gin_toolbar",
    "drupal/google_analytics",
    "drupal/google_tag",
    "drupal/image_widget_crop",
    "drupal/inline_entity_form",
    "drupal/link_attributes",
    "drupal/linkit",
    "drupal/linkit_media_library",
    "drupal/maxlength",
    "drupal/media_alias_display",
    "drupal/media_bulk_upload",
    "drupal/media_entity_file_replace",
    "drupal/menu_block",
    "drupal/metatag",
    "drupal/migrate_plus",
    "drupal/migrate_tools",
    "drupal/node_revision_delete",
    "drupal/oembed_providers",
    "drupal/optional_end_date",
    "drupal/paragraphs",
    "drupal/pathauto",
    "drupal/quick_node_clone",
    "drupal/rebuild_cache_access",
    "drupal/redirect",
    "drupal/redis",
    "drupal/responsive_table_filter",
    "drupal/role_delegation",
    "drupal/scheduler",
    "drupal/simple_gmap",
    "drupal/simple_sitemap",
    "drupal/smart_date",
    "drupal/smtp",
    "drupal/svg_image",
    "drupal/text_summary_options",
    "drupal/twig_tweak",
    "drupal/upgrade_status",
    "drupal/view_unpublished",
    "drupal/views_autosubmit",
    "drupal/views_bulk_edit",
    "drupal/webform",
    "drush/drush",
    "enyo/dropzone",
    "exif-js/exif-js",
    "oomphinc/composer-installers-extender",
    "platformsh/config-reader",
    "ubc-web-services/ubc_add_to_calendar",
    "ubc-web-services/kraken",
    "ubc-web-services/kraken-science",
    "ubc-web-services/kraken-vpr",
    "ubc-web-services/ubc_chosen_style_tweaks",
    "ubc-web-services/ubc_ckeditor_widgets",
    "ubc-web-services/ubc_d8_config_modules",
    "ubc-web-services/ubc_science_shared_config",
    "ubc-web-services/ws-recipes",
    "wikimedia/composer-merge-plugin"
  ]'

  composer_output=$(jq -r --argjson exclude "$EXCLUDE_KEYS" '
    if .require then
      .require
      | to_entries[]
      | select(.key as $k | ($exclude | index($k)) | not)
      | "- \(.key): \(.value)"
    else
      empty
    end
  ' "$COMPOSER_FILE")

  if [[ -n "$composer_output" ]]; then
    echo_md "$composer_output"
  else
    echo_md "No remaining composer dependencies found after exclusions."
  fi

  echo_md ""

  ##########################################
  # 4. Composer extra.patches (if present) #
  ##########################################

  echo_md "## Composer Patches (extra > patches)"

  patch_output=$(jq -r '
    if .extra and .extra.patches then
      .extra.patches | to_entries[] |
      "\(.key):\n" + ( .value | to_entries[] | "  - \(.key): \(.value)" )
    else
      empty
    end
  ' "$COMPOSER_FILE")

  if [[ -n "$patch_output" ]]; then
    echo_md "$patch_output"
  else
    echo_md "No patches defined under extra.patches."
  fi

else
  echo_md "No composer.json file found."
fi

echo_md ""
echo "Project summary written to $OUTPUT_FILE"