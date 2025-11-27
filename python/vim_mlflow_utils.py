import math


def format_run_duration(total_seconds):
    """Format a run duration in seconds using s/m/h units."""
    if total_seconds is None:
        return "-"
    if isinstance(total_seconds, float) and math.isnan(total_seconds):
        return "-"
    if total_seconds < 0:
        return "-"
    if total_seconds < 300:
        return f"{int(total_seconds)}s"
    if total_seconds < 7200:
        return f"{int(total_seconds // 60)}m"
    hours = total_seconds / 3600.0
    return f"{hours:.1f}h"
