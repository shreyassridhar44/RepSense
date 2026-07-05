@echo off
echo ========================================
echo RepSense Backend Services Startup
echo ========================================
echo.
echo This will start all three backend services using Docker Compose.
echo Make sure Docker Desktop is running!
echo.
echo Services will be available at:
echo   - API Service:       http://localhost:8000/docs
echo   - Inference Service: http://localhost:8001/docs
echo   - Coach Service:     http://localhost:8002/docs
echo.
echo Press Ctrl+C to stop all services.
echo ========================================
echo.

cd backend
docker compose up --build
