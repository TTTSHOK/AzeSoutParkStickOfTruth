#!/usr/bin/env python3
"""Build a translated OAF using the user's own original game files.

This project intentionally distributes no game archives or extracted English text.
"""
import argparse
import json
import struct
from pathlib import Path


def read_std(data):
    if len(data) < 14:
        raise ValueError("STD header is too short")
    count = struct.unpack_from("<I", data, 6)[0]
    table_end = 14 + count * 36
    if table_end > len(data):
        raise ValueError("STD record table is truncated")
    records = []
    for i in range(count):
        sid, chars, size, offset, extra = struct.unpack_from("<IQQQQ", data, 10 + i * 36)
        end = offset + size
        if offset < table_end or end >= len(data) or data[end] != 0:
            raise ValueError(f"Invalid STD string boundary at record {i}")
        value = data[offset:end].decode("utf-8")
        if len(value) != chars:
            raise ValueError(f"Character count mismatch for string {sid}")
        records.append((sid, value, extra, offset, end))
    return records


def patch_std(data, changes):
    records = read_std(data)
    table_end = 14 + len(records) * 36
    result = bytearray(data[:table_end])
    found = set()
    for i, (sid, old, extra, _offset, _end) in enumerate(records):
        value = changes.get(sid, old)
        found.add(sid)
        encoded = value.encode("utf-8")
        struct.pack_into("<IQQQQ", result, 10 + i * 36, sid, len(value), len(encoded), len(result), extra)
        result.extend(encoded + b"\0")
    if records:
        result.extend(data[records[-1][4] + 1 :])
    else:
        result.extend(data[table_end:])
    missing = set(changes) - found
    if missing:
        raise ValueError(f"Translation IDs not present in source STD: {sorted(missing)[:8]}")
    return bytes(result)


def build_oaf(archive, extracted_dir, translations):
    if archive[:4] != b"OAF!":
        raise ValueError("Input does not have an OAF header")
    count = struct.unpack_from("<I", archive, 20)[0]
    names_pos = struct.unpack_from("<Q", archive, 12)[0]
    if names_pos > len(archive) or 24 + 20 * count > len(archive):
        raise ValueError("Invalid OAF header offsets")
    names = archive[names_pos:].split(b"\0")[:count]
    if len(names) != count:
        raise ValueError("OAF filename table is incomplete")
    index = {n.decode("utf-8").replace("\\", "/").casefold(): i for i, n in enumerate(names)}
    by_file = {}
    for row in translations:
        key = str(row["file"]).replace("\\", "/").casefold()
        if key not in index:
            raise ValueError(f"STD not found in OAF: {row['file']}")
        sid = int(row["id"])
        if sid in by_file.setdefault(key, {}):
            raise ValueError(f"Duplicate translation ID: {row['file']} / {sid}")
        by_file[key][sid] = str(row["az"])

    output = bytearray(archive[: 24 + 20 * count])
    for i, raw_name in enumerate(names):
        entry = 24 + i * 20
        magic, offset, flag, size, packed = struct.unpack_from("<IIIII", archive, entry)
        if flag or packed:
            raise ValueError("Compressed OAF entries are unsupported")
        if offset + size > len(archive):
            raise ValueError("OAF entry extends beyond archive")
        payload = archive[offset : offset + size]
        name = raw_name.decode("utf-8")
        key = name.replace("\\", "/").casefold()
        changes = by_file.get(key)
        if changes:
            source = extracted_dir.joinpath(*name.replace("\\", "/").split("/"))
            if not source.is_file():
                raise FileNotFoundError(f"Extract the matching original STD first: {source}")
            original = source.read_bytes()
            if original != payload:
                raise ValueError(f"Extracted STD differs from supplied OAF: {name}")
            payload = patch_std(original, changes)
        output.extend(b"\0" * ((-len(output)) % 16))
        new_offset = len(output)
        output.extend(payload)
        struct.pack_into("<IIIII", output, entry, magic, new_offset, 0, len(payload), 0)
    output.extend(b"\0" * ((-len(output)) % 16))
    struct.pack_into("<Q", output, 12, len(output))
    output.extend(archive[names_pos:])
    return bytes(output)


def main():
    parser = argparse.ArgumentParser(description="Build Azerbaijani text from your own game files")
    parser.add_argument("--oaf", required=True, type=Path, help="Original English OAF from your installed game")
    parser.add_argument("--extracted", required=True, type=Path, help="Folder of matching extracted STD files")
    parser.add_argument("--translations", type=Path, default=Path(__file__).resolve().parents[1] / "translations/az.json")
    parser.add_argument("--output", type=Path, default=Path("data_localized_az.oaf"))
    args = parser.parse_args()
    rows = json.loads(args.translations.read_text(encoding="utf-8"))
    result = build_oaf(args.oaf.read_bytes(), args.extracted, rows)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(result)
    print(f"Created {args.output} from the supplied game files.")


if __name__ == "__main__":
    main()
