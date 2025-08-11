#!/bin/bash

# Azure Deployment Setup Script for PolicyPilot
# This script automates the Azure resource creation process

set -e  # Exit on any error

echo "🚀 PolicyPilot Azure Deployment Setup"
echo "====================================="

# Configuration variables
RESOURCE_GROUP="PolicyPilot-RG"
LOCATION="eastus2"
DB_NAME="policypilot-db"
DB_ADMIN="policypilotadmin"
STORAGE_ACCOUNT="policypilotfiles$(date +%s)"  # Add timestamp to ensure uniqueness
CONTAINER_REGISTRY="policypilotregistry$(date +%s)"
CONTAINER_ENV="PolicyPilot-Environment"
BACKEND_APP="policypilot-backend"
FRONTEND_APP="PolicyPilot-Frontend"

# Function to check if Azure CLI is installed
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        echo "❌ Azure CLI is not installed. Please install it first:"
        echo "   macOS: brew install azure-cli"
        echo "   Windows: Download from https://aka.ms/installazurecliwindows"
        echo "   Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
        exit 1
    fi
    echo "✅ Azure CLI found"
}

# Function to check if user is logged in
check_azure_login() {
    if ! az account show &> /dev/null; then
        echo "❌ You're not logged into Azure. Please run:"
        echo "   az login"
        exit 1
    fi
    echo "✅ Azure login verified"
}

# Function to generate secure password
generate_password() {
    echo "$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)!"
}

# Function to create resource group
create_resource_group() {
    echo "📦 Creating resource group: $RESOURCE_GROUP"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
    echo "✅ Resource group created"
}

# Function to create PostgreSQL database
create_database() {
    echo "🗄️ Creating PostgreSQL database: $DB_NAME"
    DB_PASSWORD=$(generate_password)
    echo "Database password: $DB_PASSWORD" > .azure-credentials.txt
    
    az postgres flexible-server create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DB_NAME" \
        --location "$LOCATION" \
        --admin-user "$DB_ADMIN" \
        --admin-password "$DB_PASSWORD" \
        --sku-name Standard_B1ms \
        --tier Burstable \
        --storage-size 32 \
        --version 14 \
        --output none
    
    # Configure firewall
    az postgres flexible-server firewall-rule create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DB_NAME" \
        --rule-name AllowAzureServices \
        --start-ip-address 0.0.0.0 \
        --end-ip-address 0.0.0.0 \
        --output none
    
    echo "✅ PostgreSQL database created"
    echo "Database URL: postgresql://$DB_ADMIN:$DB_PASSWORD@$DB_NAME.postgres.database.azure.com:5432/postgres?sslmode=require" >> .azure-credentials.txt
}

# Function to create storage account
create_storage() {
    echo "💾 Creating storage account: $STORAGE_ACCOUNT"
    az storage account create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$STORAGE_ACCOUNT" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --output none
    
    # Create blob container
    az storage container create \
        --name documents \
        --account-name "$STORAGE_ACCOUNT" \
        --public-access off \
        --output none
    
    # Get connection string
    STORAGE_CONNECTION=$(az storage account show-connection-string \
        --resource-group "$RESOURCE_GROUP" \
        --name "$STORAGE_ACCOUNT" \
        --query connectionString -o tsv)
    
    echo "Storage connection string: $STORAGE_CONNECTION" >> .azure-credentials.txt
    echo "✅ Storage account created"
}

# Function to create container registry
create_container_registry() {
    echo "🐳 Creating container registry: $CONTAINER_REGISTRY"
    az acr create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$CONTAINER_REGISTRY" \
        --sku Basic \
        --output none
    
    # Enable admin access
    az acr update \
        --name "$CONTAINER_REGISTRY" \
        --admin-enabled true \
        --output none
    
    # Get credentials
    REGISTRY_USERNAME=$(az acr credential show --name "$CONTAINER_REGISTRY" --query username -o tsv)
    REGISTRY_PASSWORD=$(az acr credential show --name "$CONTAINER_REGISTRY" --query passwords[0].value -o tsv)
    
    echo "Registry username: $REGISTRY_USERNAME" >> .azure-credentials.txt
    echo "Registry password: $REGISTRY_PASSWORD" >> .azure-credentials.txt
    echo "✅ Container registry created"
}

# Function to create container apps environment
create_container_environment() {
    echo "🌐 Creating Container Apps environment: $CONTAINER_ENV"
    az containerapp env create \
        --name "$CONTAINER_ENV" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --output none
    echo "✅ Container Apps environment created"
}

# Function to create static web app
create_static_web_app() {
    echo "🌐 Creating Static Web App: $FRONTEND_APP"
    
    # Check if GitHub repository exists
    if ! git remote get-url origin &> /dev/null; then
        echo "⚠️ No Git remote origin found. Skipping Static Web App creation."
        echo "   Please create the Static Web App manually or push this repository to GitHub first."
        return
    fi
    
    REPO_URL=$(git remote get-url origin)
    az staticwebapp create \
        --name "$FRONTEND_APP" \
        --resource-group "$RESOURCE_GROUP" \
        --source "$REPO_URL" \
        --branch main \
        --app-location "/frontend" \
        --build-location "build" \
        --location "$LOCATION" \
        --output none
    
    echo "✅ Static Web App created"
}

# Function to setup database schema
setup_database_schema() {
    echo "📋 Setting up database schema..."
    
    # Read database credentials
    DB_PASSWORD=$(grep "Database password:" .azure-credentials.txt | cut -d' ' -f3)
    
    # Create SQL schema file
    cat > schema.sql << 'EOF'
-- PolicyPilot Database Schema
CREATE TABLE IF NOT EXISTS documents (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    content_type VARCHAR(100),
    file_size BIGINT,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE,
    azure_blob_url TEXT
);

CREATE TABLE IF NOT EXISTS document_chunks (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,
    text_content TEXT NOT NULL,
    metadata JSONB,
    embedding_vector FLOAT8[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS query_logs (
    id SERIAL PRIMARY KEY,
    query_text TEXT NOT NULL,
    response_data JSONB,
    processing_time FLOAT,
    user_session VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_chunks_document_id ON document_chunks(document_id);
CREATE INDEX IF NOT EXISTS idx_query_logs_created_at ON query_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_documents_processed ON documents(processed);
CREATE INDEX IF NOT EXISTS idx_chunks_created_at ON document_chunks(created_at);
EOF

    # Execute schema
    az postgres flexible-server execute \
        --name "$DB_NAME" \
        --admin-user "$DB_ADMIN" \
        --admin-password "$DB_PASSWORD" \
        --database-name postgres \
        --file-path schema.sql \
        --output none
    
    rm schema.sql
    echo "✅ Database schema created"
}

# Function to display summary
display_summary() {
    echo ""
    echo "🎉 Azure Resources Created Successfully!"
    echo "======================================"
    echo ""
    echo "📝 Important Information:"
    echo "- Resource Group: $RESOURCE_GROUP"
    echo "- Location: $LOCATION"
    echo "- Database: $DB_NAME"
    echo "- Storage: $STORAGE_ACCOUNT"
    echo "- Registry: $CONTAINER_REGISTRY"
    echo ""
    echo "🔐 Credentials saved to: .azure-credentials.txt"
    echo "⚠️  IMPORTANT: Keep this file secure and don't commit it to Git!"
    echo ""
    echo "Next Steps:"
    echo "1. Update backend/.env.production with the credentials from .azure-credentials.txt"
    echo "2. Build and push Docker images:"
    echo "   cd backend && docker build -t $CONTAINER_REGISTRY.azurecr.io/policypilot-backend:latest ."
    echo "   docker push $CONTAINER_REGISTRY.azurecr.io/policypilot-backend:latest"
    echo "3. Create the backend container app"
    echo "4. Configure GitHub Actions with the credentials"
    echo ""
    echo "📚 See README.md for detailed deployment instructions"
}

# Main execution
main() {
    echo "Starting Azure resource setup..."
    echo ""
    
    check_azure_cli
    check_azure_login
    
    # Prompt for confirmation
    echo "This script will create the following Azure resources:"
    echo "- Resource Group: $RESOURCE_GROUP"
    echo "- PostgreSQL Database: $DB_NAME"
    echo "- Storage Account: $STORAGE_ACCOUNT"
    echo "- Container Registry: $CONTAINER_REGISTRY"
    echo "- Container Apps Environment: $CONTAINER_ENV"
    echo "- Static Web App: $FRONTEND_APP"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 1
    fi
    
    # Create resources
    create_resource_group
    create_database
    create_storage
    create_container_registry
    create_container_environment
    create_static_web_app
    setup_database_schema
    
    display_summary
}

# Run main function
main "$@"
