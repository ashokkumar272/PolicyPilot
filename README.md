# PolicyPilot 🛡️

> **LLM-Powered Insurance Policy Document Processing System**

PolicyPilot is an intelligent document processing system that helps analyze insurance policies using advanced AI and semantic search capabilities. Upload your insurance documents and get instant, context-aware answers to your policy questions.

![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green.svg)
![React](https://img.shields.io/badge/React-18+-blue.svg)
![TypeScript](https://img.shields.io/badge/TypeScript-4.9+-blue.svg)
![Azure](https://img.shields.io/badge/Azure-Ready-orange.svg)

## ✨ Features

- **🤖 AI-Powered Analysis**: Uses Azure OpenAI GPT-4 for intelligent policy interpretation
- **📄 Multi-Format Support**: Process PDF, DOCX, and TXT documents
- **🔍 Semantic Search**: Advanced vector search with neighboring chunk context (±1 range)
- **💬 Interactive Chat**: Modern React-based chat interface
- **📁 Document Management**: Drag & drop upload with document organization
- **🚀 Production Ready**: Docker containerization and Azure deployment
- **🔒 Secure**: Azure-integrated authentication and storage

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   React Frontend │────│   FastAPI Backend │────│  Azure OpenAI   │
│   (Port 3000)    │    │   (Port 8000)     │    │   GPT-4.1       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         │                        ▼                        │
         │              ┌──────────────────┐              │
         │              │   PostgreSQL     │              │
         └──────────────│   Database       │──────────────┘
                        └──────────────────┘
                                 │
                        ┌──────────────────┐
                        │  Azure Blob      │
                        │  Storage         │
                        └──────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Python 3.11+**
- **Node.js 18+**
- **Azure OpenAI API Key**
- **Azure Account** (for production deployment)

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/rajatsinghten/PolicyPilot.git
   cd PolicyPilot
   ```

2. **Set up Backend**
   ```bash
   cd backend
   
   # Create and activate virtual environment
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   
   # Install dependencies
   pip install -r requirements.txt
   
   # Configure environment variables
   cp .env.example .env
   # Edit .env with your Azure OpenAI credentials
   ```

3. **Set up Frontend**
   ```bash
   cd ../frontend
   
   # Install dependencies
   npm install
   ```

4. **Start Development Servers**
   ```bash
   # Terminal 1: Start Backend
   cd backend
   source venv/bin/activate
   python -m app.api
   
   # Terminal 2: Start Frontend
   cd frontend
   npm start
   ```

5. **Access the Application**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000
   - API Documentation: http://localhost:8000/docs

## 📋 Environment Configuration

### Backend Environment Variables (`.env`)

```env
# Azure OpenAI Configuration
AZURE_OPENAI_API_KEY=your-azure-openai-key
AZURE_OPENAI_ENDPOINT=https://your-endpoint.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT_NAME=your-deployment-name

# Application Configuration
API_HOST=0.0.0.0
API_PORT=8000
ENVIRONMENT=development

# Document Processing
MAX_DOCUMENT_SIZE=10485760
CHUNK_SIZE=500
CHUNK_OVERLAP=50
TOP_K_RESULTS=5
INCLUDE_NEIGHBORS=true
NEIGHBOR_RANGE=1

# CORS (for production, specify your frontend URL)
CORS_ORIGINS=http://localhost:3000
```

## 🔧 API Endpoints

### Document Management
- `POST /upload` - Upload and process documents
- `GET /documents` - List all processed documents
- `DELETE /documents/{document_name}` - Delete a document

### Query Processing
- `POST /process` - Process natural language queries with LLM reasoning
- `GET /search/{query}` - Simple semantic search without LLM

### System
- `GET /health` - Health check endpoint
- `GET /` - API information

### Example API Usage

```javascript
// Upload a document
const formData = new FormData();
formData.append('file', pdfFile);
const response = await fetch('http://localhost:8000/upload', {
  method: 'POST',
  body: formData
});

// Process a query
const queryResponse = await fetch('http://localhost:8000/process', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    query: "What is covered under accidental death?",
    top_k: 5,
    use_llm_reasoning: true,
    include_neighbors: true
  })
});
```

## 🐳 Docker Development

### Using Docker Compose

```bash
# Build and start all services
docker-compose up --build

# Access applications
# Frontend: http://localhost:80
# Backend: http://localhost:8000
```

### Individual Container Commands

```bash
# Backend only
cd backend
docker build -t policypilot-backend .
docker run -p 8000:8000 --env-file .env policypilot-backend

# Frontend only
cd frontend
docker build -t policypilot-frontend .
docker run -p 80:80 policypilot-frontend
```

## ☁️ Azure Deployment

### Automated Deployment (Recommended)

1. **Fork this repository** to your GitHub account

2. **Set up Azure resources** using Azure CLI:
   ```bash
   # Install Azure CLI
   brew install azure-cli  # macOS
   
   # Login to Azure
   az login
   
   # Run the deployment script
   ./deploy/setup-azure.sh
   ```

3. **Configure GitHub Secrets** in your repository:
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
   - `AZURE_TENANT_ID`
   - `AZURE_REGISTRY_USERNAME`
   - `AZURE_REGISTRY_PASSWORD`
   - `AZURE_STATIC_WEB_APPS_API_TOKEN`

4. **Push changes** to trigger automatic deployment:
   ```bash
   git add .
   git commit -m "Deploy to Azure"
   git push origin main
   ```

### Manual Deployment Steps

<details>
<summary>Click to expand detailed manual deployment steps</summary>

#### Phase 1: Prepare Azure Resources

```bash
# Create resource group
az group create --name PolicyPilot-RG --location eastus2

# Create PostgreSQL database
az postgres flexible-server create \
  --resource-group PolicyPilot-RG \
  --name policypilot-db \
  --location eastus2 \
  --admin-user policypilotadmin \
  --admin-password "YourSecurePassword123!" \
  --sku-name Standard_B1ms

# Create storage account
az storage account create \
  --resource-group PolicyPilot-RG \
  --name policypilotfiles \
  --location eastus2 \
  --sku Standard_LRS

# Create container registry
az acr create \
  --resource-group PolicyPilot-RG \
  --name policypilotregistry \
  --sku Basic
```

#### Phase 2: Deploy Backend

```bash
# Login to container registry
az acr login --name policypilotregistry

# Build and push backend image
cd backend
docker build -t policypilotregistry.azurecr.io/policypilot-backend:latest .
docker push policypilotregistry.azurecr.io/policypilot-backend:latest

# Create Container Apps environment
az containerapp env create \
  --name PolicyPilot-Environment \
  --resource-group PolicyPilot-RG \
  --location eastus2

# Deploy backend container
az containerapp create \
  --name policypilot-backend \
  --resource-group PolicyPilot-RG \
  --environment PolicyPilot-Environment \
  --image policypilotregistry.azurecr.io/policypilot-backend:latest \
  --target-port 8000 \
  --ingress external
```

#### Phase 3: Deploy Frontend

```bash
# Build frontend
cd frontend
npm run build

# Create Static Web App
az staticwebapp create \
  --name PolicyPilot-Frontend \
  --resource-group PolicyPilot-RG \
  --source https://github.com/rajatsinghten/PolicyPilot \
  --branch main \
  --app-location "/frontend" \
  --build-location "build"
```

#### Phase 4: Configure Database

```sql
-- Connect to PostgreSQL and create tables
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    content_type VARCHAR(100),
    file_size BIGINT,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE,
    azure_blob_url TEXT
);

CREATE TABLE document_chunks (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,
    text_content TEXT NOT NULL,
    metadata JSONB,
    embedding_vector FLOAT8[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE query_logs (
    id SERIAL PRIMARY KEY,
    query_text TEXT NOT NULL,
    response_data JSONB,
    processing_time FLOAT,
    user_session VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

</details>

## 🛠️ Development

### Project Structure

```
PolicyPilot/
├── backend/                    # FastAPI backend
│   ├── app/
│   │   ├── api.py             # Main API endpoints
│   │   ├── embedder.py        # Document embedding logic
│   │   ├── ingestion.py       # Document processing
│   │   ├── parser.py          # Query parsing
│   │   ├── reasoner.py        # LLM reasoning
│   │   └── retriever.py       # Semantic search
│   ├── data/
│   │   ├── documents/         # Uploaded documents
│   │   └── embeddings/        # FAISS index and embeddings
│   ├── config.py              # Configuration settings
│   ├── requirements.txt       # Python dependencies
│   └── Dockerfile             # Backend container config
├── frontend/                   # React frontend
│   ├── src/
│   │   ├── components/        # React components
│   │   ├── services/          # API services
│   │   └── types/            # TypeScript type definitions
│   ├── public/               # Static assets
│   ├── package.json          # Node.js dependencies
│   └── Dockerfile            # Frontend container config
├── .github/workflows/         # GitHub Actions CI/CD
├── docker-compose.yml         # Local development setup
└── README.md                 # This file
```

### Key Technologies

**Backend:**
- **FastAPI**: High-performance Python web framework
- **Sentence Transformers**: Text embedding generation
- **FAISS**: Vector similarity search
- **Azure OpenAI**: GPT-4.1 for intelligent reasoning
- **PyPDF2**: PDF document processing

**Frontend:**
- **React 18**: Modern UI framework
- **TypeScript**: Type-safe JavaScript
- **Axios**: HTTP client for API communication
- **CSS3**: Modern styling with Inter font

### Adding New Features

1. **Backend Changes**: Modify files in `backend/app/`
2. **Frontend Changes**: Update components in `frontend/src/components/`
3. **Configuration**: Update `backend/config.py` for new settings
4. **Database**: Add migrations in deployment scripts

## 📊 Monitoring & Logging

### Application Insights Integration

```python
# Backend logging configuration
from loguru import logger

logger.add(
    "logs/app.log",
    rotation="1 week",
    retention="1 month",
    level="INFO"
)
```

### Health Check Endpoints

- `GET /health` - Application health status
- `GET /` - Service information and component status

## 🔒 Security

### Environment Variables
- Never commit `.env` files to version control
- Use Azure Key Vault for production secrets
- Rotate API keys regularly

### CORS Configuration
```python
# Production CORS setup
CORS_ORIGINS = [
    "https://your-domain.com",
    "https://your-app.azurestaticapps.net"
]
```

### File Upload Security
- File type validation
- Size limits (10MB default)
- Virus scanning (recommended for production)

## 🧪 Testing

### Running Tests

```bash
# Backend tests
cd backend
python -m pytest tests/

# Frontend tests
cd frontend
npm test
```

### Test Coverage

```bash
# Generate coverage report
cd backend
python -m pytest --cov=app tests/
```

## � Troubleshooting

### Common Issues

**Backend not starting:**
```bash
# Check virtual environment activation
source venv/bin/activate
which python

# Verify dependencies
pip install -r requirements.txt

# Check environment variables
python -c "import os; print(os.getenv('AZURE_OPENAI_API_KEY'))"
```

**Frontend build errors:**
```bash
# Clear npm cache
npm cache clean --force

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

**Azure OpenAI connection issues:**
- Verify API key and endpoint in `.env`
- Check deployment name matches Azure configuration
- Ensure proper CORS settings

**Docker issues:**
```bash
# Rebuild containers
docker-compose down
docker-compose up --build --force-recreate
```

## 📈 Performance Optimization

### Backend Optimization
- Use Redis for caching (production)
- Implement connection pooling for database
- Optimize chunk size and overlap parameters

### Frontend Optimization
- Enable React production build: `npm run build`
- Implement lazy loading for components
- Use service workers for caching

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit your changes**: `git commit -m 'Add amazing feature'`
4. **Push to the branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Development Workflow

```bash
# Start development environment
./start-dev.sh

# Make changes and test
# Backend: http://localhost:8000
# Frontend: http://localhost:3000

# Run tests before committing
cd backend && python -m pytest
cd frontend && npm test

# Commit and push changes
git add .
git commit -m "Description of changes"
git push origin feature-branch
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/rajatsinghten/PolicyPilot/issues)
- **Discussions**: [GitHub Discussions](https://github.com/rajatsinghten/PolicyPilot/discussions)
- **Email**: rajatsinghten@example.com

## 🎯 Roadmap

- [ ] **Multi-language Support**: Process documents in multiple languages
- [ ] **Advanced Analytics**: Document insights and policy comparison
- [ ] **Mobile App**: React Native mobile application
- [ ] **Integration APIs**: Connect with insurance management systems
- [ ] **Machine Learning**: Custom model training for specific insurance domains
- [ ] **Audit Trail**: Complete logging and compliance features

## 👥 Team

- **Rajat Singh** - *Lead Developer* - [@rajatsinghten](https://github.com/rajatsinghten)

## 🙏 Acknowledgments

- **Azure OpenAI** for powerful language model capabilities
- **Hugging Face** for sentence transformer models
- **FastAPI** community for excellent documentation
- **React** team for modern frontend framework

---

**Built with ❤️ using Azure AI Services**

*PolicyPilot - Making insurance policies understandable through AI*
🧠 **Azure OpenAI Integration**: GPT-4 powered reasoning and analysis  
📄 **Multi-format Document Support**: PDF, DOCX, TXT processing  
🎨 **Beautiful Modern UI**: Glass morphism design with smooth animations  
⚡ **Real-time Chat Interface**: Interactive natural language queries  
📤 **Drag & Drop Upload**: Seamless document upload experience  
📚 **Document Management**: View, manage, and delete uploaded documents  
🛡️ **Insurance-Focused**: Specialized for policy analysis and claims processing  
🔗 **Context-Aware Retrieval**: Includes neighboring chunks for complete context  

## 🏗️ Architecture

```
PolicyPilot/
├── backend/                # FastAPI Backend
│   ├── app/
│   │   ├── api.py         # FastAPI endpoints
│   │   ├── ingestion.py   # Document processing & chunking
│   │   ├── embedder.py    # Text embeddings (Azure OpenAI/HuggingFace)
│   │   ├── parser.py      # Query parsing & understanding
│   │   ├── retriever.py   # Semantic search with FAISS
│   │   └── reasoner.py    # LLM reasoning & decision making
│   ├── data/
│   │   ├── documents/     # Upload documents here
│   │   └── embeddings/    # Vector storage (auto-generated)
│   ├── config.py          # System configuration
│   ├── main.py            # CLI interface
│   └── requirements.txt   # Python dependencies
├── frontend/               # React Frontend
│   ├── src/
│   │   ├── components/    # React components
│   │   ├── App.tsx        # Main App component
│   │   └── index.tsx      # Entry point
│   ├── public/            # Static assets
│   ├── package.json       # Node.js dependencies
│   └── tsconfig.json      # TypeScript config
├── start-dev.sh           # Development startup script
└── package.json           # Root package.json
```

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- Node.js 16+
- Azure OpenAI API key (optional, for enhanced reasoning)

### One-Command Setup (Recommended)
```bash
# Clone the repository
git clone https://github.com/yourusername/PolicyPilot.git
cd PolicyPilot

# Install all dependencies and start both services
npm run install
npm run dev
```

This will:
- Set up the Python virtual environment in `backend/`
- Install all Python dependencies
- Install all Node.js dependencies in `frontend/`
- Start both backend (port 8000) and frontend (port 3000)

### Manual Setup

#### Backend Setup
```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### Frontend Setup
```bash
cd frontend
npm install
```

#### Start Services
```bash
# Terminal 1 - Backend
cd backend
source venv/bin/activate
python -m uvicorn app.api:app --reload --host 0.0.0.0 --port 8000

# Terminal 2 - Frontend
cd frontend
npm start
```

## 🌐 Access the Application

After starting:
- **Frontend UI**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🔧 Configuration

### Environment Variables (.env)
Create a `.env` file in the `backend/` directory:

```env
# Azure OpenAI Configuration (for enhanced reasoning)
AZURE_OPENAI_API_KEY=your-azure-openai-api-key
AZURE_OPENAI_ENDPOINT=https://your-resource.cognitiveservices.azure.com/
AZURE_OPENAI_DEPLOYMENT_NAME=your-deployment-name

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000

# RAG Settings
CHUNK_SIZE=500
TOP_K_RESULTS=5
SIMILARITY_THRESHOLD=0.3
```

## 📡 API Endpoints

### Core Endpoints

#### 1. Health Check
```http
GET /health
```
Returns system status and component availability.

#### 2. Process Query (Main RAG Endpoint)
```http
POST /process
Content-Type: application/json

{
  "query": "What are the dental coverage benefits?",
  "use_llm_reasoning": true,
  "top_k": 5
}
```

**Response Format**:
```json
{
  "decision": "Insufficient Information",
  "confidence": 0.7,
  "reasoning": "The query does not specify the type of dental treatment...",
  "justification": {
    "clauses": [
      {
        "text": "Policy clause text...",
        "source": "Document.pdf",
        "section": "Section 2.1",
        "relevance_score": 0.85
      }
    ]
  },
  "recommendations": ["Provide specific details..."],
  "query_understanding": {
    "age": null,
    "gender": null,
    "procedure": "dental treatment"
  },
  "processing_time": 4.2
}
```

#### 3. Upload Document
```http
POST /upload
Content-Type: multipart/form-data

file: [PDF/DOCX/TXT file]
```

#### 4. List Documents
```http
GET /documents
```

#### 5. Delete Document
```http
DELETE /documents/{document_name}
```

## 🎯 Usage Examples

### Query Types
The system can handle various insurance-related queries:

- **Coverage Questions**: "What dental treatments are covered?"
- **Exclusions**: "What are the policy exclusions?"
- **Claims**: "46M, knee surgery, Mumbai, coverage amount?"
- **Benefits**: "What are the maternity benefits?"
- **Waiting Periods**: "What are the waiting periods for pre-existing conditions?"

### Frontend Integration

```javascript
// Process a query with LLM reasoning
async function processQuery(query) {
  const response = await fetch('http://localhost:8000/process', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      query: query,
      use_llm_reasoning: true,
      top_k: 5
    })
  });
  return await response.json();
}

// Upload a document
async function uploadDocument(file) {
  const formData = new FormData();
  formData.append('file', file);
  
  const response = await fetch('http://localhost:8000/upload', {
    method: 'POST',
    body: formData
  });
  return await response.json();
}
```

## 📋 Available Scripts

From the root directory:
```bash
npm run dev              # Start both backend and frontend
npm run backend          # Start only backend
npm run frontend         # Start only frontend
npm run backend:install  # Install Python dependencies
npm run frontend:install # Install Node.js dependencies
npm run install          # Install all dependencies
npm run frontend:build   # Build frontend for production
npm run clean            # Clean all dependencies and cache
```

## 🔧 Development

### Backend Development
```bash
cd backend
source venv/bin/activate

# Start with auto-reload
python -m uvicorn app.api:app --reload

# CLI operations
python main.py ingest --path data/documents/
python main.py query --query "your question"
python main.py status
```

### Frontend Development
```bash
cd frontend
npm start          # Start development server
npm run build      # Build for production
npm test           # Run tests
```

## 🎨 UI Features

### Modern Design
- **Glass Morphism**: Semi-transparent containers with backdrop blur
- **Smooth Animations**: Fade-in effects and hover interactions
- **Gradient Backgrounds**: Beautiful purple-blue gradients
- **Responsive Layout**: Works on desktop and mobile

### Interactive Elements
- **Real-time Chat**: Instant message display with typing indicators
- **Document Upload**: Drag & drop with progress feedback
- **Status Indicators**: Live backend connection status
- **Hover Effects**: Enhanced button and input interactions

## 🔒 Security

- **Environment Variables**: API keys stored securely in `.env` files
- **CORS Configuration**: Properly configured for development
- **Input Validation**: File type and size validation
- **Error Handling**: Graceful error responses

## 📊 Performance

- **Document Processing**: ~1-2 seconds per document
- **Query Processing**: ~2-5 seconds per query (with LLM reasoning)
- **Concurrent Requests**: Supported via FastAPI async
- **File Size Limit**: 50MB per document
- **Supported Formats**: PDF, DOCX, TXT

## 🐛 Troubleshooting

### Common Issues

1. **Backend Connection Failed**
   - Check if backend is running on port 8000
   - Verify virtual environment is activated
   - Check API health at http://localhost:8000/health

2. **LLM Reasoning Not Working**
   - Verify Azure OpenAI credentials in `.env`
   - Check API endpoint and deployment name
   - Ensure sufficient API quota

3. **Document Upload Fails**
   - Check file format (PDF, DOCX, TXT only)
   - Verify file size (max 50MB)
   - Check backend logs for errors

### Error Codes
- `200` - Success
- `400` - Bad Request (invalid query/file)
- `404` - Not Found (no relevant documents)
- `500` - Internal Server Error

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Links

- **Live Demo**: [Add your demo link]
- **API Documentation**: http://localhost:8000/docs
- **Azure OpenAI**: https://azure.microsoft.com/services/openai/
- **FastAPI**: https://fastapi.tiangolo.com/

---

**Ready to use!** Start with the health check endpoint to verify connectivity, then upload documents and start asking questions about your insurance policies.
