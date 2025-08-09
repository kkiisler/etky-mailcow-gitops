# Nextcloud GitOps Configuration

This repository contains the Docker Compose configuration for deploying Nextcloud alongside Mailcow with a shared Traefik reverse proxy.

## Overview

This GitOps repository is primarily used by the [etky-mailcow](https://github.com/kkiisler/etky-mailcow) Ansible automation for deploying Nextcloud. While it can be used for manual deployments, it's designed to work seamlessly with the automated infrastructure provisioning.

## Architecture

- **Reverse Proxy**: Traefik (shared with Mailcow)
- **Database**: MariaDB 10.11
- **Cache**: Redis 7
- **Storage**: S3-compatible object storage (Pilvio S3)
- **Email**: Integration with Mailcow SMTP
- **Monitoring**: Python-based monitoring with Slack alerts
- **Backup**: Automated S3 backups via unified backup system

## Prerequisites

1. **Traefik** must be running with a network named `traefik_proxy`
2. **Mailcow** must be installed and accessible
3. **S3 bucket** created and accessible (automatically created if using the main Terraform deployment)
4. **Domain** configured with DNS pointing to your server

## Automated Deployment (Recommended)

This repository is automatically used when deploying via the main infrastructure:

```bash
# Clone the main infrastructure repository
git clone https://github.com/kkiisler/etky-mailcow.git
cd etky-mailcow

# Deploy using Terraform and Ansible
cd terraform
terraform apply

# The Ansible playbook will automatically:
# - Clone this GitOps repository
# - Configure Nextcloud using the docker-compose.yml
# - Set up monitoring and backups
```

## Manual Deployment

If you need to deploy manually or customize the configuration:

### 1. Clone this repository

```bash
git clone https://github.com/kkiisler/etky-mailcow-gitops.git
cd etky-mailcow-gitops
```

### 2. Configure environment

Create a `.env` file with your configuration:

```bash
cat > .env << 'EOF'
# Domain Configuration
DOMAIN_NAME=cloud.example.com
TRAEFIK_NETWORK=traefik_proxy

# Nextcloud Version
NEXTCLOUD_VERSION=31

# Database Configuration
DB_USER=nextcloud
DB_PASSWORD=CHANGE_ME_SECURE_PASSWORD
DB_ROOT_PASSWORD=CHANGE_ME_ROOT_PASSWORD

# Redis Configuration
REDIS_PASSWORD=CHANGE_ME_REDIS_PASSWORD
REDIS_MAX_MEMORY=512mb

# Nextcloud Admin
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=CHANGE_ME_ADMIN_PASSWORD

# S3 Object Storage (Pilvio)
S3_ENDPOINT=s3.pilw.io
S3_BUCKET=your-nextcloud-bucket
S3_ACCESS_KEY=YOUR_S3_ACCESS_KEY
S3_SECRET_KEY=YOUR_S3_SECRET_KEY
S3_REGION=eu-west-1

# SMTP Configuration (Mailcow Integration)
SMTP_HOST=mail.example.com
SMTP_SECURE=tls
SMTP_PORT=587
SMTP_NAME=nextcloud@example.com
SMTP_PASSWORD=CHANGE_ME_SMTP_PASSWORD
MAIL_FROM_ADDRESS=noreply
MAIL_DOMAIN=example.com
EOF
```

### 3. Create Mailcow SMTP user

Before starting Nextcloud, create a mailbox in Mailcow:

1. Log into Mailcow admin panel at `https://mail.example.com`
2. Go to Configuration → Mail Setup → Mailboxes → Add mailbox
3. Create mailbox: `nextcloud@example.com`
4. Use the password in your `.env` file as `SMTP_PASSWORD`

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

### Service Control (Automated Deployment)

If deployed via Ansible, use the management scripts:

```bash
# Service management
nextcloud-service.sh start|stop|restart|status|logs [service]|check-networks

# Run OCC commands
nextcloud-service.sh occ [command]

# Maintenance tasks
nextcloud-maintenance.sh
```

### Service Control (Manual Deployment)

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
# If deployed via Ansible
check-monitoring.sh

# Manual check
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

### Configuring Email with Resend

If using Resend for outbound emails via Mailcow:
1. Configure Mailcow to use Resend as a relay host
2. Nextcloud will automatically use Mailcow's SMTP, which routes through Resend
3. This provides better deliverability for transactional emails

## Backup and Restore

### Automated Backup System (via Ansible)

If deployed through the main infrastructure:

```bash
# Manual backup
unified-backup.sh

# Check backup status
backup-status.sh

# Monitor backup health
backup-monitor.sh

# List available backups
unified-restore.sh list

# Restore Nextcloud
unified-restore.sh nextcloud <timestamp>

# Restore both Mailcow and Nextcloud
unified-restore.sh both <timestamp>
```

Backups include:
- Database dumps (MariaDB)
- Configuration files
- Data is already in S3 (primary storage)
- 7-day retention policy by default

### Manual Backup

For manual deployments:
- Database: `docker compose exec db mysqldump -u root -p$DB_ROOT_PASSWORD nextcloud > backup.sql`
- Config: Back up the `/var/www/html/config` directory
- Data: Already in S3 if using object storage

## Monitoring

### Automated Monitoring (via Ansible)

The infrastructure includes:
- Python-based service monitoring
- Slack webhook notifications for alerts
- Health checks every 5 minutes
- Automatic alert on service failure

### Manual Monitoring

Check service health:
```bash
docker compose ps
docker compose exec app curl -f http://localhost/status.php
```

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

2. Check Mailcow mailbox exists:
   ```bash
   # Login to Mailcow and verify nextcloud@example.com exists
   ```

3. Test email:
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

3. Test S3 connectivity:
   ```bash
   # Install s3cmd or aws-cli and test bucket access
   aws s3 ls s3://your-nextcloud-bucket --endpoint-url https://s3.pilw.io
   ```

### Permission Issues

The container includes a fix-permissions script that runs on startup. If you still have issues:

```bash
docker compose exec app chown -R www-data:www-data /var/www/html/data
docker compose exec app chown -R www-data:www-data /var/www/html/config
```

## Updates

To update Nextcloud:

1. Update the version in `.env`:
   ```bash
   NEXTCLOUD_VERSION=31  # or newer stable version
   ```

2. Pull new images:
   ```bash
   docker compose pull
   ```

3. Stop services:
   ```bash
   docker compose down
   ```

4. Start services:
   ```bash
   docker compose up -d
   ```

5. Run post-update tasks:
   ```bash
   docker compose exec -u www-data app php occ upgrade
   docker compose exec -u www-data app php occ db:add-missing-indices
   docker compose exec -u www-data app php occ db:add-missing-columns
   ```

## Security Considerations

- All passwords should be strong and unique (minimum 16 characters)
- SSL/TLS is handled by Traefik automatically via Let's Encrypt
- Redis is password-protected
- Database is only accessible within the internal network
- Regular updates should be applied monthly
- Enable 2FA for admin accounts
- Use app passwords for external applications
- Configure brute force protection
- Review logs regularly for suspicious activity

## File Structure

```
.
├── docker-compose.yml           # Main composition file
├── docker-compose.override.yml  # Local overrides (optional)
├── .env                         # Environment variables (create from example)
├── scripts/
│   ├── fix-permissions.sh      # Permission fix script (runs on startup)
│   ├── health-check-api.sh     # Health check script
│   └── post-install.sh         # Post-installation setup
├── Makefile                     # Helper commands
└── README.md                    # This file
```

## Related Repositories

- **Main Infrastructure**: [etky-mailcow](https://github.com/kkiisler/etky-mailcow) - Complete IaC solution with Terraform and Ansible
- **Documentation**: See the main repository's `/docs` folder for detailed configuration guides

## Support

For issues related to:
- **This GitOps configuration**: Open an issue in this repository
- **Infrastructure/Ansible**: Open an issue in [etky-mailcow](https://github.com/kkiisler/etky-mailcow)
- **Nextcloud**: See [Nextcloud documentation](https://docs.nextcloud.com)
- **Docker/Compose issues**: Check container logs first
- **S3/Storage**: Verify credentials and bucket permissions

## License

This configuration is provided as-is for use with the etky-mailcow infrastructure deployment.