"""
Rate limiting middleware for API endpoints
Simple in-memory sliding window rate limiter
Replace with Redis-backed implementation when scaling beyond one instance
"""
from fastapi import Request, HTTPException
from collections import defaultdict
from datetime import datetime, timedelta
import asyncio
from typing import Dict, List


class InMemoryRateLimiter:
    """
    Simple sliding window rate limiter.
    Tracks requests per key (user_id or IP) within a time window.
    """

    def __init__(self):
        self._requests: Dict[str, List[datetime]] = defaultdict(list)
        self._lock = asyncio.Lock()

    async def check(self, key: str, limit: int, window_seconds: int) -> bool:
        """
        Check if request is allowed under rate limit.
        
        Args:
            key: Identifier (user_id or IP)
            limit: Maximum requests allowed
            window_seconds: Time window in seconds
            
        Returns:
            True if request is allowed, False if rate limit exceeded
        """
        async with self._lock:
            now = datetime.utcnow()
            window_start = now - timedelta(seconds=window_seconds)
            
            # Remove requests outside the window
            self._requests[key] = [
                t for t in self._requests[key] if t > window_start
            ]
            
            # Check if limit exceeded
            if len(self._requests[key]) >= limit:
                return False
            
            # Add current request
            self._requests[key].append(now)
            return True


# Global rate limiter instance
limiter = InMemoryRateLimiter()


# Rate limits per service:
# api_service:       100 req/min per user_id
# inference_service: 20 req/min per user_id (ML is expensive)
# llm_coach_service: 30 req/min per user_id


async def rate_limit_user(user_id: str, limit: int = 100, window: int = 60):
    """
    Rate limit middleware for authenticated endpoints.
    
    Args:
        user_id: User ID from JWT token
        limit: Maximum requests per window (default 100)
        window: Time window in seconds (default 60)
        
    Raises:
        HTTPException: 429 if rate limit exceeded
    """
    allowed = await limiter.check(f"user:{user_id}", limit=limit, window_seconds=window)
    if not allowed:
        raise HTTPException(
            status_code=429,
            detail="Rate limit exceeded. Try again in a minute."
        )
    return user_id


async def rate_limit_ip(request: Request, limit: int = 5, window: int = 60):
    """
    Rate limit middleware for unauthenticated endpoints (auth routes).
    
    Args:
        request: FastAPI request object
        limit: Maximum requests per window (default 5)
        window: Time window in seconds (default 60)
        
    Raises:
        HTTPException: 429 if rate limit exceeded
    """
    # Get client IP from X-Forwarded-For header (if behind proxy) or direct
    client_ip = request.headers.get("X-Forwarded-For", request.client.host)
    
    allowed = await limiter.check(f"ip:{client_ip}", limit=limit, window_seconds=window)
    if not allowed:
        raise HTTPException(
            status_code=429,
            detail="Too many requests. Try again later."
        )
    return client_ip
