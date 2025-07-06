#!/bin/bash

# DevDham Monitoring Deployment Script
# Usage: ./deploy.sh [environment]
# Environments: development, staging, production

set -e

# Configuration
PROJECT_ID="devdham-production-16"
REGION="asia-south1"
SERVICE_NAME="grafana"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if gcloud is installed and authenticated
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        log_error "No active gcloud authentication found. Please run 'gcloud auth login'"
        exit 1
    fi
    
    # Check if correct project is set
    current_project=$(gcloud config get-value project 2>/dev/null)
    if [ "$current_project" != "$PROJECT_ID" ]; then
        log_warning "Current project is '$current_project', switching to '$PROJECT_ID'"
        gcloud config set project $PROJECT_ID
    fi
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Build Docker image
build_image() {
    log_info "Building Grafana Docker image..."
    
    cd "$(dirname "$0")/.."
    
    # Generate build tag
    GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    IMAGE_TAG="$TIMESTAMP-$GIT_SHA"
    
    # Build the image
    docker build \
        -t "gcr.io/$PROJECT_ID/$SERVICE_NAME:$IMAGE_TAG" \
        -t "gcr.io/$PROJECT_ID/$SERVICE_NAME:latest" \
        ./grafana/
    
    if [ $? -eq 0 ]; then
        log_success "Docker image built successfully"
        echo "IMAGE_TAG=$IMAGE_TAG" > .build_info
    else
        log_error "Docker build failed"
        exit 1
    fi
}

# Push image to Container Registry
push_image() {
    log_info "Pushing image to Container Registry..."
    
    # Configure Docker for GCR
    gcloud auth configure-docker --quiet
    
    # Read image tag from build info
    source .build_info
    
    # Push images
    docker push "gcr.io/$PROJECT_ID/$SERVICE_NAME:$IMAGE_TAG"
    docker push "gcr.io/$PROJECT_ID/$SERVICE_NAME:latest"
    
    if [ $? -eq 0 ]; then
        log_success "Image pushed successfully"
    else
        log_error "Image push failed"
        exit 1
    fi
}

# Deploy to Cloud Run
deploy_to_cloud_run() {
    log_info "Deploying to Cloud Run..."
    
    # Read image tag from build info
    source .build_info
    
    # Set environment-specific configurations
    case $ENVIRONMENT in
        "development")
            MIN_INSTANCES=0
            MAX_INSTANCES=2
            MEMORY="512Mi"
            CPU="0.5"
            CONCURRENCY=50
            ;;
        "staging")
            MIN_INSTANCES=0
            MAX_INSTANCES=3
            MEMORY="1Gi"
            CPU="1"
            CONCURRENCY=80
            ;;
        "production")
            MIN_INSTANCES=0
            MAX_INSTANCES=5
            MEMORY="1Gi"
            CPU="1"
            CONCURRENCY=80
            ;;
        *)
            log_error "Unknown environment: $ENVIRONMENT"
            exit 1
            ;;
    esac
    
    # Deploy to Cloud Run
    gcloud run deploy $SERVICE_NAME \
        --image="gcr.io/$PROJECT_ID/$SERVICE_NAME:$IMAGE_TAG" \
        --region=$REGION \
        --platform=managed \
        --service-account="grafana-cloud-run@$PROJECT_ID.iam.gserviceaccount.com" \
        --add-cloudsql-instances="$PROJECT_ID:$REGION:grafana-db" \
        --memory=$MEMORY \
        --cpu=$CPU \
        --min-instances=$MIN_INSTANCES \
        --max-instances=$MAX_INSTANCES \
        --port=3000 \
        --allow-unauthenticated \
        --timeout=300 \
        --concurrency=$CONCURRENCY \
        --set-env-vars="NODE_ENV=$ENVIRONMENT" \
        --execution-environment=gen2 \
        --cpu-throttling \
        --no-traffic
    
    if [ $? -eq 0 ]; then
        log_success "Deployment successful"
    else
        log_error "Deployment failed"
        exit 1
    fi
}

# Health check
health_check() {
    log_info "Performing health check..."
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
        --region=$REGION \
        --format="value(status.url)")
    
    if [ -z "$SERVICE_URL" ]; then
        log_error "Could not get service URL"
        exit 1
    fi
    
    # Wait for service to be ready
    log_info "Waiting for service to be ready..."
    for i in {1..30}; do
        if curl -f -s "$SERVICE_URL/api/health" > /dev/null; then
            log_success "Health check passed"
            log_success "Service is available at: $SERVICE_URL"
            return 0
        fi
        sleep 10
    done
    
    log_error "Health check failed after 5 minutes"
    exit 1
}

# Update traffic
update_traffic() {
    log_info "Updating traffic to new revision..."
    
    gcloud run services update-traffic $SERVICE_NAME \
        --to-latest \
        --region=$REGION
    
    if [ $? -eq 0 ]; then
        log_success "Traffic updated successfully"
    else
        log_error "Traffic update failed"
        exit 1
    fi
}

# Cleanup
cleanup() {
    log_info "Cleaning up build artifacts..."
    rm -f .build_info
}

# Main deployment function
main() {
    # Parse arguments
    ENVIRONMENT=${1:-production}
    
    log_info "Starting deployment to $ENVIRONMENT environment..."
    log_info "Project: $PROJECT_ID"
    log_info "Region: $REGION"
    log_info "Service: $SERVICE_NAME"
    
    # Run deployment steps
    check_prerequisites
    build_image
    push_image
    deploy_to_cloud_run
    health_check
    update_traffic
    cleanup
    
    log_success "Deployment completed successfully!"
    log_info "You can access Grafana at the service URL provided above"
}

# Error handling
trap 'log_error "Deployment failed!"; cleanup; exit 1' ERR

# Run main function
main "$@"