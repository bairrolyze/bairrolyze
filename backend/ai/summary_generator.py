import json
from typing import Optional
from openai import AsyncOpenAI
from config.settings import settings
from models.schemas import LocationScore, AmenityModel, GeocodeResponse


SYSTEM_PROMPT = """You are an expert real estate and urban planning analyst.
Analyze neighborhood data and provide clear, concise insights for someone considering moving to this location.
Be specific, practical, and honest. Keep the total response under 200 words.
Write in plain English without bullet points — flowing paragraphs only."""

USER_PROMPT_TEMPLATE = """Analyze this neighborhood for someone considering moving here:

Address: {address}
Overall Location Score: {overall_score}/10

Category Scores:
{category_scores}

Amenities found within 2km:
{amenity_summary}

Provide a concise neighborhood summary covering:
1. Overall character and suitability
2. Key strengths (2-3 points)
3. Notable weaknesses (1-2 points)
4. Best suited for: families / professionals / students / retirees

Write 2-3 flowing paragraphs. Be specific and practical."""


def _build_category_scores_text(score: LocationScore) -> str:
    lines = []
    for cat_id, cat_score in score.categories.items():
        closest_info = ""
        if cat_score.closest:
            dist = cat_score.closest.distance_meters
            mins = cat_score.closest.walking_minutes
            closest_info = f" (nearest: {cat_score.closest.name}"
            if dist:
                closest_info += f", {dist}m"
            if mins:
                closest_info += f", {mins}min walk"
            closest_info += ")"
        lines.append(f"- {cat_score.label}: {cat_score.score / 10:.1f}/10 ({cat_score.count} places){closest_info}")
    return "\n".join(lines)


def _build_amenity_summary(amenities: list) -> str:
    from collections import Counter
    counts = Counter(a.category.value for a in amenities)
    parts = [f"{v} {k}" for k, v in counts.items()]
    return ", ".join(parts) if parts else "No amenities found"


class SummaryGenerator:
    def __init__(self):
        self._client: Optional[AsyncOpenAI] = None

    @property
    def client(self) -> AsyncOpenAI:
        if self._client is None:
            if not settings.openai_api_key:
                raise ValueError("OpenAI API key not configured")
            self._client = AsyncOpenAI(api_key=settings.openai_api_key)
        return self._client

    async def generate(
        self,
        address: str,
        score: LocationScore,
        amenities: list,
    ) -> str:
        category_scores_text = _build_category_scores_text(score)
        amenity_summary = _build_amenity_summary(amenities)

        user_prompt = USER_PROMPT_TEMPLATE.format(
            address=address,
            overall_score=f"{score.overall / 10:.1f}",
            category_scores=category_scores_text,
            amenity_summary=amenity_summary,
        )

        response = await self.client.chat.completions.create(
            model=settings.openai_model,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_prompt},
            ],
            max_tokens=400,
            temperature=0.7,
        )

        return response.choices[0].message.content.strip()

    def _fallback_summary(self, score: LocationScore, address: str) -> str:
        overall = score.overall
        if overall >= 80:
            quality = "excellent"
        elif overall >= 60:
            quality = "good"
        elif overall >= 40:
            quality = "fair"
        else:
            quality = "below average"

        best_cats = sorted(
            score.categories.values(), key=lambda c: c.score, reverse=True
        )[:2]
        best_names = " and ".join(c.label.lower() for c in best_cats)

        return (
            f"This location has a {quality} location score of {overall / 10:.1f}/10. "
            f"The area scores particularly well in {best_names}. "
            f"Explore the map to see all nearby amenities within 2km."
        )


summary_generator = SummaryGenerator()
