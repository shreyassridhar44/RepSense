from fastapi import Header, HTTPException, status
from supabase import create_client, Client
import jwt

from app.core.config import get_settings

settings = get_settings()

_supabase_client: Client | None = None


def get_supabase() -> Client:
    """Server-side Supabase client using the service role key.
    Used for privileged operations (admin queries, storage management).
    Never expose the service role key to the Flutter app."""
    global _supabase_client
    if _supabase_client is None:
        _supabase_client = create_client(settings.supabase_url, settings.supabase_service_role_key)
    return _supabase_client


async def get_current_user_id(authorization: str = Header(default="")) -> str:
    """Verifies the Supabase JWT sent by the Flutter client in the
    `Authorization: Bearer <token>` header and returns the user id (sub claim).
    The token is the same one supabase_flutter attaches automatically when
    you call SupabaseService.client.auth.currentSession?.accessToken.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token")

    token = authorization.removeprefix("Bearer ").strip()
    try:
        payload = jwt.decode(
            token,
            settings.supabase_jwt_secret,
            algorithms=["HS256"],
            audience="authenticated",
        )
    except jwt.PyJWTError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token") from exc

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")
    return user_id
