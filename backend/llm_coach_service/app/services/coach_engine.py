"""Natural Language Coach.

Final stage of the recommended ML pipeline: "LLM only for generating
natural-language explanations." Takes structured output from the
Inference Service (scores + FormIssue objects) and the AI Explainability
fields the spec requires (Why / What / How / Risk / Confidence / Severity)
and turns them into RepSense's brand-tone coaching copy: Professional,
Supportive, Educational, Precise, Clear, Confident — never casual, never
judgmental.

Supports both Anthropic Claude and Google Gemini.
"""
from app.core.config import get_settings

settings = get_settings()

_anthropic_client = None
_gemini_model = None


def get_anthropic_client():
    """Get or create Anthropic client."""
    global _anthropic_client
    if _anthropic_client is None:
        from anthropic import Anthropic
        _anthropic_client = Anthropic(api_key=settings.anthropic_api_key)
    return _anthropic_client


def get_gemini_model():
    """Get or create Google Gemini model."""
    global _gemini_model
    if _gemini_model is None:
        import google.generativeai as genai
        genai.configure(api_key=settings.google_api_key)
        _gemini_model = genai.GenerativeModel(settings.google_model)
    return _gemini_model


def _build_system_prompt(ctx: dict | None) -> str:
    """Build system prompt with optional user context."""
    base = """You are the RepSense AI Coach — an expert in exercise biomechanics, strength training programming, injury prevention, and sports nutrition. Voice: professional, supportive, educational, precise, clear, confident. Never casual, never judgmental. Always explain the WHY behind recommendations. If asked about pain or injury: recommend consulting a physiotherapist or physician, do not attempt to diagnose. Keep responses concise (3–5 sentences) unless asked for detail. Format with bullet points only when listing 3+ items."""

    if not ctx:
        return base

    context_block = f"""

User profile:
- Name: {ctx.get('display_name', 'Athlete')}
- Experience: {ctx.get('training_experience', 'Unknown')}
- Goals: {', '.join(ctx.get('goals', [])) or 'Not specified'}
- Stats: {ctx.get('total_workouts', 0)} total workouts, {ctx.get('current_streak_days', 0)}-day streak
- Avg form score (last 7 days): {ctx.get('avg_form_score_last_7_days', 'N/A')}
- Most trained: {ctx.get('most_trained_exercise', 'N/A')}
- Weakest area: {ctx.get('weakest_muscle_group', 'N/A')}
- Recent form issues: {', '.join(ctx.get('recent_issues', [])) or 'None'}

Use this context to give personalized answers. Reference the user's actual data when relevant (e.g. "Given your squat score of 78, focusing on depth would help"). Do not repeat all context back — only reference what is relevant to the question."""

    return base + context_block


async def _call_llm(
    prompt: str, max_tokens: int = 500, system_prompt: str | None = None
) -> str:
    """Call the configured LLM provider."""
    system = system_prompt or _build_system_prompt(None)

    if settings.llm_provider == "google":
        model = get_gemini_model()
        full_prompt = f"{system}\n\n{prompt}"
        response = model.generate_content(full_prompt)
        return response.text
    else:  # anthropic
        client = get_anthropic_client()
        message = client.messages.create(
            model=settings.anthropic_model,
            max_tokens=max_tokens,
            system=system,
            messages=[{"role": "user", "content": prompt}],
        )
        return message.content[0].text


async def _generate_followups(
    question: str, answer: str, ctx: dict | None
) -> list[str]:
    """Generate 2-3 follow-up questions based on the Q&A."""
    try:
        if settings.llm_provider == "google":
            model = get_gemini_model()
            prompt = (
                f"Given this Q&A, suggest 2 short follow-up questions "
                f"(under 8 words each, no punctuation, plain text, "
                f"one per line):\nQ: {question}\nA: {answer[:200]}"
            )
            response = model.generate_content(prompt)
            lines = response.text.strip().split("\n")
            return [line.strip() for line in lines if line.strip()][:3]
        else:  # anthropic
            client = get_anthropic_client()
            response = client.messages.create(
                model=settings.anthropic_model,
                max_tokens=100,
                messages=[
                    {
                        "role": "user",
                        "content": f"Given this Q&A, suggest 2 short follow-up questions "
                        f"(under 8 words each, no punctuation, plain text, "
                        f"one per line):\nQ: {question}\nA: {answer[:200]}",
                    }
                ],
            )
            lines = response.content[0].text.strip().split("\n")
            return [line.strip() for line in lines if line.strip()][:3]
    except Exception:
        return []


async def generate_rep_feedback(issue: dict) -> str:
    """Turn one structured FormIssue (problem/reason/correction/confidence/
    severity) into a natural-language coaching line for the Camera Screen's
    real-time feedback banner."""
    prompt = (
        f"Turn this structured form issue into one short, encouraging "
        f"coaching line (max 20 words):\n"
        f"Problem: {issue['problem']}\n"
        f"Reason: {issue['reason']}\n"
        f"Correction: {issue['correction']}\n"
        f"Severity: {issue['severity']}"
    )
    return await _call_llm(prompt, max_tokens=150)


async def answer_question(
    question: str, conversation_history: list[dict], user_context: dict | None
) -> tuple[str, list[str]]:
    """Powers the AI Coach chat screen — free-form Q&A grounded in the
    user's recent workout context when available."""
    # Build system prompt with user context
    system = _build_system_prompt(user_context)

    # Build messages array: history + new user message
    messages = [
        {"role": msg["role"], "content": msg["content"]} for msg in conversation_history
    ]
    messages.append({"role": "user", "content": question})

    # Call LLM with conversation history
    if settings.llm_provider == "google":
        model = get_gemini_model()
        # Gemini doesn't support system prompts in the same way
        # Prepend system to first user message
        full_prompt = f"{system}\n\n" + "\n".join(
            [f"{m['role']}: {m['content']}" for m in messages]
        )
        response = model.generate_content(full_prompt)
        answer = response.text
    else:  # anthropic
        client = get_anthropic_client()
        response = client.messages.create(
            model=settings.anthropic_model,
            max_tokens=800,
            system=system,
            messages=messages,
        )
        answer = response.content[0].text

    # Generate suggested follow-ups
    followups = await _generate_followups(question, answer, user_context)

    return answer, followups


async def analyze_image(
    image_base64: str, media_type: str, question: str, ctx: dict | None
) -> tuple[str, list[str]]:
    """Analyze an image with Claude's vision capability."""
    system = _build_system_prompt(ctx)

    if settings.llm_provider == "google":
        # Google Gemini also supports vision
        model = get_gemini_model()
        import base64
        import io
        from PIL import Image

        # Decode base64 to image
        image_data = base64.b64decode(image_base64)
        image = Image.open(io.BytesIO(image_data))

        prompt = f"{system}\n\n{question}"
        response = model.generate_content([prompt, image])
        answer = response.text
    else:  # anthropic
        client = get_anthropic_client()
        response = client.messages.create(
            model=settings.anthropic_model,
            max_tokens=600,
            system=system,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": media_type,
                                "data": image_base64,
                            },
                        },
                        {"type": "text", "text": question},
                    ],
                }
            ],
        )
        answer = response.content[0].text

    followups = await _generate_followups(question, answer, ctx)
    return answer, followups


async def summarize_workout(workout_data: dict) -> str:
    """Generates the 'AI observations' / top-mistakes narrative shown on
    the Exercise Summary screen."""
    prompt = (
        f"Summarize this workout in 2-3 sentences, highlighting the "
        f"single most important thing to improve next time: {workout_data}"
    )
    return await _call_llm(prompt, max_tokens=300)
