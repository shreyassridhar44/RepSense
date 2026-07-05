"""Pose Estimation — wraps MediaPipe Pose.

Per the technical specification: "Don't use YOLO as the primary
movement-analysis model." This module implements the recommended
pipeline's first stage — pose estimation / body keypoints — using
MediaPipe Pose (mobile alternative: RTMPose / MoveNet Lightning, wired
up the same way client-side via ML Kit on-device).

Install: pip install mediapipe opencv-python-headless
"""
from __future__ import annotations
from app.ml.joint_angles import Landmark

try:
    import mediapipe as mp
except ImportError:  # pragma: no cover - optional heavy dependency
    mp = None


class PoseEstimator:
    def __init__(self) -> None:
        if mp is None:
            raise RuntimeError(
                "mediapipe is not installed. Run `pip install mediapipe opencv-python-headless`."
            )
        self._pose = mp.solutions.pose.Pose(
            static_image_mode=False,
            model_complexity=1,
            enable_segmentation=False,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5,
        )

    def estimate(self, frame_bgr) -> list[Landmark] | None:
        """Run pose estimation on a single BGR frame (numpy array).
        Returns 33 normalized landmarks, or None if no person detected."""
        import cv2

        rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
        result = self._pose.process(rgb)
        if not result.pose_landmarks:
            return None
        return [
            Landmark(lm.x, lm.y, lm.z, lm.visibility)
            for lm in result.pose_landmarks.landmark
        ]

    def close(self) -> None:
        self._pose.close()
