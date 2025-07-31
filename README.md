# Nextcloud GitOps Configuration

This repository contains the Docker Compose configuration for deploying Nextcloud alongside Mailcow with a shared Traefik reverse proxy.

## Architecture

- **Reverse Proxy**: Traefik (shared with Mailcow)
- **Database**: MariaDB 10.11
- **Cache**: Redis 7
- **Storage**: S3-compatible object storage
- **Email**: Integration with Mailcow SMTP

## Prerequisites

1. **Traefik** must be running with a network named `traefik_proxy`
2. **Mailcow** must be installed and accessible
3. **S3 bucket** created and accessible (automatically created if using the main Terraform deployment)
4. **Domain** configured with DNS pointing to your server

## Deployment

### 1. Clone this repository

```bash
git clone https://github.com/your-org/etky-nextcloud-gitops.git
cd etky-nextcloud-gitops
```

### 2. Configure environment

```bash
cp .env.example .env
# Edit .env with your configuration
vim .env
```

Required configuration:
- `DOMAIN_NAME`: Your Nextcloud domain (e.g., cloud.example.com)
- `DB_PASSWORD`, `DB_ROOT_PASSWORD`: Secure database passwords
- `NEXTCLOUD_ADMIN_PASSWORD`: Admin password for Nextcloud
- `S3_*`: Your S3 configuration for object storage
  - For Pilvio S3: endpoint is `s3.pilw.io`, region is `eu-west-1`
  - Credentials are auto-generated if using the main Terraform deployment
- `REDIS_PASSWORD`: Secure Redis password
- `SMTP_*`: Mailcow SMTP configuration (see below)

### 3. Create Mailcow SMTP user

Before starting Nextcloud, create a mailbox in Mailcow:

1. Log into Mailcow admin panel
2. Create a new mailbox: `noreply@yourdomain.com`
3. Use the password in your `.env` file as `SMTP_PASSWORD`

### 4. Ensure Traefik network exists

```bash
docker network create traefik_proxy || true
```

### 5. Start Nextcloud

```bash
docker compose up -d
```

### 6. Run post-installation configuration

```bash
# Wait for Nextcloud to initialize (about 1-2 minutes)
./scripts/post-install.sh
```

## Management

### Service Control

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f [service]

# Restart a service
docker compose restart [service]
```

### Nextcloud OCC Commands

```bash
# Run any occ command
docker compose exec -u www-data app php occ [command]

# Examples:
docker compose exec -u www-data app php occ status
docker compose exec -u www-data app php occ user:list
docker compose exec -u www-data app php occ app:list
```

### Health Check

```bash
./scripts/health-check-api.sh
```

### Maintenance

```bash
# Enable maintenance mode
docker compose exec -u www-data app php occ maintenance:mode --on

# Disable maintenance mode
docker compose exec -u www-data app php occ maintenance:mode --off

# Run file scan
docker compose exec -u www-data app php occ files:scan --all

# Clean up
docker compose exec -u www-data app php occ files:cleanup
```

## Integration with Mailcow

This configuration is designed to work alongside Mailcow:

1. **Email**: Nextcloud uses Mailcow's SMTP server for sending emails
2. **Network**: Both services share the Traefik network for reverse proxy
3. **Domains**: Ensure your domains don't conflict (e.g., mail.example.com for Mailcow, cloud.example.com for Nextcloud)

## Backup

Backups are handled by the main infrastructure deployment (Ansible):
- Database dumps are taken daily
- Configuration is backed up to S3
- Data is already in S3 (primary storage)

## Troubleshooting

### Nextcloud is not accessible

1. Check if all containers are running:
   ```bash
   docker compose ps
   ```

2. Check Traefik logs:
   ```bash
   docker logs traefik
   ```

3. Verify network connectivity:
   ```bash
   docker network ls | grep traefik_proxy
   ```

### Email not working

1. Verify SMTP settings:
   ```bash
   docker compose exec -u www-data app php occ config:system:get mail_smtphost
   ```

2. Test email:
   ```bash
   docker compose exec -u www-data app php occ config:system:set mail_send_plaintext_only --value=true
   docker compose exec -u www-data app php occ mail:send-test your-email@example.com
   ```

### S3 connection issues

1. Check S3 configuration:
   ```bash
   docker compose exec -u www-data app php occ config:system:get objectstore
   ```

2. Verify S3 credentials in `.env` file

## Updates

To update Nextcloud:

1. Update the version in `.env`:
   ```bash
   NEXTCLOUD_VERSION=32
   ```

2. Pull new images:
   ```bash
   docker compose pull
   ```

3. Restart services:
   ```bash
   docker compose up -d
   ```

4. Run post-update tasks:
   ```bash
   docker compose exec -u www-data app php occ upgrade
   docker compose exec -u www-data app php occ db:add-missing-indices
   ```

## Security Considerations

- All passwords should be strong and unique
- SSL/TLS is handled by Traefik automatically
- Redis is password-protected
- Database is only accessible within the internal network
- Regular updates should be applied
- Enable 2FA for admin accounts

## Support

For issues related to:
- **This configuration**: Open an issue in this repository
- **Nextcloud**: See [Nextcloud documentation](https://docs.nextcloud.com)
- **Infrastructure**: Contact your system administrator