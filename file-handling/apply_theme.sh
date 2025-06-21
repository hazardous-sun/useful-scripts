#!/bin/env bash

# Check if theme name was passed
if [ -z "$1" ]; then
  echo "❌ Error: No theme name provided."
  echo "Usage: $0 <theme-name>"
  exit 1
fi

# Ensure CUSTOM_THEMES_DIR is set
if [ -z "$CUSTOM_THEMES_DIR" ]; then
  echo "❌ Error: CUSTOM_THEMES_DIR environment variable is not set."
  exit 1
fi

THEME_NAME="$1"
THEME_DIR="$CUSTOM_THEMES_DIR/$THEME_NAME"
THEME_FILE="$THEME_DIR/colors.env"

# Check if theme directory exists
if [ ! -d "$THEME_DIR" ]; then
  echo "❌ Error: Theme '$THEME_NAME' not found in $CUSTOM_THEMES_DIR"
  exit 1
fi

# Check if colors.env exists
if [ ! -f "$THEME_FILE" ]; then
  echo "❌ Error: colors.env not found in theme directory: $THEME_FILE"
  exit 1
fi

# Source variables and export them
set -a
source "$THEME_FILE"
set +a

# Apply theme to Waybar
CONFIG_DIR="$HOME/.config"
TEMPLATE="$CONFIG_DIR/waybar/style.css.template"
TARGET="$CONFIG_DIR/waybar/style.css"

if [ ! -f "$TEMPLATE" ]; then
  echo "❌ Error: Waybar template not found: $TEMPLATE"
  exit 1
fi

envsubst < "$TEMPLATE" > "$TARGET"

echo "✅ Theme '$THEME_NAME' applied successfully."

