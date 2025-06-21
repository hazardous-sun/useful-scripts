#!/bin/env bash

#-------------------------------#
#        CONFIGURATION         #
#-------------------------------#
CONFIG_DIR="$HOME/.config"

#-------------------------------#
#        LOG FUNCTIONS         #
#-------------------------------#
log_info()    { echo -e "ℹ️ $1"; }
log_success() { echo -e "✅ $1"; }
log_error()   { echo -e "❌ $1" >&2; }

#-------------------------------#
#     VALIDATION FUNCTIONS     #
#-------------------------------#

check_env_vars() {
  if [[ -z "$CUSTOM_THEMES_DIR" ]]; then
    log_error "CUSTOM_THEMES_DIR environment variable is not set."
    exit 1
  fi
}

check_theme_name() {
  if [[ -z "$1" ]]; then
    log_error "No theme name provided."
    echo "Usage: $0 <theme-name>"
    exit 1
  fi
}

check_theme_dir() {
  if [[ ! -d "$THEME_DIR" ]]; then
    log_error "Theme '$THEME_NAME' not found in $CUSTOM_THEMES_DIR"
    exit 1
  fi
}

check_colors_file() {
  if [[ ! -f "$THEME_COLORS_FILE" ]]; then
    log_error "colors.env not found in: $THEME_COLORS_FILE"
    exit 1
  fi
}

#-------------------------------#
#         APPLY THEME          #
#-------------------------------#

apply_templates_in_config() {
  log_info "Searching for style.css.template files in $CONFIG_DIR..."

  find "$CONFIG_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
    template="$dir/style.css.template"
    output="$dir/style.css"

    if [[ -f "$template" ]]; then
      log_info "Applying theme to: $template"
      envsubst < "$template" > "$output"
      log_success "Generated: $output"
    fi
  done
}

#-------------------------------#
#              MAIN            #
#-------------------------------#

main() {
  check_env_vars
  check_theme_name "$1"

  THEME_NAME="$1"
  THEME_DIR="$CUSTOM_THEMES_DIR/$THEME_NAME"
  THEME_COLORS_FILE="$THEME_DIR/colors.env"

  check_theme_dir
  check_colors_file

  log_info "Loading theme variables from: $THEME_COLORS_FILE"
  set -a
  source "$THEME_COLORS_FILE"
  set +a

  apply_templates_in_config
}

main "$@"

