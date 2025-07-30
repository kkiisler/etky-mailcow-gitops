#!/bin/bash

# Fix permissions for Nextcloud
# This script runs as the entrypoint to ensure proper permissions

set -e

# Function to fix ownership
fix_ownership() {
    echo "Fixing ownership for Nextcloud data..."
    chown -R www-data:www-data /var/www/html/data 2>/dev/null || true
    chown -R www-data:www-data /var/www/html/config 2>/dev/null || true
    chown -R www-data:www-data /var/www/html/apps 2>/dev/null || true
    chown -R www-data:www-data /var/www/html/themes 2>/dev/null || true
}

# Function to fix permissions
fix_permissions() {
    echo "Setting proper permissions..."
    find /var/www/html -type d -exec chmod 755 {} \; 2>/dev/null || true
    find /var/www/html -type f -exec chmod 644 {} \; 2>/dev/null || true
    
    # Special permissions for config and data
    chmod 770 /var/www/html/data 2>/dev/null || true
    chmod 770 /var/www/html/config 2>/dev/null || true
}

# Main execution
echo "Starting Nextcloud with permission fixes..."
fix_ownership
fix_permissions

# Execute the original command
exec "$@"