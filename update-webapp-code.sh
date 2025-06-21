#!/bin/bash
set -e

BACKEND_URL="$1"
if [ -z "$BACKEND_URL" ]; then
  echo "Usage: $0 <backend-url>"
  exit 1
fi

echo "🔧 Updating Model Router application code with backend URL: $BACKEND_URL"

ORIGINAL_DIR=$(pwd)

BACKEND_DIR="./backend"
rm -rf "$BACKEND_DIR"
mkdir -p "$BACKEND_DIR/app"

echo "🚀 Creating backend application code..."

cat > "$BACKEND_DIR/app/main.py" << 'EOF'
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import httpx
import os
import logging
from datetime import datetime

app = FastAPI(title="Azure AI Foundry Model Router API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    model_router_endpoint: Optional[str] = None
    api_key: Optional[str] = None
    auth_type: str = "api_key"
    temperature: Optional[float] = 0.7
    max_tokens: Optional[int] = 1000

class ChatResponse(BaseModel):
    response: str
    model_used: str
    cost_estimate: float
    complexity_score: float
    cached: bool = False
    timestamp: str

@app.get("/")
async def root():
    return {"message": "Azure AI Foundry Model Router API", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        if not request.model_router_endpoint or not request.api_key:
            raise HTTPException(
                status_code=400, 
                detail="Model Router endpoint and API key are required"
            )
        
        complexity = calculate_complexity(request.messages)
        
        headers = {"Content-Type": "application/json"}
        if request.auth_type == "api_key":
            headers["Authorization"] = f"Bearer {request.api_key}"
        elif request.auth_type == "aad_token":
            headers["Authorization"] = f"Bearer {request.api_key}"
        
        payload = {
            "messages": [{"role": msg.role, "content": msg.content} for msg in request.messages],
            "temperature": request.temperature,
            "max_tokens": request.max_tokens
        }
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                request.model_router_endpoint,
                json=payload,
                headers=headers
            )
            
            if response.status_code != 200:
                logger.error(f"Model Router API error: {response.status_code} - {response.text}")
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Model Router API error: {response.text}"
                )
            
            result = response.json()
            
            ai_response = result.get("choices", [{}])[0].get("message", {}).get("content", "")
            model_used = result.get("model", "unknown")
            
            cost_estimate = estimate_cost(model_used, len(str(request.messages)), len(ai_response))
            
            return ChatResponse(
                response=ai_response,
                model_used=model_used,
                cost_estimate=cost_estimate,
                complexity_score=complexity,
                cached=False,
                timestamp=datetime.utcnow().isoformat()
            )
            
    except httpx.TimeoutException:
        raise HTTPException(status_code=408, detail="Request timeout - Model Router did not respond")
    except httpx.RequestError as e:
        logger.error(f"Request error: {str(e)}")
        raise HTTPException(status_code=503, detail=f"Service unavailable: {str(e)}")
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

def calculate_complexity(messages: List[ChatMessage]) -> float:
    """Calculate query complexity for analytics purposes"""
    total_length = sum(len(msg.content) for msg in messages)
    
    technical_keywords = [
        "algorithm", "architecture", "implementation", "optimization", "performance",
        "scalability", "distributed", "microservices", "kubernetes", "docker",
        "machine learning", "neural network", "deep learning", "artificial intelligence",
        "blockchain", "cryptocurrency", "database", "sql", "nosql", "api", "rest",
        "graphql", "authentication", "authorization", "security", "encryption"
    ]
    
    keyword_count = sum(1 for msg in messages for keyword in technical_keywords 
                       if keyword.lower() in msg.content.lower())
    
    length_score = min(total_length / 1000, 0.7)  # Cap length influence
    keyword_score = min(keyword_count * 0.1, 0.3)  # Cap keyword influence
    
    return round(length_score + keyword_score, 2)

def estimate_cost(model: str, input_tokens: int, output_tokens: int) -> float:
    """Estimate cost based on model and token usage"""
    cost_per_1k_tokens = {
        "gpt-4": 0.03,
        "gpt-3.5-turbo": 0.002,
        "claude-3-sonnet": 0.003,
        "claude-3-haiku": 0.00025
    }
    
    base_cost = cost_per_1k_tokens.get(model.lower(), 0.002)
    total_tokens = input_tokens + output_tokens
    
    return round((total_tokens / 1000) * base_cost, 4)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

cat > "$BACKEND_DIR/requirements.txt" << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
httpx==0.25.2
pydantic==2.5.0
python-multipart==0.0.6
EOF

touch "$BACKEND_DIR/app/__init__.py"

echo "📦 Packaging backend code..."
cd "$BACKEND_DIR"

if command -v zip >/dev/null 2>&1; then
    echo "✅ Using zip command to package backend..."
    zip -r "$ORIGINAL_DIR/webapp-code/backend.zip" . -x "*.pyc" "__pycache__/*" ".env"
else
    echo "⚠️  Zip command not available. Please manually create backend.zip:"
    echo "   1. Navigate to the ./backend directory"
    echo "   2. Select all files and folders (excluding .pyc files and __pycache__ folders)"
    echo "   3. Create a zip archive named 'backend.zip'"
    echo "   4. Move the backend.zip file to ./webapp-code/backend.zip"
    echo ""
    echo "   Files to include in backend.zip:"
    find . -type f ! -name "*.pyc" ! -path "*/__pycache__/*" ! -name ".env" | sed 's|^\./|   - |'
    echo ""
    echo "   Expected location: $ORIGINAL_DIR/webapp-code/backend.zip"
    echo ""
    read -p "Press Enter after you have manually created backend.zip in ./webapp-code/ directory..."
    
    if [ ! -f "$ORIGINAL_DIR/webapp-code/backend.zip" ]; then
        echo "❌ Error: backend.zip not found in ./webapp-code/ directory"
        echo "Please create the zip file and run the script again."
        exit 1
    else
        echo "✅ Found backend.zip in ./webapp-code/ directory"
    fi
fi

FRONTEND_DIR="./frontend"
rm -rf "$FRONTEND_DIR"
mkdir -p "$FRONTEND_DIR/src"

echo "🎨 Creating frontend application code..."

cat > "$FRONTEND_DIR/package.json" << 'EOF'
{
  "name": "azure-model-router-frontend",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "axios": "^1.6.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.37",
    "@types/react-dom": "^18.2.15",
    "@typescript-eslint/eslint-plugin": "^6.10.0",
    "@typescript-eslint/parser": "^6.10.0",
    "@vitejs/plugin-react": "^4.1.0",
    "eslint": "^8.53.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.4",
    "typescript": "^5.2.2",
    "vite": "^4.5.0"
  }
}
EOF

cat > "$FRONTEND_DIR/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

cat > "$FRONTEND_DIR/tsconfig.node.json" << 'EOF'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
EOF

cat > "$FRONTEND_DIR/vite.config.ts" << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist'
  }
})
EOF

cat > "$FRONTEND_DIR/index.html" << 'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Azure AI Foundry Model Router</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

cat > "$FRONTEND_DIR/src/main.tsx" << 'EOF'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.tsx'
import './index.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
EOF

cat > "$FRONTEND_DIR/src/index.css" << 'EOF'
:root {
  font-family: Inter, system-ui, Avenir, Helvetica, Arial, sans-serif;
  line-height: 1.5;
  font-weight: 400;
  color-scheme: light dark;
  color: rgba(255, 255, 255, 0.87);
  background-color: #242424;
  font-synthesis: none;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  -webkit-text-size-adjust: 100%;
}

a {
  font-weight: 500;
  color: #646cff;
  text-decoration: inherit;
}
a:hover {
  color: #535bf2;
}

body {
  margin: 0;
  display: flex;
  place-items: center;
  min-width: 320px;
  min-height: 100vh;
}

h1 {
  font-size: 3.2em;
  line-height: 1.1;
}

button {
  border-radius: 8px;
  border: 1px solid transparent;
  padding: 0.6em 1.2em;
  font-size: 1em;
  font-weight: 500;
  font-family: inherit;
  background-color: #1a1a1a;
  color: white;
  cursor: pointer;
  transition: border-color 0.25s;
}
button:hover {
  border-color: #646cff;
}
button:focus,
button:focus-visible {
  outline: 4px auto -webkit-focus-ring-color;
}

@media (prefers-color-scheme: light) {
  :root {
    color: #213547;
    background-color: #ffffff;
  }
  a:hover {
    color: #747bff;
  }
  button {
    background-color: #f9f9f9;
    color: #213547;
  }
}
EOF

cat > "$FRONTEND_DIR/src/App.tsx" << 'EOF'
import { useState } from 'react';
import axios from 'axios';

interface ChatMessage {
  role: string;
  content: string;
}

interface ChatResponse {
  response: string;
  model_used: string;
  cost_estimate: number;
  complexity_score: number;
  cached: boolean;
  timestamp: string;
}

function App() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [inputMessage, setInputMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [modelRouterEndpoint, setModelRouterEndpoint] = useState('');
  const [apiKey, setApiKey] = useState('');
  const [authType, setAuthType] = useState('api_key');
  const [lastResponse, setLastResponse] = useState<ChatResponse | null>(null);

  const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

  const sendMessage = async () => {
    if (!inputMessage.trim() || !modelRouterEndpoint || !apiKey) return;

    const newMessage: ChatMessage = { role: 'user', content: inputMessage };
    const updatedMessages = [...messages, newMessage];
    setMessages(updatedMessages);
    setInputMessage('');
    setLoading(true);

    try {
      const response = await axios.post(`${apiBaseUrl}/chat`, {
        messages: updatedMessages,
        model_router_endpoint: modelRouterEndpoint,
        api_key: apiKey,
        auth_type: authType,
        temperature: 0.7,
        max_tokens: 1000
      });

      const assistantMessage: ChatMessage = {
        role: 'assistant',
        content: response.data.response
      };

      setMessages([...updatedMessages, assistantMessage]);
      setLastResponse(response.data);
    } catch (error) {
      console.error('Error sending message:', error);
      const errorMessage: ChatMessage = {
        role: 'assistant',
        content: 'Error: Failed to get response from Model Router. Please check your configuration.'
      };
      setMessages([...updatedMessages, errorMessage]);
    } finally {
      setLoading(false);
    }
  };

  const clearChat = () => {
    setMessages([]);
    setLastResponse(null);
  };

  return (
    <div style={{ padding: '20px', maxWidth: '800px', margin: '0 auto' }}>
      <h1>Azure AI Foundry Model Router</h1>
      
      <div style={{ marginBottom: '20px', padding: '15px', border: '1px solid #ccc', borderRadius: '5px' }}>
        <h3>Configuration</h3>
        <div style={{ marginBottom: '10px' }}>
          <label>Model Router Endpoint:</label>
          <input
            type="text"
            value={modelRouterEndpoint}
            onChange={(e) => setModelRouterEndpoint(e.target.value)}
            placeholder="https://your-project-model-router-env.region.inference.ml.azure.com/score"
            style={{ width: '100%', padding: '5px', marginTop: '5px' }}
          />
        </div>
        <div style={{ marginBottom: '10px' }}>
          <label>API Key:</label>
          <input
            type="password"
            value={apiKey}
            onChange={(e) => setApiKey(e.target.value)}
            placeholder="Your Azure AI Foundry API Key"
            style={{ width: '100%', padding: '5px', marginTop: '5px' }}
          />
        </div>
        <div style={{ marginBottom: '10px' }}>
          <label>Auth Type:</label>
          <select
            value={authType}
            onChange={(e) => setAuthType(e.target.value)}
            style={{ width: '100%', padding: '5px', marginTop: '5px' }}
          >
            <option value="api_key">API Key</option>
            <option value="aad_token">AAD Token</option>
          </select>
        </div>
      </div>

      <div style={{ marginBottom: '20px', height: '400px', overflowY: 'auto', border: '1px solid #ccc', padding: '10px' }}>
        {messages.map((message, index) => (
          <div key={index} style={{ marginBottom: '10px' }}>
            <strong>{message.role === 'user' ? 'You' : 'Assistant'}:</strong>
            <div style={{ marginLeft: '10px', whiteSpace: 'pre-wrap' }}>{message.content}</div>
          </div>
        ))}
        {loading && <div>Loading...</div>}
      </div>

      <div style={{ display: 'flex', marginBottom: '10px' }}>
        <input
          type="text"
          value={inputMessage}
          onChange={(e) => setInputMessage(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
          placeholder="Type your message..."
          style={{ flex: 1, padding: '10px', marginRight: '10px' }}
          disabled={loading}
        />
        <button onClick={sendMessage} disabled={loading || !modelRouterEndpoint || !apiKey}>
          Send
        </button>
        <button onClick={clearChat} style={{ marginLeft: '10px' }}>
          Clear
        </button>
      </div>

      {lastResponse && (
        <div style={{ marginTop: '20px', padding: '15px', border: '1px solid #ccc', borderRadius: '5px', backgroundColor: '#f9f9f9' }}>
          <h3>Last Response Analytics</h3>
          <p><strong>Model Used:</strong> {lastResponse.model_used}</p>
          <p><strong>Cost Estimate:</strong> ${lastResponse.cost_estimate.toFixed(4)}</p>
          <p><strong>Complexity Score:</strong> {lastResponse.complexity_score}</p>
          <p><strong>Cached:</strong> {lastResponse.cached ? 'Yes' : 'No'}</p>
          <p><strong>Timestamp:</strong> {new Date(lastResponse.timestamp).toLocaleString()}</p>
        </div>
      )}

      <div style={{ marginTop: '20px', fontSize: '12px', color: '#666' }}>
        <p>This application integrates with Azure AI Foundry Model Router for intelligent model selection and cost optimization.</p>
        <p>Configure your Model Router endpoint and API key above to start testing.</p>
      </div>
    </div>
  );
}

export default App;
EOF

cat > "$FRONTEND_DIR/.env.production" << 'EOF'
VITE_API_BASE_URL=__BACKEND_URL__
EOF

cat > "$FRONTEND_DIR/src/vite-env.d.ts" << 'EOF'
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
EOF

echo "✅ Created frontend application code"

cd "$FRONTEND_DIR"
npm install

sed "s|__BACKEND_URL__|$BACKEND_URL|g" .env.production > .env.local

echo "🎨 Building frontend with production API URL: $BACKEND_URL"
npm run build

echo "📦 Packaging frontend code..."
cd dist

if command -v zip >/dev/null 2>&1; then
    echo "✅ Using zip command to package frontend..."
    zip -r "$ORIGINAL_DIR/webapp-code/frontend.zip" .
else
    echo "⚠️  Zip command not available. Please manually create frontend.zip:"
    echo "   1. Navigate to the ./frontend/dist directory"
    echo "   2. Select all files and folders in the dist directory"
    echo "   3. Create a zip archive named 'frontend.zip'"
    echo "   4. Move the frontend.zip file to ./webapp-code/frontend.zip"
    echo ""
    echo "   Files to include in frontend.zip (from ./frontend/dist/):"
    find . -type f | sed 's|^\./|   - |'
    echo ""
    echo "   Expected location: $ORIGINAL_DIR/webapp-code/frontend.zip"
    echo ""
    read -p "Press Enter after you have manually created frontend.zip in ./webapp-code/ directory..."
    
    if [ ! -f "$ORIGINAL_DIR/webapp-code/frontend.zip" ]; then
        echo "❌ Error: frontend.zip not found in ./webapp-code/ directory"
        echo "Please create the zip file and run the script again."
        exit 1
    else
        echo "✅ Found frontend.zip in ./webapp-code/ directory"
    fi
fi

echo "✅ Updated webapp-code packages with backend URL: $BACKEND_URL"
