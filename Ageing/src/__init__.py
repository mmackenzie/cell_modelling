"""
Battery ageing package.

Provides:
- Data reading (RPT and profiles)
- Degradation physics models
- Degradation prediction engine
- Plotting utilities
"""

from .data_handler import DataReader
from .degradation_physics import DegradationPhysics
from .degradation_predictor import DegradationPredictor
from . import utils

__all__ = ["DataReader", "DegradationPhysics", "DegradationPredictor", "utils"]