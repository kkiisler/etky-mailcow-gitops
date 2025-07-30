#!/bin/bash

# Nextcloud post-installation configuration script
# This script runs after the initial Nextcloud installation

set -e

echo "Running Nextcloud post-installation configuration..."

# Wait for Nextcloud to be fully ready
echo "Waiting for Nextcloud to be ready..."
until docker-compose exec -T app su -s /bin/sh www-data -c "php occ status" 2>/dev/null | grep -q "installed: true"; do
    echo "Waiting for Nextcloud installation to complete..."
    sleep 10
done

echo "Nextcloud is ready. Starting configuration..."

# Set background jobs to cron
echo "Configuring background jobs..."
docker-compose exec -T app su -s /bin/sh www-data -c "php occ background:cron" || true

# Configure Redis caching
echo "Configuring Redis caching..."
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set redis host --value='redis'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set redis port --value='6379' --type=integer" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set redis password --value='$REDIS_PASSWORD'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set redis timeout --value='0.0' --type=float" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set redis dbindex --value='0' --type=integer" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set memcache.local --value='\\OC\\Memcache\\Redis'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set memcache.distributed --value='\\OC\\Memcache\\Redis'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set memcache.locking --value='\\OC\\Memcache\\Redis'" || true

# Configure email settings (add after Redis configuration)
if [ -n "$SMTP_HOST" ]; then
    echo "Configuring email settings..."
    docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set mail_smtpmode --value='smtp'" || true
    docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set mail_smtphost --value='$SMTP_HOST'" || true
    docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set mail_smtpport --value='$SMTP_PORT'" || true
    docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set mail_smtpsecure --value='$SMTP_SECURE'" || true
    docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set mail_from_address --value='$MAIL_FROM_ADDRESS'" || true
    docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set mail_domain --value='$MAIL_DOMAIN'" || true
    
    if [ -n "$SMTP_NAME" ] && [ -n "$SMTP_PASSWORD" ]; then
        docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set mail_smtpauth --value='1'" || true
        docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set mail_smtpname --value='$SMTP_NAME'" || true
        docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set mail_smtppassword --value='$SMTP_PASSWORD'" || true
    fi
fi

# Configure S3 as primary storage
echo "Configuring S3 primary storage..."
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set objectstore class --value='\\OC\\Files\\ObjectStore\\S3'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set objectstore arguments bucket --value='$S3_BUCKET'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set objectstore arguments key --value='$S3_ACCESS_KEY'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set objectstore arguments secret --value='$S3_SECRET_KEY'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set objectstore arguments region --value='$S3_REGION'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set objectstore arguments hostname --value='$S3_ENDPOINT'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set objectstore arguments port --value='443'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set objectstore arguments use_ssl --value='true' --type=boolean" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set objectstore arguments use_path_style --value='true' --type=boolean" || true

# Configure trusted domains
echo "Configuring trusted domains..."
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set trusted_domains 0 --value='$DOMAIN_NAME'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set overwrite.cli.url --value='https://$DOMAIN_NAME'" || true

# Configure logging
echo "Configuring logging..."
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set log_type --value='file'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set logfile --value='/var/www/html/data/nextcloud.log'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set loglevel --value='2'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set logrotate_size --value='104857600'" || true

# Enable recommended apps
echo "Enabling recommended apps..."
docker-compose exec -T app su -s /bin/sh www-data -c "php occ app:enable twofactor_totp" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ app:enable bruteforcesettings" || true

# Run maintenance tasks
echo "Running maintenance tasks..."
docker-compose exec -T app su -s /bin/sh www-data -c "php occ db:add-missing-indices" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ db:add-missing-columns" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ db:add-missing-primary-keys" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ db:convert-filecache-bigint --no-interaction" || true

# Set default phone region
echo "Setting default phone region..."
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set default_phone_region --value='EE'" || true

# Configure preview generation
echo "Configuring preview generation..."
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set preview_max_x --value='2048'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set preview_max_y --value='2048'" || true
docker-compose exec -T app su -s /bin/sh www-data -c "php occ config:system:set jpeg_quality --value='60'" || true

echo "Post-installation configuration completed!"