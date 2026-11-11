#!/usr/bin/env python3
"""Build an inspectable regional OSM road-graph candidate from a PBF extract.

This is an offline preprocessing tool. Its output is not consumed by the game.
GDAL/OGR first selects regional way IDs and tags; this tool then reads the OSM
PBF directly to recover those ways' original node references and coordinates.
Review graph connectivity and truck-specific restrictions before route use.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import struct
import zlib
from collections import defaultdict
from pathlib import Path
from typing import Any

ROAD_CLASSES = {
    "motorway", "motorway_link", "trunk", "trunk_link", "primary",
    "primary_link", "secondary", "secondary_link", "tertiary", "tertiary_link",
    "unclassified", "residential", "living_street", "service",
}
EARTH_RADIUS_KM = 6371.0088
HSTORE_PAIR = re.compile(r'"((?:[^"\\]|\\.)*)"=>"((?:[^"\\]|\\.)*)"')

# Keep restriction tags in the candidate graph. A road blocked to one truck
# may remain usable by another vehicle, so access filtering belongs in routing.
PRESERVED_TAGS = (
    "access", "vehicle", "motor_vehicle", "motorcar", "goods", "hgv",
    "access:conditional", "vehicle:conditional", "motor_vehicle:conditional",
    "goods:conditional", "hgv:conditional",
    "maxweight", "maxweightrating", "maxweight:hgv", "maxweightrating:hgv",
    "maxheight", "maxwidth", "maxaxleload", "maxlength", "hgv_articulated",
    "hazmat", "hazmat:conditional", "surface", "smoothness", "maxspeed",
    "maxspeed:hgv",
)


def hstore_tags(value: str | None) -> dict[str, str]:
    """Decode the OSM driver's simple hstore representation."""
    if not value:
        return {}
    result: dict[str, str] = {}
    for key, item in HSTORE_PAIR.findall(value):
        try:
            result[json.loads(f'"{key}"')] = json.loads(f'"{item}"')
        except json.JSONDecodeError:
            continue
    return result


def oneway_value(tags: dict[str, str]) -> int:
    value = tags.get("oneway", "").lower()
    if value in {"yes", "1", "true"}:
        return 1
    if value == "-1":
        return -1
    if value == "no":
        return 0
    if tags.get("junction", "") == "roundabout":
        return 1
    return 0


def road_tags(feature: Any) -> dict[str, str] | None:
    properties = feature.get("properties", {})
    highway = str(properties.get("highway", "") or "")
    if highway not in ROAD_CLASSES:
        return None
    tags = hstore_tags(properties.get("other_tags"))
    name = str(properties.get("name", "") or "")
    if name:
        tags["name"] = name
    tags["highway"] = highway
    result = {
        "class": highway,
        "ref": tags.get("ref", ""),
        "name": tags.get("name", ""),
        "oneway": str(oneway_value(tags)),
        "surface": tags.get("surface", ""),
        "bridge": tags.get("bridge", ""),
        "tunnel": tags.get("tunnel", ""),
        "layer": tags.get("layer", "0"),
    }
    result.update({key: tags[key] for key in PRESERVED_TAGS if key in tags})
    return result


def feature_points(feature: Any) -> list[tuple[float, float]]:
    geometry = feature.get("geometry")
    if not geometry or geometry.get("type") != "LineString":
        return []
    return [(float(point[0]), float(point[1])) for point in geometry.get("coordinates", []) if len(point) >= 2]


def clip_segment(
    a: tuple[float, float], b: tuple[float, float],
    bounds: tuple[float, float, float, float],
) -> tuple[float, float, float, float] | None:
    """Clip one lon/lat segment to west,south,east,north using Liang-Barsky."""
    x0, y0 = a
    x1, y1 = b
    west, south, east, north = bounds
    dx, dy = x1 - x0, y1 - y0
    lower, upper = 0.0, 1.0
    for p, q in ((-dx, x0 - west), (dx, east - x0), (-dy, y0 - south), (dy, north - y0)):
        if abs(p) < 1e-15:
            if q < 0.0:
                return None
            continue
        ratio = q / p
        if p < 0.0:
            lower = max(lower, ratio)
        else:
            upper = min(upper, ratio)
        if lower > upper:
            return None
    return lower, upper, x0 + lower * dx, y0 + lower * dy


def clipped_endpoints(
    a: tuple[float, float], b: tuple[float, float],
    bounds: tuple[float, float, float, float],
) -> tuple[tuple[float, float, float, str], tuple[float, float, float, str]] | None:
    clipped = clip_segment(a, b, bounds)
    if clipped is None:
        return None
    lower, upper, _, _ = clipped
    x0, y0 = a
    x1, y1 = b
    dx, dy = x1 - x0, y1 - y0
    start_lon, start_lat = x0 + lower * dx, y0 + lower * dy
    end_lon, end_lat = x0 + upper * dx, y0 + upper * dy
    start_key = "" if lower > 1e-12 else "original"
    end_key = "" if upper < 1.0 - 1e-12 else "original"
    return (start_lon, start_lat, lower, start_key), (end_lon, end_lat, upper, end_key)


def haversine_km(a: tuple[float, float], b: tuple[float, float]) -> float:
    lon_a, lat_a = map(math.radians, a)
    lon_b, lat_b = map(math.radians, b)
    lat_delta, lon_delta = lat_b - lat_a, lon_b - lon_a
    value = math.sin(lat_delta / 2.0) ** 2 + math.cos(lat_a) * math.cos(lat_b) * math.sin(lon_delta / 2.0) ** 2
    return 2.0 * EARTH_RADIUS_KM * math.atan2(math.sqrt(value), math.sqrt(max(0.0, 1.0 - value)))


def open_roads(path: Path) -> list[dict[str, Any]]:
    try:
        collection = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise SystemExit(f"Could not read OGR-exported GeoJSON {path}: {exc}") from exc
    if collection.get("type") != "FeatureCollection":
        raise SystemExit("Input must be an OGR-exported GeoJSON FeatureCollection.")
    return collection.get("features", [])


def read_varint(data: memoryview, offset: int) -> tuple[int, int]:
    value = 0
    shift = 0
    while offset < len(data):
        byte = data[offset]
        offset += 1
        value |= (byte & 0x7F) << shift
        if byte < 0x80:
            return value, offset
        shift += 7
        if shift >= 70:
            break
    raise ValueError("Malformed or truncated PBF varint")


def iter_fields(data: bytes | memoryview):
    view = data if isinstance(data, memoryview) else memoryview(data)
    offset = 0
    while offset < len(view):
        key, offset = read_varint(view, offset)
        number, wire = key >> 3, key & 7
        if number == 0:
            raise ValueError("Invalid protobuf field number 0")
        if wire == 0:
            value, offset = read_varint(view, offset)
        elif wire == 1:
            end = offset + 8
            if end > len(view):
                raise ValueError("Truncated fixed64 protobuf field")
            value = view[offset:end]
            offset = end
        elif wire == 2:
            length, offset = read_varint(view, offset)
            end = offset + length
            if end > len(view):
                raise ValueError("Truncated length-delimited protobuf field")
            value = view[offset:end]
            offset = end
        elif wire == 5:
            end = offset + 4
            if end > len(view):
                raise ValueError("Truncated fixed32 protobuf field")
            value = view[offset:end]
            offset = end
        else:
            raise ValueError(f"Unsupported protobuf wire type {wire}")
        yield number, wire, value


def packed_varints(data: memoryview, *, signed: bool = False) -> list[int]:
    values: list[int] = []
    offset = 0
    while offset < len(data):
        value, offset = read_varint(data, offset)
        if signed:
            value = (value >> 1) ^ -(value & 1)
        values.append(value)
    return values


def signed_int64(value: int) -> int:
    return value - (1 << 64) if value >= (1 << 63) else value


def iter_pbf_data(path: Path):
    """Yield decompressed OSMData blocks from the PBF file framing."""
    with path.open("rb") as stream:
        while True:
            prefix = stream.read(4)
            if not prefix:
                return
            if len(prefix) != 4:
                raise ValueError("Truncated PBF block header length")
            header_length = struct.unpack(">I", prefix)[0]
            header = stream.read(header_length)
            if len(header) != header_length:
                raise ValueError("Truncated PBF block header")
            block_type = ""
            blob_size = 0
            for field, wire, value in iter_fields(header):
                if field == 1 and wire == 2:
                    block_type = bytes(value).decode("utf-8")
                elif field == 3 and wire == 0:
                    blob_size = int(value)
            blob = stream.read(blob_size)
            if len(blob) != blob_size:
                raise ValueError("Truncated PBF data block")
            if block_type != "OSMData":
                continue
            raw: bytes | None = None
            compressed: bytes | None = None
            raw_size = 0
            for field, wire, value in iter_fields(blob):
                if field == 1 and wire == 2:
                    raw = bytes(value)
                elif field == 2 and wire == 0:
                    raw_size = int(value)
                elif field == 3 and wire == 2:
                    compressed = bytes(value)
            if raw is None:
                if compressed is None:
                    raise ValueError("PBF OSMData block uses an unsupported compression format")
                raw = zlib.decompress(compressed)
            if raw_size and len(raw) != raw_size:
                raise ValueError("PBF block decompressed to an unexpected size")
            yield raw


def primitive_groups(block: bytes):
    granularity = 100
    lat_offset = 0
    lon_offset = 0
    groups: list[memoryview] = []
    for field, wire, value in iter_fields(block):
        if field == 2 and wire == 2:
            groups.append(value)
        elif field == 17 and wire == 0:
            granularity = int(value)
        elif field == 19 and wire == 0:
            lat_offset = signed_int64(int(value))
        elif field == 20 and wire == 0:
            lon_offset = signed_int64(int(value))
    return groups, granularity, lat_offset, lon_offset


def way_id_and_refs(data: memoryview) -> tuple[int | None, list[int]]:
    way_id: int | None = None
    refs_delta: list[int] = []
    for field, wire, value in iter_fields(data):
        if field == 1 and wire == 0:
            way_id = int(value)
        elif field == 8 and wire == 2:
            refs_delta.extend(packed_varints(value, signed=True))
    refs: list[int] = []
    current = 0
    for delta in refs_delta:
        current += delta
        refs.append(current)
    return way_id, refs


def collect_selected_ways(pbf_path: Path, selected_tags: dict[int, dict[str, str]]) -> dict[int, tuple[dict[str, str], list[int]]]:
    ways: dict[int, tuple[dict[str, str], list[int]]] = {}
    print("Pass 1/2: recovering original OSM way node references...", flush=True)
    for block in iter_pbf_data(pbf_path):
        groups, _, _, _ = primitive_groups(block)
        for group in groups:
            for field, wire, value in iter_fields(group):
                if field != 3 or wire != 2:
                    continue
                way_id, refs = way_id_and_refs(value)
                if way_id in selected_tags:
                    ways[way_id] = (selected_tags[way_id], refs)
    return ways


def collect_node_locations(pbf_path: Path, wanted: set[int]) -> dict[int, tuple[float, float]]:
    locations: dict[int, tuple[float, float]] = {}
    print(f"Pass 2/2: resolving coordinates for {len(wanted):,} referenced OSM nodes...", flush=True)
    for block in iter_pbf_data(pbf_path):
        groups, granularity, lat_offset, lon_offset = primitive_groups(block)
        scale = 1e-9
        for group in groups:
            for field, wire, value in iter_fields(group):
                if field == 1 and wire == 2:  # ordinary Node
                    node_id = None
                    lat = None
                    lon = None
                    for node_field, node_wire, node_value in iter_fields(value):
                        if node_wire != 0:
                            continue
                        raw = int(node_value)
                        decoded = (raw >> 1) ^ -(raw & 1)
                        if node_field == 1:
                            node_id = decoded
                        elif node_field == 8:
                            lat = decoded
                        elif node_field == 9:
                            lon = decoded
                    if node_id in wanted and lat is not None and lon is not None:
                        locations[node_id] = ((lon_offset + granularity * lon) * scale, (lat_offset + granularity * lat) * scale)
                elif field == 2 and wire == 2:  # DenseNodes
                    deltas: dict[int, list[int]] = {1: [], 8: [], 9: []}
                    for dense_field, dense_wire, dense_value in iter_fields(value):
                        if dense_field in deltas and dense_wire == 2:
                            deltas[dense_field].extend(packed_varints(dense_value, signed=True))
                    ids, latitudes, longitudes = (deltas[number] for number in (1, 8, 9))
                    if not (len(ids) == len(latitudes) == len(longitudes)):
                        raise ValueError("Malformed DenseNodes: ID/latitude/longitude counts differ")
                    node_id = lat = lon = 0
                    for id_delta, lat_delta, lon_delta in zip(ids, latitudes, longitudes):
                        node_id += id_delta
                        lat += lat_delta
                        lon += lon_delta
                        if node_id in wanted:
                            locations[node_id] = ((lon_offset + granularity * lon) * scale, (lat_offset + granularity * lat) * scale)
        if len(locations) == len(wanted):
            break
    return locations


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input_pbf", type=Path, help="OSM PBF extract containing selected ways and nodes")
    parser.add_argument("source_features", type=Path, help="GDAL/OGR-exported regional road FeatureCollection")
    parser.add_argument("output", type=Path, help="Output compact JSON graph candidate")
    parser.add_argument("--bounds", nargs=4, type=float, metavar=("WEST", "SOUTH", "EAST", "NORTH"), default=(18.0, -34.5, 19.3, -33.3), help="WGS84 box; defaults to greater Cape Town")
    parser.add_argument("--source-snapshot", default="unspecified", help="Date/time label recorded in output metadata")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    bounds = tuple(args.bounds)
    if not args.input_pbf.is_file():
        raise SystemExit(f"Input PBF not found: {args.input_pbf}")
    if not args.source_features.is_file():
        raise SystemExit(f"OGR road-feature GeoJSON not found: {args.source_features}")
    west, south, east, north = bounds
    if west >= east or south >= north:
        raise SystemExit("Bounds must be ordered west < east and south < north")

    selected_tags: dict[int, dict[str, str]] = {}
    for feature in open_roads(args.source_features):
        tags = road_tags(feature)
        points = feature_points(feature)
        if not tags or len(points) < 2 or not any(clip_segment(a, b, bounds) is not None for a, b in zip(points, points[1:])):
            continue
        try:
            way_id = int(feature.get("properties", {}).get("osm_id"))
        except (TypeError, ValueError):
            continue
        selected_tags[way_id] = tags

    selected_ways = collect_selected_ways(args.input_pbf, selected_tags)
    wanted_nodes = {node_id for _, refs in selected_ways.values() for node_id in refs}
    node_locations = collect_node_locations(args.input_pbf, wanted_nodes)
    junction_uses: defaultdict[int, int] = defaultdict(int)
    usable_ways: dict[int, tuple[dict[str, str], list[int]]] = {}
    missing_node_refs = 0
    for way_id, (tags, refs) in selected_ways.items():
        absent = [node_id for node_id in refs if node_id not in node_locations]
        if absent:
            missing_node_refs += len(absent)
            continue
        points = [(node_id, *node_locations[node_id]) for node_id in refs]
        if not any(clip_segment((a[1], a[2]), (b[1], b[2]), bounds) is not None for a, b in zip(points, points[1:])):
            continue
        usable_ways[way_id] = (tags, refs)
        for node_id in set(refs):
            junction_uses[node_id] += 1

    print("Writing edges using original OSM node references...", flush=True)
    nodes: dict[str, dict[str, float | str]] = {}
    edges: list[dict[str, Any]] = []
    ways_written = 0
    for way_id, (tags, refs) in usable_ways.items():
        points = [(node_id, *node_locations[node_id]) for node_id in refs]
        path: list[tuple[str, float, float]] = []
        segment_number = 0

        def flush() -> None:
            nonlocal path, segment_number
            if len(path) >= 2:
                start_id, end_id = path[0][0], path[-1][0]
                distance = sum(haversine_km((left[1], left[2]), (right[1], right[2])) for left, right in zip(path, path[1:]))
                if distance > 0.0:
                    for node_id, lon, lat in (path[0], path[-1]):
                        nodes[node_id] = {"lon": lon, "lat": lat}
                    edges.append({
                        "id": f"{way_id}:{segment_number}", "from": start_id, "to": end_id,
                        **tags, "distance_km": round(distance, 4),
                        "geometry": [[round(lon, 7), round(lat, 7)] for _, lon, lat in path],
                    })
                    segment_number += 1
            path = []

        for index, (a, b) in enumerate(zip(points, points[1:])):
            clipped = clipped_endpoints((a[1], a[2]), (b[1], b[2]), bounds)
            if clipped is None:
                flush()
                continue
            start, end = clipped
            start_original = start[3] == "original"
            end_original = end[3] == "original"
            start_id = f"osm_node:{a[0]}" if start_original else f"clip:{way_id}:{index}:start"
            end_id = f"osm_node:{b[0]}" if end_original else f"clip:{way_id}:{index}:end"
            if start_original and junction_uses.get(start_id, 0) > 1:
                flush()
            if path and path[-1][0] != start_id:
                flush()
            if not path:
                path.append((start_id, start[0], start[1]))
            if path[-1][0] != end_id:
                path.append((end_id, end[0], end[1]))
            if end_original and junction_uses.get(end_id, 0) > 1:
                flush()
        flush()
        if segment_number:
            ways_written += 1

    payload = {
        "metadata": {
            "source": "OpenStreetMap via Geofabrik South Africa extract",
            "source_snapshot": args.source_snapshot,
            "license": "ODbL-1.0",
            "attribution": "© OpenStreetMap contributors",
            "attribution_url": "https://www.openstreetmap.org/copyright",
            "bounds_wgs84": list(bounds),
            "included_highway_classes": sorted(ROAD_CLASSES),
            "access_filter": "No access values are filtered during graph building; restrictions are retained for profile-specific routing.",
            "preserved_restriction_tags": list(PRESERVED_TAGS),
            "connectivity_method": "Original OSM way refs and node IDs read directly from the source PBF; GDAL/OGR is used only to select regional way IDs and tags.",
            "missing_node_reference_count": missing_node_refs,
            "limitations": [
                "Candidate road geometry only; connectivity has not been validated for truck routing.",
                "The QA evaluator handles a limited set of explicit vehicle/goods/HGV/hazmat restrictions; conditional access, turn restrictions, numeric truck limits, and legal defaults are not modelled.",
                "Map clipping creates unconnected endpoints at the regional boundary.",
                "Do not derive gameplay distances or contract values until graph QA is complete.",
            ],
        },
        "nodes": [{"id": node_id, **values} for node_id, values in sorted(nodes.items())],
        "edges": edges,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, separators=(",", ":"), ensure_ascii=False) + "\n", encoding="utf-8")
    size_mb = args.output.stat().st_size / (1024 * 1024)
    print(
        f"Wrote {len(nodes):,} graph nodes and {len(edges):,} edges "
        f"from {ways_written:,}/{len(selected_ways):,} selected road ways "
        f"({size_mb:.2f} MiB; missing node refs: {missing_node_refs:,}): {args.output}",
        flush=True,
    )
    print("This candidate is not wired into the game; review connectivity, restrictions, size, and Android load performance first.")


if __name__ == "__main__":
    main()
