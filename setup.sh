#!/bin/bash

# Check for Homebrew and install if missing
if ! command -v brew &>/dev/null; then
  echo "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Check for aspell and install if missing
if ! brew ls --versions aspell > /dev/null; then
  echo "aspell not found. Installing..."
  brew install aspell
fi

# Install Ruby gems
echo "Installing Ruby gems..."
bundle install

echo "Setup completed."

