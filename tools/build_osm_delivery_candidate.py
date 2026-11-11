#!/usr/bin/env python3
"""Build a regional truck-delivery candidate from a processed OSM graph.

Retains the arterial network and local roads close to supplied terminal and
district anchors. The output is for offline QA only; it is not game routing.
"""

from __future__ import annotations

import argparse
import gzip
import json
import math
from pathlib import Path
from typing import Any

ARTERIAL_CLASSES = {
    "motorway", "motorway_link", "trunk", "trunk_link", "primary", "primary_link",
    "secondary", "secondary_link", "tertiary", "tertiary_link",
}
LOCAL_CLASSES = {"unclassified", "residential", "living_street", "service"}


def distance_to_segment_km(point: tuple[float, float], a: tuple[float, float], b: tuple[float, float]) -> float:
    """Local equirectangular point-to-segment distance, suitable for metro buffers."""
    latitude_scale = math.cos(math.radians(point[1]))
    ax, ay = (a[0] - point[0]) * latitude_scale, a[1] - point[1]
    bx, by = (b[0] - point[0]) * latitude_scale, b[1] - point[1]
    dx, dy = bx - ax, by - ay
    denominator = dx * dx + dy * dy
    fraction = max(0.0, min(1.0, -(ax * dx + ay * dy) / denominator)) if denominator else 0.0
    return 111.195 * math.hypot(ax + fraction * dx, ay + fraction * dy)


def edge_near_anchor(edge: dict[str, Any], anchor: tuple[float, float], radius_km: float) -> bool:
    points = edge.get("geometry", [])
    if len(points) < 2:
        return False
    lon, lat = anchor
    if (max(point[0] for point in points) < lon - radius_km / 80
            or min(point[0] for point in points) > lon + radius_km / 80
            or max(point[1] for point in points) < lat - radius_km / 100
            or min(point[1] for point in points) > lat + radius_km / 100):
        return False
    return any(distance_to_segment_km(anchor, tuple(a[:2]), tuple(b[:2])) <= radius_km
               for a, b in zip(points, points[1:]))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("graph", type=Path, help="Processed regional OSM graph JSON")
    parser.add_argument("output", type=Path, help="Filtered delivery-candidate graph JSON")
    parser.add_argument("anchors", type=Path, nargs="+", help="Anchor-array JSON files (terminals and districts)")
    parser.add_argument("--local-access-radius-km", type=float, default=1.0,
                        help="Keep residential/unclassified/living-street edges this close to any anchor")
    args = parser.parse_args()
    if args.local_access_radius_km <= 0:
        raise SystemExit("--local-access-radius-km must be positive")

    source = json.loads(args.graph.read_text(encoding="utf-8"))
    anchors = [place for path in args.anchors for place in json.loads(path.read_text(encoding="utf-8"))]
    bounds = source["metadata"]["bounds_wgs84"]
    anchors = [p for p in anchors if bounds[0] <= p["lon"] <= bounds[2] and bounds[1] <= p["lat"] <= bounds[3]]
    if not anchors:
        raise SystemExit("No anchors fall within the source graph bounds.")

    selected_edges = []
    class_counts: dict[str, int] = {}
    for edge in source["edges"]:
        road_class = str(edge.get("class", ""))
        keep = road_class in ARTERIAL_CLASSES
        if road_class in LOCAL_CLASSES:
            keep = any(edge_near_anchor(edge, (float(p["lon"]), float(p["lat"])), args.local_access_radius_km)
                       for p in anchors)
        if keep:
            selected_edges.append(edge)
            class_counts[road_class] = class_counts.get(road_class, 0) + 1

    used_node_ids = {edge[endpoint] for edge in selected_edges for endpoint in ("from", "to")}
    source_nodes = {node["id"]: node for node in source["nodes"]}
    result = {
        "metadata": {
            **source["metadata"],
            "candidate_type": "arterial network plus local roads near demo anchors",
            "local_access_radius_km": args.local_access_radius_km,
            "anchor_ids": [p["id"] for p in anchors],
            "selected_edge_count_by_class": dict(sorted(class_counts.items())),
            "source_graph": str(args.graph),
            "limitations": list(source["metadata"].get("limitations", [])) + [
                "Local access selection is a geometric buffer around demo anchors, not a navigable address-level road catalogue.",
                "This filtered candidate is for QA only and is not loaded by gameplay.",
            ],
        },
        "nodes": [source_nodes[node_id] for node_id in sorted(used_node_ids)],
        "edges": selected_edges,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(result, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    args.output.write_bytes(encoded + b"\n")
    gzip_bytes = len(gzip.compress(encoded, compresslevel=9))
    print(f"Wrote {len(used_node_ids):,} nodes and {len(selected_edges):,} edges to {args.output}")
    print(f"Selected edge classes: {class_counts}")
    print(f"JSON {len(encoded) / 1048576:.2f} MiB; gzip {gzip_bytes / 1048576:.2f} MiB")
    print("Offline QA candidate only; not connected to gameplay.")


if __name__ == "__main__":
    main()
