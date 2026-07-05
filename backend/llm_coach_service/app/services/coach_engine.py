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


SYSTEM_PROMPT = """You are the RepSense AI Coach — an explainable, biomechanics-aware \
strength training assistant. Voice: professional, supportive, educational, precise, \
clear, confident. Never casual, never judgmental.

When explaining a form correction, always cover: what happened, why it matters \
(injury/performance risk), and a concrete correction. Keep responses concise \
(2-4 sentences) unless asked for more detail. You are not a medical professional — \
for pain or injury concerns, recommend consulting a physical therapist or physician."""


async def _call_llm(prompt: str, max_tokens: int = 500) -> str:
    """Call the configured LLM provider."""
    if settings.llm_provider == "google":
        model = get_gemini_model()
        full_prompt = f"{SYSTEM_PROMPT}\n\n{prompt}"
        response = model.generate_content(full_prompt)
        return response.text
    else:  # anthropic
        client = get_anthropic_client()
        message = client.messages.create(
            model=settings.anthropic_model,
            max_tokens=max_tokens,
            system=SYSTEM_PROMPT,
            messages=[{"role": "user", "content": prompt}],
        )
        return message.content[0].text


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


async def answer_question(question: str, context: dict | None = None) -> str:
    """Powers the AI Coach chat screen — free-form Q&A grounded in the
    user's recent workout context when available."""
    context_str = f"\n\nUser's recent context: {context}" if context else ""
    prompt = f"{question}{context_str}"
    return await _call_llm(prompt, max_tokens=500)


async def summarize_workout(workout_data: dict) -> str:
    """Generates the 'AI observations' / top-mistakes narrative shown on
    the Exercise Summary screen."""
    prompt = (
        f"Summarize this workout in 2-3 sentences, highlighting the "
        f"single most important thing to improve next time: {workout_data}"
    )
    return await _call_llm(prompt, max_tokens=300)
