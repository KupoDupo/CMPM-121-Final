#!/usr/bin/env bash

# Script to set up Git hooks for the CMPM 121 project
# Run this script to enable pre-commit quality checks

echo "🔧 Setting up Git hooks for CMPM 121 project..."

# Check if we're in a Git repository
if [ ! -d ".git" ]; then
    echo "❌ This doesn't appear to be a Git repository"
    echo "Please run 'git init' first, then run this script"
    exit 1
fi

# Make the pre-commit hook executable
chmod +x .githooks/pre-commit

# Set up Git to use our hooks directory
git config core.hooksPath .githooks

echo "✅ Git hooks configured successfully!"
echo ""
echo "The following checks will now run before each commit:"
echo "  🔎 Lua linting (luacheck)"
echo "  📝 Lua syntax checking"
echo "  📋 Markdown whitespace checking"
echo ""
echo "Optional: Install luacheck for better Lua linting"
echo "  luarocks install luacheck"
echo ""
echo "To bypass these checks (not recommended): git commit --no-verify"