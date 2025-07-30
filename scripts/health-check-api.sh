#!/bin/bash

# Health check script for Nextcloud
# Returns 0 if healthy, 1 if unhealthy

# Check if Nextcloud is responding
if ! curl -f -s "http://nextcloud-app/status.php" > /dev/null; then
    echo "ERROR: Nextcloud is not responding"
    exit 1
fi

# Check database connection
if ! docker exec nextcloud-db mysqladmin ping -h localhost -u root -p${DB_ROOT_PASSWORD} --silent; then
    echo "ERROR: Database is not responding"
    exit 1
fi

# Check Redis if enabled
if [ "$ENABLE_REDIS" = "true" ]; then
    if ! docker exec nextcloud-redis redis-cli --pass "$REDIS_PASSWORD" ping > /dev/null 2>&1; then
        echo "ERROR: Redis is not responding"
        exit 1
    fi
fi

echo "All services are healthy"
exit 0