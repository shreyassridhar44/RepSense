"""Biomechanics Engine — rule-based form analysis using joint angles.

Per spec: "Rule-based biomechanical analysis using joint angles and
kinematics" sits between the temporal model and the LLM explanation layer.
Each metric (range of motion, tempo, stability, alignment, symmetry,
lockout, depth, control) receives its own 0-100 score.
"""
from dataclasses import dataclass, field


@dataclass
class FormIssue:
    problem: str
    reason: str
    correction: str
    confidence: float  # 0-1
    severity: str  # "Minor" | "Moderate" | "Severe"


@dataclass
class RepAnalysis:
    scores: dict[str, float] = field(default_factory=dict)
    issues: list[FormIssue] = field(default_factory=list)

    @property
    def overall_score(self) -> float:
        if not self.scores:
            return 0.0
        return round(sum(self.scores.values()) / len(self.scores), 1)


def analyze_rep(angle_sequence: list[dict[str, float]], exercise: str) -> RepAnalysis:
    """Analyze a single completed repetition's angle sequence and produce
    per-metric scores plus explainable issues."""
    analysis = RepAnalysis()
    if not angle_sequence:
        return analysis

    knee_angles = [a.get("left_knee_flexion", 180) for a in angle_sequence]
    spine_angles = [a.get("spine_angle", 0) for a in angle_sequence]
    left_knee = knee_angles
    right_knee = [a.get("right_knee_flexion", 180) for a in angle_sequence]

    # Range of motion: how deep did the bottom position go.
    min_knee = min(knee_angles) if knee_angles else 180
    rom_score = max(0, min(100, (170 - min_knee) / 70 * 100))
    analysis.scores["range_of_motion"] = round(rom_score, 1)
    if min_knee > 120 and exercise == "squat":
        analysis.issues.append(FormIssue(
            problem="Squat depth was shallow.",
            reason="Insufficient range of motion reduces muscle activation.",
            correction="Increase squat depth by approximately five centimeters.",
            confidence=0.91,
            severity="Moderate",
        ))

    # Symmetry: difference between left/right knee angle trajectories.
    symmetry_diff = sum(abs(l - r) for l, r in zip(left_knee, right_knee)) / max(1, len(left_knee))
    symmetry_score = max(0, 100 - symmetry_diff * 4)
    analysis.scores["symmetry"] = round(symmetry_score, 1)
    if symmetry_diff > 12:
        analysis.issues.append(FormIssue(
            problem="Your knees moved asymmetrically.",
            reason="Uneven load distribution increases injury risk on the dominant side.",
            correction="Focus on driving both knees evenly throughout the movement.",
            confidence=0.88,
            severity="Moderate",
        ))

    # Spine / posture stability.
    spine_variance = (max(spine_angles) - min(spine_angles)) if spine_angles else 0
    stability_score = max(0, 100 - spine_variance * 3)
    analysis.scores["stability"] = round(stability_score, 1)
    if spine_variance > 15:
        analysis.issues.append(FormIssue(
            problem="Spine angle changed significantly during the rep.",
            reason="This increases stress on the lower back.",
            correction="Maintain a more neutral spine throughout the movement.",
            confidence=0.93,
            severity="Severe" if spine_variance > 25 else "Moderate",
        ))

    # Tempo: number of frames spent in the eccentric (down) phase.
    tempo_score = max(0, min(100, len(angle_sequence) / 30 * 100))
    analysis.scores["tempo"] = round(tempo_score, 1)
    if len(angle_sequence) < 10:
        analysis.issues.append(FormIssue(
            problem="The repetition was performed very quickly.",
            reason="Fast, uncontrolled reps reduce time-under-tension and control.",
            correction="Slow the eccentric phase for better control.",
            confidence=0.85,
            severity="Minor",
        ))

    # Lockout completeness.
    final_knee = knee_angles[-1] if knee_angles else 180
    lockout_score = max(0, min(100, (final_knee - 140) / 30 * 100))
    analysis.scores["lockout"] = round(max(0, lockout_score), 1)

    return analysis
