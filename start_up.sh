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
