#!/bin/bash
# Docker Group Setup Script
# This script adds the current user to the docker group to avoid needing sudo

set -e

echo "Setting up Docker permissions..."

# Check if docker group exists
if ! getent group docker > /dev/null 2>&1; then
    echo "Creating docker group..."
    sudo groupadd docker
else
    echo "Docker group already exists."
fi

# Add current user to docker group if not already a member
if ! groups $USER | grep -q '\bdocker\b'; then
    echo "Adding $USER to docker group..."
    sudo usermod -aG docker $USER
    echo "✓ User $USER added to docker group."
    echo ""
    echo "IMPORTANT: You need to log out and log back in for this to take effect."
    echo "Or run: newgrp docker"
else
    echo "✓ User $USER is already in docker group."
fi

# Verify Docker is running
if systemctl is-active --quiet docker; then
    echo "✓ Docker service is running."
else
    echo "⚠ Docker service is not running. Starting it..."
    sudo systemctl start docker
    sudo systemctl enable docker
fi

echo ""
echo "Docker setup complete!"
echo "To activate in current session, run: newgrp docker"

# Function to restart VS Code with docker group
restart_vscode() {
    echo ""
    echo "=== VS Code Docker Permission Fix ==="

    # Check if VS Code is running
    if pgrep -f "code" > /dev/null 2>&1; then
        echo "VS Code is currently running."
        echo "VS Code needs to be restarted to access Docker without sudo."
        echo ""
        read -p "Do you want to restart VS Code now? (y/n): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Stopping VS Code..."
            pkill -f "code" || true
            sleep 2

            # Find the workspace directory
            WORKSPACE_DIR="/home/ubuntu/MegaDLMs"
            if [ -d "$WORKSPACE_DIR" ]; then
                echo "Restarting VS Code with docker permissions..."
                sg docker -c "code $WORKSPACE_DIR" &
                echo "✓ VS Code restarted with docker group access."
            else
                echo "Starting VS Code with docker permissions..."
                sg docker -c "code" &
                echo "✓ VS Code started with docker group access."
            fi
        else
            echo "Skipped VS Code restart."
            echo "To manually restart VS Code with docker access:"
            echo "  1. Close VS Code completely"
            echo "  2. Run: sg docker -c 'code /home/ubuntu/MegaDLMs'"
        fi
    else
        echo "VS Code is not currently running."
        echo "When you start VS Code, run: sg docker -c 'code /home/ubuntu/MegaDLMs'"
    fi
}

# Check if we need to fix VS Code permissions
if command -v code > /dev/null 2>&1; then
    # Only offer to restart VS Code if user was just added to docker group
    # or if not currently in docker group
    if ! groups | grep -q '\bdocker\b' 2>/dev/null; then
        restart_vscode
    fi
fi

echo ""
echo "=========================================="
echo "=== GitHub SSH Key Setup ==="
echo "=========================================="

# SSH key setup for GitHub
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
SSH_KEY_COMMENT="$USER@$(hostname)-github"

if [ -f "$SSH_KEY_PATH" ]; then
    echo "✓ SSH key already exists at $SSH_KEY_PATH"
else
    echo "Generating new SSH key for GitHub..."
    read -p "Enter your GitHub email address: " github_email

    if [ -z "$github_email" ]; then
        echo "⚠ No email provided. Using default comment."
        github_email="$SSH_KEY_COMMENT"
    fi

    # Generate SSH key
    ssh-keygen -t ed25519 -C "$github_email" -f "$SSH_KEY_PATH" -N ""
    echo "✓ SSH key generated successfully!"
fi

# Start ssh-agent and add key
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    echo "Starting ssh-agent..."
    eval "$(ssh-agent -s)"
fi

# Add key to ssh-agent
if ! ssh-add -l | grep -q "$SSH_KEY_PATH" 2>/dev/null; then
    echo "Adding SSH key to ssh-agent..."
    ssh-add "$SSH_KEY_PATH" 2>/dev/null || true
fi

# Display the public key
echo ""
echo "=========================================="
echo "Your GitHub SSH public key:"
echo "=========================================="
cat "$SSH_KEY_PATH.pub"
echo "=========================================="
echo ""
echo "To add this key to GitHub:"
echo "1. Copy the key above (the entire line)"
echo "2. Go to: https://github.com/settings/ssh/new"
echo "3. Give it a title (e.g., 'Ubuntu Development Machine')"
echo "4. Paste the key and click 'Add SSH key'"
echo ""
echo "Or copy to clipboard with: cat $SSH_KEY_PATH.pub | xclip -selection clipboard"
echo "Or view again with: cat $SSH_KEY_PATH.pub"
echo ""

# Add GitHub to known_hosts if not already there
if ! ssh-keygen -F github.com > /dev/null 2>&1; then
    echo "Adding GitHub to known_hosts..."
    ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null
    echo "✓ GitHub added to known_hosts"
fi

# Test GitHub connection (optional)
read -p "Do you want to test the GitHub SSH connection now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Testing GitHub SSH connection..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "✓ GitHub SSH authentication successful!"
    else
        echo "⚠ GitHub SSH test failed. Make sure you've added the key to GitHub."
        echo "   Go to: https://github.com/settings/ssh/new"
    fi
fi

echo ""
echo "=========================================="
echo "=== Git Remote Configuration ==="
echo "=========================================="

# Check if we're in a git repository
if [ -d ".git" ]; then
    # Get current remote URL
    CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")

    if [ -n "$CURRENT_REMOTE" ]; then
        # Convert HTTPS URLs to SSH
        if echo "$CURRENT_REMOTE" | grep -q "^https://github.com"; then
            # Extract username/repo from HTTPS URL
            SSH_URL=$(echo "$CURRENT_REMOTE" | sed 's|https://github.com/|git@github.com:|' | sed 's|\.git$||').git

            echo "Converting remote from HTTPS to SSH..."
            echo "  Old: $CURRENT_REMOTE"
            echo "  New: $SSH_URL"

            git remote set-url origin "$SSH_URL"
            echo "✓ Remote URL updated to use SSH"
        else
            echo "✓ Remote is already using SSH: $CURRENT_REMOTE"
        fi
    else
        echo "⚠ No remote 'origin' found in this repository"
    fi
else
    echo "Not in a git repository, skipping remote configuration"
fi

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
