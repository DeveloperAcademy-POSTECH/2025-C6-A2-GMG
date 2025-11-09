#!/bin/sh

# Check if HomeBrew is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Installing it now..."
    
    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Set Homebrew path (for macOS)
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
    
    echo "Homebrew installation completed."
else
    echo "Homebrew is already installed."
fi

# Check if swift-format is installed
if ! command -v swift-format &> /dev/null; then
    echo "swift-format is not installed. Installing it now..."

    # Install swift-format
    brew install swift-format

    echo "swift-format installation completed."
else
    echo "swift-format is already installed."
fi

# Copy the pre-commit hook to the .git/hooks directory
cp -f Scripts/Hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
echo "Pre-commit hook installed successfully."

# Clone env repository only if .env directory does not exist
if [ ! -d .env ]; then
    echo ".env folder not found. Cloning env repository..."
    git clone https://github.com/ADA-4th-C6-GMG/GMG-Env.git .env
else
    echo ".env folder already exists."
fi

# Create symbolic link for fastlane/.env if it doesn't exist
if [ ! -e fastlane/.env ]; then
    ln -s ../.env/.env fastlane/.env
    echo "Symbolic link for fastlane/.env created."
else
    echo "Symbolic link for fastlane/.env already exists."
fi