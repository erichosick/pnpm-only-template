#!/bin/bash

# What this script does:
# The script utilizes the `jq` utility for JSON parsing and manipulation, so
# it needs to be installed for the script to work correctly.
# - **Initialize Errors Array**: An empty array named `errors` is initialized to
# store any error messages.
# - **Check for Git**: The script checks if Git is installed. If not, an error
# message is added to the `errors` array.
# - **Check for jq**: It then checks for the existence of the `jq` utility.
# If missing, another error message is added to the array.
# - **Check for package.json**: It checks for the existence of a `package.json`
# file in the current directory. If it doesn't exist, an error message
# is stored.
# - **Print Errors and Exit**: If there are any stored error messages in the
# `errors` array, the script prints them all and exits with a status code of 1.
# - **Check/Create .npmrc**: The script checks for a `.npmrc` file and creates
# one if it doesn't exist.
# - **Update .npmrc**: If the `.npmrc` file doesn't contain the line
#`engine-strict=true`, this line is appended to the file.
# - **Check for 'only-allow' in devDependencies**: The script checks if
# `only-allow` is present in the `devDependencies` field of `package.json`.
# If not, it installs `only-allow` as a dev dependency.
# - **Check/Add Scripts**: It checks if a `scripts` field exists in
# `package.json`. If not, it adds one with a `preinstall` script. If
# `preinstall` already exists, it appends to it.
# - **Check/Add Engines**: It checks for the existence of an `engines`
# field and a nested `npm` field in `package.json`. If not present, these are added with specific values.
# - **User Prompt for Overwriting npm Value**: If an `npm` field exists under
#`engines` but has a different value, the script prompts the user for permission
# to overwrite it. Based on the user's choice, it either overwrites the value or
# prints a warning message.

# Array to store error messages
errors=()

# Check for jq
if ! command -v jq &> /dev/null; then
  errors+=("jq is not installed. Please install it (https://jqlang.github.io/jq/) and try again.")
fi

# Check for package.json
if [ ! -f "package.json" ]; then
  errors+=("package.json not found. Please run 'pnpm init' and try again.")
fi

# If errors array has one or more elements, print them and exit
if [ ${#errors[@]} -ne 0 ]; then
  for err in "${errors[@]}"; do
    echo "$err"
  done
  exit 1
fi

# Check if .npmrc exists, if not create it
if [ ! -f ".npmrc" ]; then
  touch .npmrc
fi

# Check if "engine-strict=true" is in .npmrc, if not add it
if ! grep -q "engine-strict=true" .npmrc; then
  cat <<EOL >> .npmrc
# Stop npm from being used as the installer.
# The following was added to package.json
# { "engines": { "npm": "Use pnpm instead of npm." } }
engine-strict=true
EOL
fi

# Check if 'only-allow' exists in devDependencies of package.json
if ! jq -e '.devDependencies["only-allow"]' package.json &>/dev/null; then
  # If not found, install it as a dev dependency
  echo "Installing 'only-allow' as a development dependency."
  pnpm install --save-dev only-allow
fi

# Check if scripts field exists in package.json
if ! jq -e '.scripts' package.json &>/dev/null; then
  # Add scripts field with preinstall if it doesn't exist
  jq '. + { "scripts": { "preinstall": "npx only-allow pnpm" } }' package.json > tmp.json && mv tmp.json package.json
else
  # Check if preinstall script exists
  if jq -e '.scripts.preinstall' package.json &>/dev/null; then
    existing_script=$(jq -r '.scripts.preinstall' package.json)
    
    # Check if 'npx only-allow pnpm' is already in the preinstall script
    if [[ $existing_script != *"npx only-allow pnpm"* ]]; then
      # If preinstall script is empty
      if [ -z "$existing_script" ]; then
        new_script="npx only-allow pnpm"
      else
        # Append 'npx only-allow pnpm' to existing preinstall script
        new_script="${existing_script} && npx only-allow pnpm"
      fi
      jq --arg ns "$new_script" '.scripts.preinstall = $ns' package.json > tmp.json && mv tmp.json package.json
    fi
  else
    # Add preinstall script if it doesn't exist
    jq '.scripts += { "preinstall": "npx only-allow pnpm" }' package.json > tmp.json && mv tmp.json package.json
  fi
fi

# Function to prompt user for overwriting npm value
overwrite_npm() {
  read -p "Can we overwrite? (y/n): " answer
  if [ "$answer" == "y" ]; then
    jq '.engines.npm = "Use pnpm instead of npm."' package.json > tmp.json && mv tmp.json package.json
  else
    echo "pnpm-only will not work with the current version value in engines.npm."
  fi
}

# Check if engines field exists in package.json
if ! jq -e '.engines' package.json &>/dev/null; then
  jq '. + { "engines": { "npm": "Use pnpm instead of npm." } }' package.json > tmp.json && mv tmp.json package.json
else
  # Check if npm exists under engines
  if jq -e '.engines.npm' package.json &>/dev/null; then
    existing_npm=$(jq -r '.engines.npm' package.json)
    if [ "$existing_npm" != "Use pnpm instead of npm." ]; then
      echo "engines.npm contains an npm version. For this script to work, we will need to overwrite that value."
      overwrite_npm
    fi
  else
    # Add npm if it doesn't exist under engines
    jq '.engines += { "npm": "Use pnpm instead of npm." }' package.json > tmp.json && mv tmp.json package.json
  fi
fi
