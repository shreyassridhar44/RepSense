"""
Account management routes - Module 9
Handles account deletion with service role privileges
"""
from fastapi import APIRouter, HTTPException, Depends, Header
from supabase import Client
from typing import Optional
import os
from ...db.supabase_client import get_supabase_client

router = APIRouter(prefix="/account", tags=["account"])


@router.delete("/delete")
async def delete_account(
    authorization: Optional[str] = Header(None),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Delete user account completely (GDPR compliance)
    
    This endpoint:
    1. Verifies the user's JWT token
    2. Deletes avatar from storage
    3. Deletes workout media from storage
    4. Deletes the auth user (cascades to all tables)
    
    Requires: Valid JWT token in Authorization header
    """
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header required")
    
    # Extract token
    token = authorization.replace("Bearer ", "")
    
    try:
        # Verify token and get user
        user_response = supabase.auth.get_user(token)
        user = user_response.user
        
        if not user:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        user_id = user.id
        
        # Delete avatar from storage (non-critical)
        try:
            supabase.storage.from_("avatars").remove([f"{user_id}.jpg"])
        except Exception as e:
            print(f"Avatar deletion error (non-critical): {e}")
        
        # Delete workout media from storage (non-critical)
        try:
            files = supabase.storage.from_("workout-media").list(f"workouts/{user_id}")
            if files:
                file_paths = [f"workouts/{user_id}/{f['name']}" for f in files]
                supabase.storage.from_("workout-media").remove(file_paths)
        except Exception as e:
            print(f"Workout media deletion error (non-critical): {e}")
        
        # Delete auth user - this cascades to all related tables
        # Uses admin API with service role key
        supabase.auth.admin.delete_user(user_id)
        
        return {
            "success": True,
            "message": "Account deleted successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Account deletion error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete account: {str(e)}"
        )
