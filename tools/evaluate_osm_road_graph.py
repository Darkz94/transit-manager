#!/usr/bin/env python3
"""Report connectivity and truck-profile routes for a candidate graph.

The route probe tries several nearby road edges per anchor, respecting one-way
and a deliberately limited set of explicit vehicle access tags. It is a
preprocessing QA aid, not gameplay routing or a legal route planner.
"""

from __future__ import annotations

import argparse
import heapq
import json
import math
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

EARTH_RADIUS_KM = 6371.0088

# These are game category labels matching scripts/operations.gd, not real
# vehicle specifications or statutory classifications.
VEHICLES = {
    "van": {"hgv": False, "hazmat": False, "cargo": {"parcels", "dry"}},
    "electric_van": {"hgv": False, "hazmat": False, "cargo": {"parcels", "dry"}},
    "rigid": {"hgv": True, "hazmat": False, "cargo": {"dry", "building"}},
    "reefer": {"hgv": True, "hazmat": False, "cargo": {"produce", "dry"}},
    "prime_mover": {"hgv": True, "hazmat": False, "cargo": {"dry", "building", "machinery"}},
    "safechem_rigid": {"hgv": True, "hazmat": True, "cargo": {"dry", "hazmat"}},
    "capebulk_tipper": {"hgv": True, "hazmat": False, "cargo": {"granular", "building"}},
}

ACCESS_KEYS = ("access", "vehicle", "motor_vehicle", "goods", "hgv")
DENIED_ACCESS = {"no", "private", "destination", "delivery"}
ROAD_CLASS_PRESETS = {
    "all": None,
    "arterial_network": {
        "motorway", "motorway_link", "trunk", "trunk_link", "primary", "primary_link",
        "secondary", "secondary_link", "tertiary", "tertiary_link",
    },
    "major_truck_routes": {
        "motorway", "motorway_link", "trunk", "trunk_link", "primary", "primary_link",
        "secondary", "secondary_link",
    },
}


def edge_allowed(edge: dict[str, Any], vehicle: dict[str, Any], cargo_id: str) -> bool:
    effective = ""
    for key in ACCESS_KEYS:
        # Every Transit Manager vehicle carries goods; only HGV-specific
        # restrictions are inapplicable to the game's van categories.
        if key == "hgv" and not vehicle["hgv"]:
            continue
        value = str(edge.get(key, "")).strip().lower()
        if value:
            effective = value
    if effective in DENIED_ACCESS:
        return False
    if cargo_id == "hazmat" and str(edge.get("hazmat", "")).strip().lower() in DENIED_ACCESS:
        return False
    return True


def restriction_counts(edges: list[dict[str, Any]]) -> dict[str, int]:
    numeric = ("maxweight", "maxweightrating", "maxweight:hgv", "maxweightrating:hgv",
               "maxheight", "maxwidth", "maxaxleload", "maxlength")
    return {
        "hgv_no_edges": sum(str(e.get("hgv", "")).lower() in {"no", "private"} for e in edges),
        "goods_no_edges": sum(str(e.get("goods", "")).lower() in {"no", "private"} for e in edges),
        "hazmat_no_edges": sum(str(e.get("hazmat", "")).lower() in {"no", "private"} for e in edges),
        "edges_with_numeric_vehicle_limits": sum(any(e.get(k) for k in numeric) for e in edges),
        "edges_with_conditional_access": sum(any(e.get(k) for k in ("access:conditional", "vehicle:conditional", "motor_vehicle:conditional", "goods:conditional", "hgv:conditional", "hazmat:conditional")) for e in edges),
    }


def haversine(a: tuple[float, float], b: tuple[float, float]) -> float:
    lon_a, lat_a = map(math.radians, a)
    lon_b, lat_b = map(math.radians, b)
    dlat, dlon = lat_b - lat_a, lon_b - lon_a
    value = math.sin(dlat / 2) ** 2 + math.cos(lat_a) * math.cos(lat_b) * math.sin(dlon / 2) ** 2
    return 2 * EARTH_RADIUS_KM * math.asin(math.sqrt(value))


def components(nodes: dict[str, Any], edges: list[dict[str, Any]]) -> tuple[Counter[str], dict[str, str]]:
    parent = {node_id: node_id for node_id in nodes}

    def find(node_id: str) -> str:
        while parent[node_id] != node_id:
            parent[node_id] = parent[parent[node_id]]
            node_id = parent[node_id]
        return node_id

    for edge in edges:
        a, b = find(edge["from"]), find(edge["to"])
        if a != b:
            parent[b] = a
    groups = Counter(find(node_id) for node_id in nodes)
    return groups, {node_id: find(node_id) for node_id in nodes}


def nearest_candidates(
    place: dict[str, Any], edges: list[dict[str, Any]], edge_roots: list[str], largest_root: str,
    limit: int, radius_km: float,
) -> list[tuple[int, float, float]]:
    lon, lat = float(place["lon"]), float(place["lat"])
    latitude_scale = math.cos(math.radians(lat))
    nearest_by_edge: dict[int, tuple[float, float]] = {}
    for edge_index, edge in enumerate(edges):
        if edge_roots[edge_index] != largest_root:
            continue
        points = edge.get("geometry", [])
        if len(points) < 2:
            continue
        if (max(point[0] for point in points) < lon - radius_km / 90
                or min(point[0] for point in points) > lon + radius_km / 90
                or max(point[1] for point in points) < lat - radius_km / 90
                or min(point[1] for point in points) > lat + radius_km / 90):
            continue
        lengths = [haversine(tuple(a[:2]), tuple(b[:2])) for a, b in zip(points, points[1:])]
        total_length = sum(lengths)
        distance_before = 0.0
        for index, (a, b) in enumerate(zip(points, points[1:])):
            ax, ay = (a[0] - lon) * latitude_scale, a[1] - lat
            bx, by = (b[0] - lon) * latitude_scale, b[1] - lat
            dx, dy = bx - ax, by - ay
            denominator = dx * dx + dy * dy
            along = max(0.0, min(1.0, -(ax * dx + ay * dy) / denominator)) if denominator else 0.0
            offset = 111.195 * math.hypot(ax + along * dx, ay + along * dy)
            fraction = (distance_before + along * lengths[index]) / total_length if total_length else 0.0
            current = nearest_by_edge.get(edge_index)
            if current is None or offset < current[0]:
                nearest_by_edge[edge_index] = (offset, fraction)
            distance_before += lengths[index]
    candidates = [(edge_index, offset, fraction) for edge_index, (offset, fraction) in nearest_by_edge.items() if offset <= radius_km]
    return sorted(candidates, key=lambda item: item[1])[:limit]


def evaluate(graph_path: Path, places_paths: list[Path], origin_id: str, limit: int, radius_km: float, vehicle_id: str, cargo_id: str, road_class_set: str) -> dict[str, Any]:
    graph = json.loads(graph_path.read_text(encoding="utf-8"))
    places = []
    for places_path in places_paths:
        places.extend(json.loads(places_path.read_text(encoding="utf-8")))
    nodes = {item["id"]: item for item in graph["nodes"]}
    all_edges = graph["edges"]
    vehicle = VEHICLES[vehicle_id]
    if cargo_id not in vehicle["cargo"]:
        raise SystemExit(f"{vehicle_id} is not configured to carry {cargo_id} in the game fleet data.")
    selected_classes = ROAD_CLASS_PRESETS[road_class_set]
    edges = [edge for edge in all_edges
             if (selected_classes is None or edge.get("class") in selected_classes)
             and edge_allowed(edge, vehicle, cargo_id)]
    if not edges:
        raise SystemExit("No road edges remain for this vehicle and cargo profile.")
    active_nodes = {edge[endpoint] for edge in edges for endpoint in ("from", "to")}
    group_sizes, node_roots = components({node_id: nodes[node_id] for node_id in active_nodes}, edges)
    if not group_sizes:
        raise SystemExit("Graph contains no nodes.")
    largest_root = max(group_sizes, key=group_sizes.get)
    edge_roots = [node_roots[edge["from"]] for edge in edges]
    places_by_id = {place["id"]: place for place in places}
    if origin_id not in places_by_id:
        raise SystemExit(f"Origin place ID not found: {origin_id}")
    eligible_places = [
        place for place in places
        if graph["metadata"]["bounds_wgs84"][0] <= place["lon"] <= graph["metadata"]["bounds_wgs84"][2]
        and graph["metadata"]["bounds_wgs84"][1] <= place["lat"] <= graph["metadata"]["bounds_wgs84"][3]
    ]
    candidates = {
        place["id"]: nearest_candidates(place, edges, edge_roots, largest_root, limit, radius_km)
        for place in eligible_places
    }

    edge_splits: dict[int, list[tuple[float, str, int, float]]] = defaultdict(list)
    for place_id, selected in candidates.items():
        for candidate_index, (edge_index, offset, fraction) in enumerate(selected):
            edge_splits[edge_index].append((fraction, place_id, candidate_index, offset))
    place_nodes: dict[str, list[tuple[str, float]]] = {place_id: [] for place_id in candidates}
    adjacency: defaultdict[str, list[tuple[str, float]]] = defaultdict(list)

    for edge_index, edge in enumerate(edges):
        chain: list[tuple[float, str]] = [(0.0, edge["from"])]
        grouped: dict[float, list[tuple[str, int, float]]] = defaultdict(list)
        for fraction, place_id, candidate_index, offset in edge_splits.get(edge_index, []):
            grouped[round(fraction, 9)].append((place_id, candidate_index, offset))
        for fraction in sorted(grouped):
            virtual_node = edge["from"] if fraction <= 1e-9 else edge["to"] if fraction >= 1 - 1e-9 else f"snap:{edge_index}:{fraction:.9f}"
            if virtual_node not in (edge["from"], edge["to"]):
                chain.append((fraction, virtual_node))
            for place_id, _, offset in grouped[fraction]:
                place_nodes[place_id].append((virtual_node, offset))
        chain.append((1.0, edge["to"]))
        direction = int(edge.get("oneway", 0))
        for (start_fraction, start_node), (end_fraction, end_node) in zip(chain, chain[1:]):
            if start_node == end_node:
                continue
            length = (end_fraction - start_fraction) * float(edge["distance_km"])
            if direction in (0, 1):
                adjacency[start_node].append((end_node, length))
            if direction in (0, -1):
                adjacency[end_node].append((start_node, length))

    origin_nodes = place_nodes.get(origin_id, [])
    distances: dict[str, float] = {}
    queue: list[tuple[float, str]] = []
    for node_id, offset in origin_nodes:
        if offset < distances.get(node_id, math.inf):
            distances[node_id] = offset
            heapq.heappush(queue, (offset, node_id))
    while queue:
        distance, node_id = heapq.heappop(queue)
        if distance != distances[node_id]:
            continue
        for next_node, edge_length in adjacency[node_id]:
            candidate_distance = distance + edge_length
            if candidate_distance < distances.get(next_node, math.inf):
                distances[next_node] = candidate_distance
                heapq.heappush(queue, (candidate_distance, next_node))

    route_results = []
    for place in eligible_places:
        routes = [distances[node_id] + offset for node_id, offset in place_nodes[place["id"]] if node_id in distances]
        route_results.append({
            "place_id": place["id"],
            "name": place["name"],
            "candidate_edges_within_snap_radius": len(candidates[place["id"]]),
            "nearest_edge_snap_km": round(min((offset for _, offset in place_nodes[place["id"]]), default=math.inf), 3),
            "route_from_origin_km": round(min(routes), 2) if routes else None,
        })
    return {
        "graph": str(graph_path),
        "origin_id": origin_id,
        "origin_name": places_by_id[origin_id]["name"],
        "vehicle_profile": vehicle_id,
        "cargo_profile": cargo_id,
        "road_class_set": road_class_set,
        "included_road_classes": sorted(selected_classes) if selected_classes is not None else sorted({str(edge.get("class", "")) for edge in all_edges}),
        "vehicle_profile_note": "Game category only; not a measured vehicle specification or statutory classification.",
        "weak_component_count": len(group_sizes),
        "largest_weak_component_nodes": group_sizes[largest_root],
        "largest_weak_component_share": round(group_sizes[largest_root] / len(active_nodes), 4),
        "node_count": len(nodes),
        "active_node_count": len(active_nodes),
        "edge_count": len(all_edges),
        "eligible_edge_count": len(edges),
        "restriction_tag_counts": restriction_counts(all_edges),
        "max_snap_radius_km": radius_km,
        "nearby_edges_per_place": limit,
        "routes": route_results,
        "limitations": [
            "QA only: explicit generic access, goods/HGV, and generic hazmat restrictions are applied; conditionals, category-specific hazmat, numeric dimensions/weights, and turn restrictions are not evaluated.",
            "Destination/delivery-only roads are conservatively excluded; local access exceptions are not modeled.",
            "Vehicle profiles are game categories only; numeric truck dimensions and weights must be designed before those limits can be evaluated.",
            "Places are demo anchors; routes may use any of the nearby road snaps within the configured radius.",
            "Distances use candidate graph edge lengths and straight-line snap offsets; not real-world travel estimates.",
        ],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("graph", type=Path, help="Candidate graph JSON")
    parser.add_argument("places", type=Path, nargs="+", help="One or more place-array JSON files")
    parser.add_argument("--origin-id", default="cape-town-terminal")
    parser.add_argument("--nearby-edges", type=int, default=8, help="Try this many nearest distinct edges for each place")
    parser.add_argument("--snap-radius-km", type=float, default=1.0)
    parser.add_argument("--vehicle-id", choices=sorted(VEHICLES), default="rigid", help="Game vehicle category used for access filtering")
    parser.add_argument("--cargo-id", choices=sorted({cargo for item in VEHICLES.values() for cargo in item["cargo"]}), default="dry")
    parser.add_argument("--road-class-set", choices=sorted(ROAD_CLASS_PRESETS), default="all", help="Compare the full candidate or a selected road-class preset")
    parser.add_argument("--report", type=Path, help="Optional JSON report output")
    args = parser.parse_args()
    if args.nearby_edges < 1 or args.snap_radius_km <= 0:
        raise SystemExit("--nearby-edges and --snap-radius-km must be positive")
    result = evaluate(args.graph, args.places, args.origin_id, args.nearby_edges, args.snap_radius_km, args.vehicle_id, args.cargo_id, args.road_class_set)
    output = json.dumps(result, indent=2, ensure_ascii=False) + "\n"
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(output, encoding="utf-8")
    print(f"{result['graph']}: {result['largest_weak_component_nodes']:,}/{result['active_node_count']:,} active nodes in largest weak component ({result['largest_weak_component_share']:.1%})")
    for route in result["routes"]:
        distance = "unreachable" if route["route_from_origin_km"] is None else f"{route['route_from_origin_km']:.1f} km"
        print(f"{route['name']}: snap {route['nearest_edge_snap_km']:.2f} km; {distance}")
    print(f"Profile: {args.vehicle_id} carrying {args.cargo_id}; road classes: {args.road_class_set}; numeric limits and conditional access are not evaluated.")
    print("QA only: verify turn rules, truck specifications, and actual terminal access before using route distances.")


if __name__ == "__main__":
    main()
