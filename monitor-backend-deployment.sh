#!/bin/bash

BACKEND_URL="https://hjmrdevproj-backend-dev-nyuxwr.azurewebsites.net"
HEALTH_ENDPOINT="$BACKEND_URL/health"
ROOT_ENDPOINT="$BACKEND_URL/"

echo "🔍 Monitoring Backend Deployment Status"
echo "Backend URL: $BACKEND_URL"
echo "Health Endpoint: $HEALTH_ENDPOINT"
echo ""

check_backend_status() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Checking backend status..."
    
    ROOT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$ROOT_ENDPOINT" 2>/dev/null || echo "000")
    
    HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_ENDPOINT" 2>/dev/null || echo "000")
    
    ROOT_RESPONSE=$(curl -s "$ROOT_ENDPOINT" 2>/dev/null || echo "No response")
    HEALTH_RESPONSE=$(curl -s "$HEALTH_ENDPOINT" 2>/dev/null || echo "No response")
    
    echo "  Root endpoint ($ROOT_ENDPOINT): HTTP $ROOT_STATUS"
    echo "  Health endpoint ($HEALTH_ENDPOINT): HTTP $HEALTH_STATUS"
    
    if [ "$ROOT_STATUS" = "200" ] && [ "$HEALTH_STATUS" = "200" ]; then
        echo "  ✅ SUCCESS: Backend is healthy and responding correctly!"
        echo "  Root response: $ROOT_RESPONSE"
        echo "  Health response: $HEALTH_RESPONSE"
        return 0
    elif [ "$ROOT_STATUS" = "403" ] || [ "$HEALTH_STATUS" = "403" ]; then
        echo "  ❌ ERROR: HTTP 403 - Site Disabled (App Service stopped)"
        echo "  Action: Start the App Service in Azure Portal"
    elif [ "$ROOT_STATUS" = "503" ] || [ "$HEALTH_STATUS" = "503" ]; then
        echo "  ❌ ERROR: HTTP 503 - Application Error (deployment issue)"
        echo "  Action: Check application logs and redeploy backend code"
    elif [ "$ROOT_STATUS" = "404" ] || [ "$HEALTH_STATUS" = "404" ]; then
        echo "  ❌ ERROR: HTTP 404 - Endpoints not found (deployment incomplete)"
        echo "  Action: Verify all backend files are deployed to /site/wwwroot"
    else
        echo "  ⚠️  WARNING: Unexpected status codes"
        echo "  Root response: $ROOT_RESPONSE"
        echo "  Health response: $HEALTH_RESPONSE"
    fi
    
    return 1
}

test_chat_endpoint() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Testing chat endpoint..."
    
    CHAT_RESPONSE=$(curl -s -X POST "$BACKEND_URL/chat" \
        -H "Content-Type: application/json" \
        -d '{"messages": [{"role": "user", "content": "Hello"}], "azure_endpoint": "test", "azure_api_key": "test"}' \
        2>/dev/null)
    
    CHAT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BACKEND_URL/chat" \
        -H "Content-Type: application/json" \
        -d '{"messages": [{"role": "user", "content": "Hello"}], "azure_endpoint": "test", "azure_api_key": "test"}' \
        2>/dev/null || echo "000")
    
    echo "  Chat endpoint: HTTP $CHAT_STATUS"
    
    if [ "$CHAT_STATUS" = "200" ]; then
        echo "  ✅ Chat endpoint working correctly"
        echo "  Response: $CHAT_RESPONSE"
    elif [ "$CHAT_STATUS" = "405" ]; then
        echo "  ❌ ERROR: HTTP 405 - Method Not Allowed (deployment issue)"
        echo "  This is the error causing frontend failures"
    else
        echo "  ⚠️  Chat endpoint status: $CHAT_STATUS"
        echo "  Response: $CHAT_RESPONSE"
    fi
}

if [ "$1" = "--continuous" ]; then
    echo "Starting continuous monitoring (Ctrl+C to stop)..."
    echo ""
    
    while true; do
        if check_backend_status; then
            test_chat_endpoint
            echo ""
            echo "🎉 Backend deployment successful! Monitoring complete."
            break
        fi
        echo ""
        echo "Waiting 30 seconds before next check..."
        sleep 30
    done
else
    check_backend_status
    if [ $? -eq 0 ]; then
        test_chat_endpoint
    fi
    
    echo ""
    echo "💡 To monitor continuously: $0 --continuous"
    echo "💡 Manual deployment guide: BACKEND_DEPLOYMENT_TROUBLESHOOTING.md"
fi
