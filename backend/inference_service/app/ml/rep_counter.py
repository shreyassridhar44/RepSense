"""Rep Counting — phase-based, not frame-classification-based.

"Rep counting should not rely solely on frame classification. Instead use
movement phases: Down -> Pause -> Up -> Lockout. One complete cycle equals
one repetition." (technical specification)
"""
from enum import Enum, auto


class RepPhase(Enum):
    LOCKOUT = auto()
    DOWN = auto()
    PAUSE = auto()
    UP = auto()


# Exercise-specific phase thresholds, keyed by the primary tracked angle.
# Extend this table when adding new exercises — no inference logic changes
# required, per "Extensions should be modular" in the spec.
EXERCISE_THRESHOLDS = {
    "squat": {"angle": "left_knee_flexion", "down": 100, "up": 160},
    "deadlift": {"angle": "left_hip_flexion", "down": 90, "up": 160},
    "bench_press": {"angle": "left_elbow_extension", "down": 80, "up": 160},
    "push_up": {"angle": "left_elbow_extension", "down": 90, "up": 160},
    "bicep_curl": {"angle": "left_elbow_extension", "down": 160, "up": 50},
    "overhead_press": {"angle": "left_elbow_extension", "down": 90, "up": 165},
}


class RepCounter:
    def __init__(self, exercise: str) -> None:
        config = EXERCISE_THRESHOLDS.get(exercise, EXERCISE_THRESHOLDS["squat"])
        self.angle_key = config["angle"]
        self.down_threshold = config["down"]
        self.up_threshold = config["up"]
        self.phase = RepPhase.LOCKOUT
        self.reps = 0
        self.rep_angle_log: list[list[float]] = []
        self._current_rep_angles: list[float] = []

    def update(self, angles: dict[str, float]) -> bool:
        """Feed one frame's joint angles. Returns True exactly when a rep completes."""
        angle = angles.get(self.angle_key)
        if angle is None:
            return False

        self._current_rep_angles.append(angle)
        completed = False
        inverted = self.down_threshold > self.up_threshold  # e.g. bicep curl

        def passed_down() -> bool:
            return angle < self.down_threshold if not inverted else angle > self.down_threshold

        def passed_up() -> bool:
            return angle > self.up_threshold if not inverted else angle < self.up_threshold

        if self.phase == RepPhase.LOCKOUT and passed_down():
            self.phase = RepPhase.DOWN
        elif self.phase == RepPhase.DOWN:
            self.phase = RepPhase.PAUSE
        elif self.phase == RepPhase.PAUSE and passed_down():
            self.phase = RepPhase.UP
        elif self.phase == RepPhase.UP and passed_up():
            self.phase = RepPhase.LOCKOUT
            self.reps += 1
            completed = True
            self.rep_angle_log.append(self._current_rep_angles)
            self._current_rep_angles = []

        return completed
