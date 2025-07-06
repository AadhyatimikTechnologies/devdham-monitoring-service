# DevDham Monitoring Service

Comprehensive monitoring and observability platform for all DevDham microservices using Grafana on Google Cloud Run. This service provides real-time dashboards, alerting, and performance monitoring for the entire DevDham ecosystem.

## 🚀 Features

- **Production-Only Deployment**: Optimized for production environment monitoring
- **Real-time Dashboards**: Live monitoring for all 13+ microservices
- **Cost-Efficient**: Serverless Grafana (~$60/month vs $210 self-hosted)
- **Auto-scaling**: Scales to zero when not in use
- **Managed Prometheus**: Google Cloud's managed Prometheus integration
- **Smart Alerting**: Multi-channel notifications (Slack, email, PagerDuty)
- **Cloud SQL Integration**: Persistent configuration and data storage

## 📊 Monitoring Coverage

### Microservices Monitored
- **Event Microservice**: Event processing, package management
- **Order Microservice**: Order lifecycle, payment processing
- **User Microservice**: Authentication, user management
- **Content Microservice**: CMS and content delivery
- **LiveConnect Microservice**: Live streaming and AWS IVS
- **Scheduler Microservice**: Background jobs and Cloud Tasks
- **All Other Services**: Complete coverage of the microservices architecture

### Metrics Categories

#### Application Metrics
- HTTP request rate, latency, error rate
- Database query performance
- Redis cache hit/miss rates
- Cloud Tasks queue depth and processing time

#### Infrastructure Metrics
- Cloud Run container metrics (CPU, memory, instances)
- Cloud SQL performance and connections
- Redis operation latency
- Network throughput

#### Business Metrics
- Event creation and registration rates
- Order conversion funnel
- Revenue tracking
- Geographic user distribution

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Microservices │───▶│ Managed Prometheus│───▶│ Grafana        │
│   (event, user, │    │                  │    │ (Cloud Run)    │
│    order, etc.) │    │                  │    │                │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                                               │
         │              ┌──────────────────┐            │
         └─────────────▶│ Cloud Monitoring │◀───────────┘
                        │                  │
                        └──────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Google Cloud SDK installed and configured
- Docker installed
- Access to `devdham-production-16` project

### Local Development
```bash
# Clone and navigate
cd devdham-monitoring-service/

# Build Grafana container
npm run docker:build

# Run locally (requires Cloud SQL connection)
npm run docker:local

# Access Grafana
open http://localhost:3000
```

### Production Deployment
```bash
# Deploy to production (automatic via GitHub Actions)
git push origin main

# Manual deployment
npm run deploy
```

## 🌐 Access URLs

### Production Environment
- **Grafana Dashboard**: `https://grafana-devdham.run.app`
- **Health Check**: `https://grafana-devdham.run.app/api/health`
- **Login**: `https://grafana-devdham.run.app/login`

**Note**: This service only deploys to production. No development environment is needed for monitoring infrastructure.

## 📁 Project Structure

```
devdham-monitoring-service/
├── grafana/
│   ├── Dockerfile               # Grafana container configuration
│   ├── grafana.ini             # Grafana server configuration
│   ├── provisioning/           # Auto-provisioning configs
│   │   ├── dashboards/         # Dashboard configurations
│   │   ├── datasources/        # Data source configurations
│   │   └── notifiers/          # Alert notification configs
│   └── start.sh                # Container startup script
├── dashboards/                 # Grafana dashboard JSON files
├── alerts/
│   └── microservices.yml      # Alert rule definitions
├── scripts/
│   └── deploy.sh               # Deployment automation
├── .github/workflows/
│   └── deploy.yml              # CI/CD pipeline (main branch only)
├── docker-compose.yml          # Local development setup
├── cloudbuild.yaml             # Google Cloud Build configuration
├── prometheus-config.yaml     # Prometheus configuration
└── package.json                # Service metadata
```

## 📋 Dashboards

### 1. Platform Overview
**File**: `dashboards/platform-overview.json`
- High-level health across all microservices
- Error budget tracking
- Key business metrics

### 2. Event Microservice
**File**: `dashboards/event-microservice.json`
- Event processing performance
- Package purchase analytics
- Cloud Tasks monitoring

### 3. Order Microservice
**File**: `dashboards/order-microservice.json`
- Order lifecycle tracking
- Payment processing metrics
- Fulfillment performance

### 4. Infrastructure Health
**File**: `dashboards/infrastructure.json`
- Cloud Run scaling and performance
- Database connection pooling
- Redis cluster health

### 5. Error Analysis
**File**: `dashboards/error-analysis.json`
- Error rate trends by service
- Failed request analysis
- Alert correlation

## 🚨 Alerting Strategy

### Critical Alerts (PagerDuty)
- Service unavailable (>5min)
- High error rate (>5% for 5min)
- Database connection failures
- Payment processing failures

### Warning Alerts (Slack)
- Elevated error rate (>1% for 10min)
- High response time (>2s 95th percentile)
- Queue backlog (>100 tasks)
- Memory usage (>80% for 15min)

### Informational (Email)
- Daily summary reports
- Deployment notifications
- Weekly performance trends

## ⚙️ Configuration

### Environment Variables
```bash
# Grafana Configuration
GF_DATABASE_PASSWORD=your_db_password
GF_SECURITY_ADMIN_PASSWORD=your_admin_password
GF_SECURITY_SECRET_KEY=your_secret_key

# Google OAuth (optional)
GF_AUTH_GOOGLE_CLIENT_ID=your_client_id
GF_AUTH_GOOGLE_CLIENT_SECRET=your_client_secret

# Slack Integration
SLACK_WEBHOOK_URL=your_slack_webhook
SLACK_CHANNEL=#alerts
```

### Cloud Infrastructure
- **Cloud SQL**: `grafana-db` (PostgreSQL 14, db-f1-micro)
- **Service Account**: `grafana-cloud-run@devdham-production-16.iam.gserviceaccount.com`
- **Cloud Run Service**: `grafana` (asia-south1)

## 💰 Cost Analysis

### Monthly Costs (~$60)
- **Managed Prometheus**: ~$35 (metric ingestion)
- **Cloud Monitoring**: ~$10 (basic metrics)
- **Grafana Cloud Run**: ~$5 (minimal usage, scales to zero)
- **Cloud SQL**: ~$8 (db-f1-micro)
- **Network**: ~$2 (egress)

### Cost Optimization Features
- Grafana auto-scales to zero when unused
- Efficient metric sampling and filtering
- Optimized dashboard queries
- Smart alerting to reduce noise

## 🔐 Security

### Access Control
- Google OAuth integration for devdham.com domain
- IAM-based service account permissions
- Private Cloud SQL connections
- HTTPS-only communication

### Data Protection
- Encryption at rest and in transit
- Automated Cloud SQL backups
- Audit logging enabled
- Network isolation via VPC

## 🚀 Deployment

### Automatic Deployment (Recommended)
Push to `main` branch triggers automatic deployment:

```bash
git push origin main
```

### Manual Deployment
```bash
# Build and deploy
npm run deploy

# Check deployment status
npm run health:check
```

### Local Development
```bash
# Start local Grafana
npm run docker:local

# View logs
npm run docker:logs

# Stop services
npm run docker:stop
```

## 🧪 Testing

### Health Checks
```bash
# Production health check
curl https://grafana-devdham.run.app/api/health

# Local health check
curl http://localhost:3000/api/health
```

### Endpoint Testing
```bash
# Test all endpoints
npm run test:endpoints

# Validate dashboards
npm run validate:dashboards
```

## 📊 Monitoring the Monitor

### Service Metrics
- Grafana container health and performance
- Database connection status
- Query response times
- Dashboard load times

### Alerting on Monitoring
- Grafana service unavailable
- Database connection failures
- High query latency
- Dashboard errors

## 🛠️ Maintenance

### Daily Tasks
- [ ] Monitor dashboard health
- [ ] Check alert notifications
- [ ] Verify metric collection

### Weekly Tasks
- [ ] Review performance trends
- [ ] Update alerting thresholds
- [ ] Validate cost usage

### Monthly Tasks
- [ ] Dashboard optimization
- [ ] Security review
- [ ] Backup validation
- [ ] Documentation updates

## 🔧 Troubleshooting

### Common Issues

#### Grafana Won't Start
```bash
# Check Cloud SQL connectivity
gcloud sql instances describe grafana-db

# Verify service account permissions
gcloud projects get-iam-policy devdham-production-16
```

#### Missing Metrics
```bash
# Test Prometheus endpoints
curl https://your-microservice.com/metrics

# Check Managed Prometheus status
gcloud monitoring metrics list --filter="prometheus"
```

#### High Costs
```bash
# Review metric ingestion
gcloud logging read "resource.type=prometheus_target"

# Check dashboard query efficiency
# Use Grafana query inspector
```

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch for dashboard updates
3. **Test** changes locally using `npm run docker:local`
4. **Validate** dashboard JSON using `npm run validate:dashboards`
5. **Submit** Pull Request to `main` branch

### Adding New Dashboards
1. Create dashboard in Grafana UI
2. Export JSON to `dashboards/`
3. Add to provisioning config
4. Test and commit changes

### Adding New Microservices
1. Integrate Prometheus metrics in microservice
2. Add data source configuration
3. Create service-specific dashboard
4. Configure relevant alerts

## 📞 Support

### Team Contacts
- **DevOps/SRE**: monitoring@devdham.com
- **Platform Team**: platform@devdham.com
- **On-call**: alerts@devdham.com

### Resources
- [Grafana Documentation](https://grafana.com/docs/)
- [Google Cloud Monitoring](https://cloud.google.com/monitoring/docs)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Last Updated: July 6, 2025*  
**Built with ❤️ by the DevDham Platform Team**# Trigger deployment
