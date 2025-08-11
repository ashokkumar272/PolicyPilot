#!/bin/bash

# Check deployment status and display information
# Usage: ./check-deployment.sh

echo "🔍 PolicyPilot Deployment Status"
echo "================================"

RESOURCE_GROUP="PolicyPilot-RG"

# Check if resource group exists
if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    echo "❌ Resource group '$RESOURCE_GROUP' not found"
    echo "   Run ./setup-azure.sh to create Azure resources"
    exit 1
fi

echo "✅ Resource group: $RESOURCE_GROUP"

# Check resources
echo ""
echo "📦 Azure Resources:"
echo "-------------------"

# Database
DB_STATUS=$(az postgres flexible-server show \
    --resource-group "$RESOURCE_GROUP" \
    --name "policypilot-db" \
    --query "state" -o tsv 2>/dev/null || echo "Not found")
echo "🗄️  Database: $DB_STATUS"

# Storage
STORAGE_COUNT=$(az storage account list \
    --resource-group "$RESOURCE_GROUP" \
    --query "length(@)" -o tsv 2>/dev/null || echo "0")
echo "💾 Storage accounts: $STORAGE_COUNT"

# Container registry
REGISTRY_COUNT=$(az acr list \
    --resource-group "$RESOURCE_GROUP" \
    --query "length(@)" -o tsv 2>/dev/null || echo "0")
echo "🐳 Container registries: $REGISTRY_COUNT"

# Container apps
CONTAINERAPP_COUNT=$(az containerapp list \
    --resource-group "$RESOURCE_GROUP" \
    --query "length(@)" -o tsv 2>/dev/null || echo "0")
echo "📦 Container apps: $CONTAINERAPP_COUNT"

# Static web apps
STATICAPP_COUNT=$(az staticwebapp list \
    --resource-group "$RESOURCE_GROUP" \
    --query "length(@)" -o tsv 2>/dev/null || echo "0")
echo "🌐 Static web apps: $STATICAPP_COUNT"

# Check backend deployment
echo ""
echo "🚀 Application Status:"
echo "----------------------"

BACKEND_URL=""
if az containerapp show --name "policypilot-backend" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    BACKEND_URL=$(az containerapp show \
        --name "policypilot-backend" \
        --resource-group "$RESOURCE_GROUP" \
        --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null)
    
    if [ ! -z "$BACKEND_URL" ]; then
        echo "✅ Backend: https://$BACKEND_URL"
        
        # Test backend health
        if curl -s "https://$BACKEND_URL/health" > /dev/null; then
            echo "✅ Backend health check: PASSED"
        else
            echo "❌ Backend health check: FAILED"
        fi
    else
        echo "⚠️  Backend: Deployed but no URL found"
    fi
else
    echo "❌ Backend: Not deployed"
fi

# Check frontend deployment
FRONTEND_URL=""
if az staticwebapp list --resource-group "$RESOURCE_GROUP" --query "[0].defaultHostname" -o tsv &> /dev/null; then
    FRONTEND_URL=$(az staticwebapp list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[0].defaultHostname" -o tsv 2>/dev/null)
    
    if [ ! -z "$FRONTEND_URL" ] && [ "$FRONTEND_URL" != "null" ]; then
        echo "✅ Frontend: https://$FRONTEND_URL"
    else
        echo "⚠️  Frontend: Deployed but no URL found"
    fi
else
    echo "❌ Frontend: Not deployed"
fi

# Display costs (estimated)
echo ""
echo "💰 Estimated Monthly Costs (USD):"
echo "--------------------------------"
echo "📊 PostgreSQL Flexible Server (B1ms): ~$15-20"
echo "💾 Storage Account (Standard LRS): ~$1-5"
echo "🐳 Container Registry (Basic): ~$5"
echo "📦 Container Apps: ~$10-30 (depending on usage)"
echo "🌐 Static Web Apps: Free tier available"
echo "🤖 Azure OpenAI: Pay-per-use (varies by usage)"
echo ""
echo "💡 Total estimated: $31-60/month (excluding OpenAI usage)"

# Show URLs for easy access
if [ ! -z "$BACKEND_URL" ] || [ ! -z "$FRONTEND_URL" ]; then
    echo ""
    echo "🔗 Quick Access URLs:"
    echo "--------------------"
    
    if [ ! -z "$BACKEND_URL" ]; then
        echo "Backend API: https://$BACKEND_URL"
        echo "API Docs: https://$BACKEND_URL/docs"
    fi
    
    if [ ! -z "$FRONTEND_URL" ] && [ "$FRONTEND_URL" != "null" ]; then
        echo "Frontend App: https://$FRONTEND_URL"
    fi
fi

echo ""
echo "📚 For detailed logs and troubleshooting:"
echo "az containerapp logs show --name policypilot-backend --resource-group $RESOURCE_GROUP"
