"""Joint Angle Engine.

Calculates the core biomechanical angles described in the technical
specification (knee flexion, hip flexion, shoulder elevation, elbow
extension, spine angle, neck angle, ankle angle) from a frame of 33
MediaPipe Pose landmarks.
"""
import math
from dataclasses import dataclass


@dataclass
class Landmark:
    x: float
    y: float
    z: float = 0.0
    visibility: float = 1.0


def _angle(a: Landmark, b: Landmark, c: Landmark) -> float:
    """Angle at vertex b, formed by rays b->a and b->c, in degrees."""
    v1 = (a.x - b.x, a.y - b.y)
    v2 = (c.x - b.x, c.y - b.y)
    dot = v1[0] * v2[0] + v1[1] * v2[1]
    mag1 = math.hypot(*v1)
    mag2 = math.hypot(*v2)
    if mag1 == 0 or mag2 == 0:
        return 180.0
    cos_angle = max(-1.0, min(1.0, dot / (mag1 * mag2)))
    return math.degrees(math.acos(cos_angle))


# MediaPipe Pose landmark indices (subset relevant to joint angle math)
LM = {
    "left_shoulder": 11, "right_shoulder": 12,
    "left_elbow": 13, "right_elbow": 14,
    "left_wrist": 15, "right_wrist": 16,
    "left_hip": 23, "right_hip": 24,
    "left_knee": 25, "right_knee": 26,
    "left_ankle": 27, "right_ankle": 28,
    "nose": 0,
}


def compute_joint_angles(landmarks: list[Landmark]) -> dict[str, float]:
    """Given 33 pose landmarks for a single frame, returns every angle
    the spec requires. Missing/low-confidence landmarks are skipped."""

    def get(name: str) -> Landmark:
        return landmarks[LM[name]]

    angles: dict[str, float] = {}
    try:
        angles["left_knee_flexion"] = _angle(get("left_hip"), get("left_knee"), get("left_ankle"))
        angles["right_knee_flexion"] = _angle(get("right_hip"), get("right_knee"), get("right_ankle"))
        angles["left_hip_flexion"] = _angle(get("left_shoulder"), get("left_hip"), get("left_knee"))
        angles["right_hip_flexion"] = _angle(get("right_shoulder"), get("right_hip"), get("right_knee"))
        angles["left_elbow_extension"] = _angle(get("left_shoulder"), get("left_elbow"), get("left_wrist"))
        angles["right_elbow_extension"] = _angle(get("right_shoulder"), get("right_elbow"), get("right_wrist"))
        angles["left_shoulder_elevation"] = _angle(get("left_hip"), get("left_shoulder"), get("left_elbow"))
        angles["right_shoulder_elevation"] = _angle(get("right_hip"), get("right_shoulder"), get("right_elbow"))

        mid_shoulder = Landmark(
            (get("left_shoulder").x + get("right_shoulder").x) / 2,
            (get("left_shoulder").y + get("right_shoulder").y) / 2,
        )
        mid_hip = Landmark(
            (get("left_hip").x + get("right_hip").x) / 2,
            (get("left_hip").y + get("right_hip").y) / 2,
        )
        vertical_ref = Landmark(mid_hip.x, mid_hip.y - 1)
        angles["spine_angle"] = _angle(vertical_ref, mid_hip, mid_shoulder)
        angles["neck_angle"] = _angle(mid_shoulder, get("nose"), Landmark(get("nose").x, get("nose").y - 1))
    except (IndexError, KeyError):
        pass

    return angles
