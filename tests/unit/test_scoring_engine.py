import pytest
from datetime import datetime
from models.schemas import AmenityModel, AmenityCategory
from scoring.scoring_engine import (
    _distance_score,
    _count_score,
    calculate_location_score,
)


def make_amenity(category: str, distance: int, name: str = "Test Place") -> AmenityModel:
    return AmenityModel(
        id="test-id",
        name=name,
        category=AmenityCategory(category),
        type=category,
        lat=38.71,
        lng=-9.14,
        distance_meters=distance,
        walking_minutes=distance // 80,
    )


class TestDistanceScore:
    def test_zero_distance_gives_100(self):
        assert _distance_score(0, 1000) == 100.0

    def test_max_distance_gives_zero(self):
        assert _distance_score(1000, 1000) == 0.0

    def test_half_distance_between_0_and_100(self):
        score = _distance_score(500, 1000)
        assert 0 < score < 100

    def test_closer_scores_higher(self):
        assert _distance_score(100, 1000) > _distance_score(500, 1000)


class TestCountScore:
    def test_zero_count_gives_zero(self):
        assert _count_score(0, 5) == 0.0

    def test_ideal_count_gives_high_score(self):
        score = _count_score(5, 5)
        assert score > 60  # exponential saturation

    def test_more_than_ideal_capped_at_100(self):
        assert _count_score(100, 5) <= 100.0


class TestCalculateLocationScore:
    def test_empty_amenities_gives_zero_overall(self):
        score = calculate_location_score([])
        assert score.overall == 0.0

    def test_profile_applied(self):
        amenities = [make_amenity("transportation", 200)]
        default_score = calculate_location_score(amenities, "default")
        family_score = calculate_location_score(amenities, "family")
        # Family weights transport less than default, so score should differ
        assert default_score.overall != family_score.overall

    def test_close_amenities_score_higher(self):
        near = [make_amenity("transportation", 100)]
        far = [make_amenity("transportation", 900)]
        near_score = calculate_location_score(near)
        far_score = calculate_location_score(far)
        assert near_score.overall > far_score.overall

    def test_score_in_valid_range(self):
        amenities = [
            make_amenity("transportation", 200),
            make_amenity("education", 400),
            make_amenity("healthcare", 600),
            make_amenity("shopping", 300),
        ]
        score = calculate_location_score(amenities)
        assert 0 <= score.overall <= 100

    def test_categories_present_in_result(self):
        amenities = [make_amenity("transportation", 200)]
        score = calculate_location_score(amenities)
        assert "transportation" in score.categories

    def test_closest_amenity_set(self):
        amenities = [
            make_amenity("education", 300, "School A"),
            make_amenity("education", 500, "School B"),
        ]
        score = calculate_location_score(amenities)
        ed_score = score.categories.get("education")
        assert ed_score is not None
        assert ed_score.closest is not None
        assert ed_score.closest.name == "School A"

    def test_profile_weights_sum_to_one(self):
        from config.scoring_config import PROFILE_WEIGHTS
        for profile, weights in PROFILE_WEIGHTS.items():
            total = sum(weights.values())
            assert abs(total - 1.0) < 0.01, f"Profile {profile} weights sum to {total}"
