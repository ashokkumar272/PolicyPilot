#!/bin/bash

# Deploy containers to Azure Container Apps
# Run this after setup-azure.sh completes

set -e

echo "🚀 Deploying PolicyPilot to Azure Container Apps"
echo "================================================"

# Read configuration from credentials file
if [ ! -f ".azure-credentials.txt" ]; then
    echo "❌ .azure-credentials.txt not found. Please run setup-azure.sh first."
    exit 1
fi

# Extract values from credentials file
REGISTRY_USERNAME=$(grep "Registry username:" .azure-credentials.txt | cut -d' ' -f3)
REGISTRY_PASSWORD=$(grep "Registry password:" .azure-credentials.txt | cut -d' ' -f3)
DB_URL=$(grep "Database URL:" .azure-credentials.txt | cut -d' ' -f3-)
STORAGE_CONNECTION=$(grep "Storage connection string:" .azure-credentials.txt | cut -d' ' -f4-)

# Find registry name (extract from username)
CONTAINER_REGISTRY="$REGISTRY_USERNAME"
RESOURCE_GROUP="PolicyPilot-RG"
CONTAINER_ENV="PolicyPilot-Environment"
BACKEND_APP="policypilot-backend"

# Check if required environment variables are set
if [ -z "$AZURE_OPENAI_API_KEY" ] || [ -z "$AZURE_OPENAI_ENDPOINT" ] || [ -z "$AZURE_OPENAI_DEPLOYMENT_NAME" ]; then
    echo "❌ Missing Azure OpenAI environment variables. Please set:"
    echo "   export AZURE_OPENAI_API_KEY='your-key'"
    echo "   export AZURE_OPENAI_ENDPOINT='your-endpoint'"
    echo "   export AZURE_OPENAI_DEPLOYMENT_NAME='your-deployment'"
    exit 1
fi

echo "✅ Environment variables verified"

# Login to container registry
echo "🔐 Logging into Azure Container Registry..."
az acr login --name "$CONTAINER_REGISTRY"

# Build and push backend image
echo "🐳 Building and pushing backend image..."
cd backend
docker build -t "$CONTAINER_REGISTRY.azurecr.io/policypilot-backend:latest" .
docker push "$CONTAINER_REGISTRY.azurecr.io/policypilot-backend:latest"
cd ..

# Build and push frontend image (optional, if using container for frontend too)
echo "🐳 Building and pushing frontend image..."
cd frontend
docker build -t "$CONTAINER_REGISTRY.azurecr.io/policypilot-frontend:latest" .
docker push "$CONTAINER_REGISTRY.azurecr.io/policypilot-frontend:latest"
cd ..

# Deploy backend container app
echo "🚀 Deploying backend container app..."
az containerapp create \
    --name "$BACKEND_APP" \
    --resource-group "$RESOURCE_GROUP" \
    --environment "$CONTAINER_ENV" \
    --image "$CONTAINER_REGISTRY.azurecr.io/policypilot-backend:latest" \
    --target-port 8000 \
    --ingress external \
    --registry-server "$CONTAINER_REGISTRY.azurecr.io" \
    --registry-username "$REGISTRY_USERNAME" \
    --registry-password "$REGISTRY_PASSWORD" \
    --env-vars \
        AZURE_OPENAI_API_KEY="$AZURE_OPENAI_API_KEY" \
        AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_ENDPOINT" \
        AZURE_OPENAI_DEPLOYMENT_NAME="$AZURE_OPENAI_DEPLOYMENT_NAME" \
        DATABASE_URL="$DB_URL" \
        AZURE_STORAGE_CONNECTION_STRING="$STORAGE_CONNECTION" \
        ENVIRONMENT=production \
        API_HOST=0.0.0.0 \
        API_PORT=8000

# Get backend URL
BACKEND_URL=$(az containerapp show \
    --name "$BACKEND_APP" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.configuration.ingress.fqdn" -o tsv)

echo ""
echo "🎉 Deployment Complete!"
echo "======================"
echo ""
echo "✅ Backend API: https://$BACKEND_URL"
echo "✅ API Documentation: https://$BACKEND_URL/docs"
echo ""
echo "Next steps:"
echo "1. Test your backend API at https://$BACKEND_URL/health"
echo "2. Configure your frontend to use the backend URL"
echo "3. Update CORS settings if needed"
echo ""
echo "Backend URL saved to: backend-url.txt"
echo "https://$BACKEND_URL" > backend-url.txt
