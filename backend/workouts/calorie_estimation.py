MET_BY_DIFFICULTY = {
    "beginner": 3.5,
    "intermediate": 5.0,
    "advanced": 7.0,
}


def estimate_calories_burned(weight_kg, duration_minutes, difficulty):
    if weight_kg is None:
        return None

    met = MET_BY_DIFFICULTY[difficulty]
    calories = met * 3.5 * float(weight_kg) / 200 * duration_minutes
    return round(calories)
