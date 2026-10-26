#!/usr/bin/env python3
"""App Store Connect listing text, kept as files in git and pushed through Apple's API.

    python3 appstore/push.py check                             # the credentials work, and each app's Apple ID
    python3 appstore/push.py validate                          # every app's text against Apple's limits; no network
    python3 appstore/push.py push --app double-putt --dry-run   # what would change, field by field
    python3 appstore/push.py push --app double-putt             # push it (only the fields that differ)
    python3 appstore/push.py push --app double-putt --only promotional_text,description
    python3 appstore/push.py testflight --app double-putt --dry-run    # TestFlight's test information and groups
    python3 appstore/push.py testflight --app double-putt --build 1 --dry-run           # and build 1's What to Test
    python3 appstore/push.py testflight --app double-putt --build 1 --submit --dry-run  # to Friends, beta review
    python3 appstore/push.py testflight --app double-putt --invite EMAIL --dry-run      # a tester, to Friends
    python3 appstore/push.py media --app double-putt --screenshots DIR [DIR ...] --creative FILE --dry-run

The text lives in appstore/<app>/app/<locale>/<field>.txt, TestFlight's in appstore/<app>/testflight/, and any in-app
purchase's display name and description in appstore/<app>/iap/<folder>/<locale>/. A push writes to the version that's still editable (Prepare for Submission and
the like), so nothing goes public until that version is submitted and released.

Credentials come from the 1Password Environment "App Store Connect", mounted at ~/.appstoreconnect/.env (another path
with ASCC_ENV_FILE), or from the process environment: ASCC_KEY_ID, ASCC_ISSUER_ID, ASCC_PRIVATE_KEY (the contents of the
.p8), and ASCC_APP_ID_<APP> (each app's numeric Apple ID). Nothing secret is written to disk or printed. Talking to the
API needs the cryptography package (python3 -m pip install --user cryptography); validate needs nothing.

Copied from Bigger Fish's appstore/push.py (adapted from a friend's App Store listing kit), with `testflight` added.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import re
import struct
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
API = "https://api.appstoreconnect.apple.com"

# Each app: where its Apple ID comes from, and its in-app purchases (folder under iap/ -> product ID).
APPS = {
    "double-putt": {"app_id_env": "ASCC_APP_ID_DOUBLE_PUTT", "iap": {}},
}

# How `purchase` sets up each in-app purchase, by product ID. The product ID is permanent once created, and Family
# Sharing can't be turned off once it's on. The price is in US dollars, the base territory; Apple sets the others.
# Double Putt has none yet.
PURCHASE_SETUP: dict[str, dict] = {}

# Listing fields: file name -> (where App Store Connect keeps it, its attribute, character limit). Version
# localizations hold what can change with each version; app info localizations hold the name and subtitle.
FIELDS = {
    "name": ("info", "name", 30),
    "subtitle": ("info", "subtitle", 30),
    "privacy_policy_url": ("info", "privacyPolicyUrl", 255),
    "promotional_text": ("version", "promotionalText", 170),
    "description": ("version", "description", 4000),
    "keywords": ("version", "keywords", 100),
    "release_notes": ("version", "whatsNew", 4000),
    "support_url": ("version", "supportUrl", 255),
    "marketing_url": ("version", "marketingUrl", 255),
}
REQUIRED = ["name", "subtitle", "description", "keywords", "support_url", "privacy_policy_url"]
IAP_LIMITS = {"name": 30, "description": 45}
# An app's first version has no What's New, so release_notes.txt is left out until there's a second.
EDITABLE_STATES = {"PREPARE_FOR_SUBMISSION", "READY_FOR_REVIEW", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED",
                   "WAITING_FOR_REVIEW", "INVALID_BINARY"}
# A version in a draft submission (Ready for Review) keeps its text editable but not its images and videos.
MEDIA_EDITABLE_STATES = EDITABLE_STATES - {"READY_FOR_REVIEW"}


# --------------------------------------------------------------------------------------------------------------------
# The files

def read(path: Path) -> str | None:
    """A field's text, without the file's final newline."""
    if not path.exists():
        return None
    text = path.read_text(encoding="utf-8")
    return text[:-1] if text.endswith("\n") else text


def locales(app: str) -> list[str]:
    folder = HERE / app / "app"
    return sorted(p.name for p in folder.iterdir() if p.is_dir()) if folder.exists() else []


def listing(app: str, locale: str) -> dict[str, str]:
    base = HERE / app / "app" / locale
    return {name: text for name in FIELDS if (text := read(base / f"{name}.txt")) is not None}


def purchases(app: str, locale: str) -> dict[str, dict[str, str]]:
    out = {}
    for folder in APPS[app]["iap"]:
        base = HERE / app / "iap" / folder / locale
        fields = {name: text for name in IAP_LIMITS if (text := read(base / f"{name}.txt")) is not None}
        if fields:
            out[folder] = fields
    return out


def measure(name: str, value: str) -> int:
    """A field's length as Apple limits it: keywords in UTF-8 bytes, everything else in characters."""
    return len(value.encode()) if name == "keywords" else len(value)


def problems(app: str, locale: str) -> list[str]:
    """Everything wrong with one locale's text, by Apple's limits and a few house rules."""
    found = []
    text = listing(app, locale)
    for name in REQUIRED:
        if name not in text:
            found.append(f"{name}.txt is missing")
    for name, value in text.items():
        limit = FIELDS[name][2]
        if measure(name, value) > limit:
            unit = "bytes" if name == "keywords" else "characters"
            found.append(f"{name}: {measure(name, value)} {unit}, over the limit of {limit}")
        if name.endswith("_url") and not value.startswith("https://"):
            found.append(f"{name}: not an https:// link")
    keywords = text.get("keywords", "")
    if ", " in keywords:
        found.append("keywords: a space after a comma wastes a character")
    # Words in the name and subtitle are already searched; repeating them in keywords wastes room.
    named = set(re.findall(r"\w+", (text.get("name", "") + " " + text.get("subtitle", "")).lower()))
    repeats = [k for k in keywords.split(",") if (words := set(re.findall(r"\w+", k.lower()))) and words <= named]
    if repeats:
        found.append(f"keywords: already in the name or subtitle: {', '.join(repeats)}")
    for folder, fields in purchases(app, locale).items():
        for name, value in fields.items():
            if len(value) > IAP_LIMITS[name]:
                found.append(f"iap/{folder} {name}: {len(value)} characters, over the limit of {IAP_LIMITS[name]}")
    return found


def validate(apps: list[str]) -> int:
    bad = 0
    for app in apps:
        for locale in locales(app):
            found = problems(app, locale)
            sizes = ", ".join(f"{name} {measure(name, value)}/{FIELDS[name][2]}" for name, value in listing(app, locale).items())
            print(f"{app} {locale}: {'ok' if not found else 'NOT OK'} ({sizes})")
            for problem in found:
                print(f"  - {problem}")
            bad += len(found)
        per_locale, notes = testflight_text(app)
        if per_locale or notes is not None:
            found = testflight_problems(app)
            sizes = ", ".join([f"{loc} {n} {len(t)}/{TESTFLIGHT_LIMIT}" for loc, f in per_locale.items()
                               for n, t in f.items()] + ([f"review_notes {len(notes)}/{TESTFLIGHT_LIMIT}"]
                                                         if notes is not None else []))
            print(f"{app} testflight: {'ok' if not found else 'NOT OK'} ({sizes})")
            for problem in found:
                print(f"  - {problem}")
            bad += len(found)
    return 1 if bad else 0


# --------------------------------------------------------------------------------------------------------------------
# Credentials and the API

def load_credentials() -> None:
    """Fills the environment from the mounted 1Password Environment, without overriding what's already set. The mount
    is a pipe 1Password feeds when it's read, so it's read once, here, and never copied anywhere."""
    path = Path(os.path.expanduser(os.environ.get("ASCC_ENV_FILE", "~/.appstoreconnect/.env")))
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    for key, value in re.findall(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*("(?:[^"\\]|\\.)*"|\'[^\']*\'|[^\n]*)', text, re.M):
        if value[:1] in "\"'" and value[-1:] == value[:1]:
            value = value[1:-1]
        os.environ.setdefault(key, value)


def pem(raw: str) -> bytes:
    """The private key as PEM, however it was pasted: real line breaks, literal \\n, or all on one line."""
    text = raw.strip().strip("\"'").replace("\\n", "\n")
    match = re.match(r"(-----BEGIN [A-Z ]+-----)\s*(.+?)\s*(-----END [A-Z ]+-----)", text, re.S)
    if not match:
        raise SystemExit("ASCC_PRIVATE_KEY doesn't look like the .p8's contents (no BEGIN/END PRIVATE KEY lines)")
    body = re.sub(r"\s+", "", match.group(2))
    lines = [body[i:i + 64] for i in range(0, len(body), 64)]
    return "\n".join([match.group(1), *lines, match.group(3), ""]).encode()


def token() -> str:
    """A signed token for the API, good for 19 minutes (Apple allows 20)."""
    missing = [k for k in ("ASCC_KEY_ID", "ASCC_ISSUER_ID", "ASCC_PRIVATE_KEY") if not os.environ.get(k)]
    if missing:
        raise SystemExit(f"missing {', '.join(missing)}: add them to the 1Password Environment \"App Store Connect\"")
    try:
        from cryptography.hazmat.primitives import hashes, serialization
        from cryptography.hazmat.primitives.asymmetric import ec
        from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
    except ImportError:
        raise SystemExit("talking to App Store Connect needs cryptography: python3 -m pip install --user cryptography")

    def b64(data: bytes) -> str:
        return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

    now = int(time.time())
    header = {"alg": "ES256", "kid": os.environ["ASCC_KEY_ID"], "typ": "JWT"}
    claims = {"iss": os.environ["ASCC_ISSUER_ID"], "iat": now, "exp": now + 19 * 60, "aud": "appstoreconnect-v1"}
    message = f"{b64(json.dumps(header).encode())}.{b64(json.dumps(claims).encode())}".encode()
    key = serialization.load_pem_private_key(pem(os.environ["ASCC_PRIVATE_KEY"]), password=None)
    r, s = decode_dss_signature(key.sign(message, ec.ECDSA(hashes.SHA256())))
    return f"{message.decode()}.{b64(r.to_bytes(32, 'big') + s.to_bytes(32, 'big'))}"


class Client:
    def __init__(self) -> None:
        self.auth = f"Bearer {token()}"

    def call(self, method: str, path: str, body: dict | None = None) -> dict:
        request = urllib.request.Request(f"{API}{path}", method=method,
                                         data=json.dumps(body).encode() if body is not None else None,
                                         headers={"Authorization": self.auth, "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                text = response.read().decode()
        except urllib.error.HTTPError as error:
            raise RuntimeError(f"{method} {path}: {error.code} {error.read().decode()[:500]}") from None
        return json.loads(text) if text else {}

    def get(self, path: str) -> list[dict]:
        return self.call("GET", path).get("data", [])

    def get_all(self, path: str) -> list[dict]:
        """Every page of a list."""
        out = []
        while path:
            page = self.call("GET", path)
            out += page.get("data", [])
            path = (page.get("links") or {}).get("next", "").removeprefix(API)
        return out

    def get_one(self, path: str) -> dict | None:
        """A to-one relationship's resource, or None when there isn't one yet."""
        try:
            return self.call("GET", path).get("data")
        except RuntimeError as error:
            if ": 404 " in str(error):
                return None
            raise


def transfer(operations: list[dict], data: bytes) -> None:
    """Sends a reserved asset's bytes to the upload URLs Apple returned: unauthenticated and time-limited."""
    for op in operations:
        headers = {h["name"]: h["value"] for h in op.get("requestHeaders") or []}
        part = data[op["offset"]:op["offset"] + op["length"]]
        request = urllib.request.Request(op["url"], method=op["method"], data=part, headers=headers)
        with urllib.request.urlopen(request, timeout=120) as response:
            response.read()


def upsert(client: Client, kind: str, existing: dict | None, attrs: dict, parent: tuple[str, str, str],
           locale: str, dry_run: bool, label: str) -> bool:
    """Changes only the attributes that differ from what App Store Connect has; creates the localization if needed."""
    current = existing.get("attributes", {}) if existing else {}
    changed = {k: v for k, v in attrs.items() if (current.get(k) or "") != v}
    for k in attrs:
        print(f"  {label}.{k}: {'changes' if k in changed else 'same'}"
              + (f" ({len(current.get(k) or '')} -> {len(attrs[k])} characters)" if k in changed else ""))
    if not changed or dry_run:
        return bool(changed)
    if existing:
        client.call("PATCH", f"/v1/{kind}/{existing['id']}",
                    {"data": {"type": kind, "id": existing["id"], "attributes": changed}})
    else:
        relationship, parent_type, parent_id = parent
        client.call("POST", f"/v1/{kind}", {"data": {"type": kind, "attributes": {**changed, "locale": locale},
                                                     "relationships": {relationship: {"data": {"type": parent_type,
                                                                                               "id": parent_id}}}}})
    return True


def push(app: str, only: set[str] | None, dry_run: bool) -> int:
    if validate([app]):
        print("Fix the text before pushing.")
        return 1
    load_credentials()
    app_id = os.environ.get(APPS[app]["app_id_env"])
    if not app_id:
        raise SystemExit(f"missing {APPS[app]['app_id_env']} (the app's numeric Apple ID) in the 1Password Environment")
    client = Client()
    every = client.get(f"/v1/apps/{app_id}/appStoreVersions?limit=50")
    versions = [v for v in every if v["attributes"].get("appStoreState") in EDITABLE_STATES]
    if not versions and only == {"promotional_text"}:
        # Promotional text can change on the live version, without a new one.
        versions = [v for v in every if v["attributes"].get("appStoreState") == "READY_FOR_SALE"]
    if not versions:
        raise SystemExit("no editable version: create the next version in App Store Connect first")
    version = versions[0]
    infos = client.get(f"/v1/apps/{app_id}/appInfos")
    info = next((i for i in infos if i["attributes"].get("appStoreState") in EDITABLE_STATES
                 or i["attributes"].get("state") in EDITABLE_STATES), infos[0] if len(infos) == 1 else None)
    print(f"{app}: version {version['attributes'].get('versionString')} ({version['attributes'].get('appStoreState')})"
          + (" — dry run, nothing is written" if dry_run else ""))
    version_locs = {l["attributes"]["locale"]: l
                    for l in client.get(f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations?limit=200")}
    info_locs = {l["attributes"]["locale"]: l
                 for l in client.get(f"/v1/appInfos/{info['id']}/appInfoLocalizations?limit=200")} if info else {}
    changes = 0
    for locale in locales(app):
        print(f"[{locale}]")
        text = {k: v for k, v in listing(app, locale).items() if only is None or k in only}
        by_place = {"version": {}, "info": {}}
        for name, value in text.items():
            place, attribute, _ = FIELDS[name]
            by_place[place][attribute] = value
        if by_place["version"]:
            changes += upsert(client, "appStoreVersionLocalizations", version_locs.get(locale), by_place["version"],
                              ("appStoreVersion", "appStoreVersions", version["id"]), locale, dry_run, "listing")
        if by_place["info"]:
            if info is None:
                print("  name, subtitle, privacy policy: no editable app info, skipped")
            else:
                changes += upsert(client, "appInfoLocalizations", info_locs.get(locale), by_place["info"],
                                  ("appInfo", "appInfos", info["id"]), locale, dry_run, "app info")
        if only is None or "iap" in only:
            for folder, fields in purchases(app, locale).items():
                product_id = APPS[app]["iap"][folder]
                found = client.get(f"/v1/apps/{app_id}/inAppPurchasesV2?filter[productId]={product_id}&limit=1")
                if not found:
                    print(f"  iap {folder}: {product_id} isn't in App Store Connect yet, skipped")
                    continue
                purchase = found[0]["id"]
                locs = {l["attributes"]["locale"]: l
                        for l in client.get(f"/v2/inAppPurchases/{purchase}/inAppPurchaseLocalizations?limit=50")}
                changes += upsert(client, "inAppPurchaseLocalizations", locs.get(locale), fields,
                                  ("inAppPurchaseV2", "inAppPurchases", purchase), locale, dry_run, f"iap {folder}")
    print(f"{changes} localization{'' if changes == 1 else 's'} {'would change' if dry_run else 'changed'}.")
    return 0


def check() -> int:
    """Whether the credentials work, printing nothing secret: the key loads, and Apple answers with your apps."""
    load_credentials()
    names = ["ASCC_KEY_ID", "ASCC_ISSUER_ID", "ASCC_PRIVATE_KEY"] + [a["app_id_env"] for a in APPS.values()]
    for name in names:
        print(f"{name}: {'set' if os.environ.get(name) else 'missing'}")
    if not os.environ.get("ASCC_PRIVATE_KEY"):
        return 1
    try:
        from cryptography.hazmat.primitives import serialization
        from cryptography.hazmat.primitives.asymmetric import ec
    except ImportError:
        raise SystemExit("checking the key needs cryptography: python3 -m pip install --user cryptography")
    try:
        key = serialization.load_pem_private_key(pem(os.environ["ASCC_PRIVATE_KEY"]), password=None)
    except ValueError:
        print("ASCC_PRIVATE_KEY doesn't load as a private key: paste the whole .p8, BEGIN and END lines included")
        return 1
    good = isinstance(key, ec.EllipticCurvePrivateKey) and key.curve.name == "secp256r1"
    print(f"private key: {'loads, an EC P-256 key as Apple issues' if good else 'loads, but it is not an EC P-256 key'}")
    if not (os.environ.get("ASCC_KEY_ID") and os.environ.get("ASCC_ISSUER_ID")):
        print("Add ASCC_KEY_ID and ASCC_ISSUER_ID (App Store Connect > Users and Access > Integrations) to talk to Apple.")
        return 0 if good else 1
    try:
        apps = Client().get("/v1/apps?limit=50&fields[apps]=name,bundleId")
    except RuntimeError as error:
        print(f"Apple said no: {error}")
        return 1
    print("Apple answered. Your apps (the number is each one's ASCC_APP_ID_...):")
    for app in apps:
        print(f"  {app['id']}  {app['attributes']['name']}  ({app['attributes']['bundleId']})")
    return 0 if good else 1


# --------------------------------------------------------------------------------------------------------------------
# Screenshots and creative assets, through the App Asset Library

SCREENSHOT, HEADER, SEARCH = "APP_SCREENSHOT", "PRODUCT_PAGE_HEADER_ASSET", "APP_STORE_SEARCH_RESULTS_ASSET"
PREVIEW = "APP_PREVIEW"
# The devices with screenshots of their own get an app preview: an 886x1920 video goes to the 6.9" and 6.5" iPhones and
# the iPhone Duo, a 1200x1600 (or 1600x1200) one to the 13" iPad. The 6.3" iPhone has no set of its own: App Store
# Connect shows it the 6.5"'s, and Apple fills in the smaller iPhones and iPads from these.
PREVIEW_GROUPS = ("IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE", "IPHONE_FACE_ID_LARGE_PROFILE", "IPHONE_DUO_PROFILE",
                  "IPAD_13_PROFILE")
# A size that fits more than one device goes to the first of these it fits: 2048x2732 fits the 13" iPad and the 12.9",
# and the 13" is the one App Store Connect requires (it scales those down for the smaller iPads).
PREFERRED_GROUPS = ("IPAD_13_PROFILE",)
VIDEO_SUFFIXES = {".mp4", ".m4v", ".mov"}


def library_kind(path: Path) -> tuple[str, str, str]:
    """Where a file lives in the asset library: its collection, resource type, and placement relationship."""
    if path.suffix.lower() in VIDEO_SUFFIXES:
        return "videos", "appAssetLibraryVideos", "video"
    return "images", "appAssetLibraryImages", "image"


def png_info(path: Path) -> tuple[int, int, bool]:
    """A PNG's width, height, and whether it has an alpha channel (App Store Connect refuses one)."""
    with path.open("rb") as file:
        head = file.read(33)
    if head[:8] != b"\x89PNG\r\n\x1a\n" or head[12:16] != b"IHDR":
        raise SystemExit(f"{path}: not a PNG")
    width, height = struct.unpack(">II", head[16:24])
    return width, height, head[25] in (4, 6)


def video_size(path: Path) -> tuple[int, int]:
    """A .mp4 or .mov's picture size, from its video track's header (moov > trak > tkhd), without ffprobe."""
    data = path.read_bytes()

    def boxes(start: int, end: int):
        while start + 8 <= end:
            size, kind = struct.unpack(">I4s", data[start:start + 8])
            header = 8
            if size == 1:
                size, header = struct.unpack(">Q", data[start + 8:start + 16])[0], 16
            elif size == 0:
                size = end - start
            if size < header:
                return
            yield kind, start + header, start + size
            start += size

    for kind, start, end in boxes(0, len(data)):
        if kind != b"moov":
            continue
        for kind, start, end in boxes(start, end):
            if kind != b"trak":
                continue
            for kind, start, end in boxes(start, end):
                if kind == b"tkhd":
                    # Its last eight bytes are the width and height, 16.16 fixed point; a sound track's are zero.
                    width, height = struct.unpack(">II", data[end - 8:end])
                    if width and height:
                        return width >> 16, height >> 16
    raise SystemExit(f"{path}: no video track")


def media(app: str, locale: str, folders: list[Path], creatives: dict[str, Path], previews: list[Path],
          poster: str | None, dry_run: bool) -> int:
    """Replaces the editable version's screenshots (each folder's PNGs, in name order), its product page header and
    search results asset (`creatives`, by placement type), and its app previews (each video to the devices its size
    fits), with `poster` as the frame shown before one plays. New files are uploaded and processed first; the old
    placements are only swapped out once every one is ready, so a failure leaves the listing as it was."""
    load_credentials()
    app_id = os.environ.get(APPS[app]["app_id_env"])
    if not app_id:
        raise SystemExit(f"missing {APPS[app]['app_id_env']} in the 1Password Environment")
    client = Client()
    ref = client.call("GET", "/v1/appAssetLibraryRefData")["data"]
    ref = (ref[0] if isinstance(ref, list) else ref)["attributes"]
    image_specs = {s["specId"]: s for s in ref["imageSpecs"]}
    video_specs = {s["specId"]: s for s in ref.get("videoSpecs", [])}

    def groups_for(kind: str, width: int, height: int) -> list[str]:
        """The devices a file of that size and placement can go to, from Apple's reference data (so any device App Store
        Connect takes, the iPad and iPhone Duo included): the preferred one first."""
        specs = video_specs if kind == PREVIEW else image_specs
        out = []
        for placement in ref["placementTypes"]:
            if placement["placementTypeId"] != kind:
                continue
            for mapping in placement["specMappings"]:
                for spec_id in mapping["specs"]:
                    d = specs.get(spec_id, {}).get("dimensions", {})
                    if d.get("minWidth", 0) <= width <= d.get("maxWidth", 0) and d.get("minHeight", 0) <= height <= d.get("maxHeight", 0):
                        out.append(mapping["placementGroupId"])
                        break
        return sorted(out, key=lambda group: group not in PREFERRED_GROUPS)

    # What goes where: (placement type, group) -> files in order. A folder is one device's set, which can mix sizes the
    # device takes (an iPhone Duo's closed and opened screens, upright or sideways).
    plan: dict[tuple[str, str], list[Path]] = {}
    sizes: dict[Path, str] = {}
    for folder in folders:
        paths = sorted(folder.glob("*.png"))
        if not paths:
            raise SystemExit(f"{folder}: no PNGs")
        placed: dict[str, Path] = {}
        for path in paths:
            width, height, alpha = png_info(path)
            if alpha:
                raise SystemExit(f"{path}: has an alpha channel, which App Store Connect refuses")
            groups = groups_for(SCREENSHOT, width, height)
            if not groups:
                raise SystemExit(f"{path}: {width}x{height} isn't an App Store screenshot size")
            placed.setdefault(groups[0], path)
            sizes[path] = f"{width}x{height}"
            plan.setdefault((SCREENSHOT, groups[0]), []).append(path)
        if len(placed) > 1:
            raise SystemExit(f"{folder}: one device's set per folder, but it has "
                             + " and ".join(f"{group} ({path.name}, {sizes[path]})" for group, path in placed.items()))
    for kind, creative in creatives.items():
        width, height, alpha = png_info(creative)
        if alpha:
            raise SystemExit(f"{creative}: has an alpha channel")
        groups = groups_for(kind, width, height)
        if not groups:
            raise SystemExit(f"{creative}: {width}x{height} doesn't fit {kind}")
        plan[(kind, groups[0])] = [creative]
    if poster and not re.fullmatch(r"\d\d:\d\d:\d\d:\d\d", poster):
        raise SystemExit(f"--poster {poster}: a timecode into the video, HH:MM:SS:FF (FF is the frame)")
    for preview in previews:
        if preview.suffix.lower() not in VIDEO_SUFFIXES:
            raise SystemExit(f"{preview}: an app preview is a .mp4, .m4v or .mov")
        width, height = video_size(preview)
        groups = [group for group in groups_for(PREVIEW, width, height) if group in PREVIEW_GROUPS]
        if not groups:
            raise SystemExit(f"{preview}: {width}x{height} isn't an app preview size for any of {', '.join(PREVIEW_GROUPS)}")
        sizes[preview] = f"{width}x{height}"
        for group in groups:
            if (PREVIEW, group) in plan:
                raise SystemExit(f"{group}: two previews, {plan[(PREVIEW, group)][0].name} and {preview.name}")
            plan[(PREVIEW, group)] = [preview]
    for (kind, group), files in plan.items():
        if kind == SCREENSHOT and len(files) > 10:
            raise SystemExit(f"{group}: {len(files)} screenshots, over Apple's 10")

    versions = [v for v in client.get(f"/v1/apps/{app_id}/appStoreVersions?limit=50")
                if v["attributes"].get("appStoreState") in MEDIA_EDITABLE_STATES]
    if not versions:
        raise SystemExit("no version whose media can change: create the next version in App Store Connect, or take "
                         "it out of its draft submission")
    version = versions[0]
    localization = next((l for l in client.get(f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations?limit=200")
                         if l["attributes"]["locale"] == locale), None)
    if localization is None:
        raise SystemExit(f"version {version['attributes'].get('versionString')} has no {locale} localization yet: push the text first")
    print(f"{app} {locale}: version {version['attributes'].get('versionString')} ({version['attributes'].get('appStoreState')})"
          + (" — dry run, nothing is written" if dry_run else ""))

    def existing(kind: str, group: str) -> list[dict]:
        return client.get(f"/v1/appStoreVersionLocalizations/{localization['id']}/placements?filter[placementType]={kind}"
                          f"&filter[placementGroup]={group}&sort=placementGroupPosition&limit=50")

    current = {key: existing(*key) for key in plan}
    for (kind, group), files in plan.items():
        counts = Counter(sizes[p] for p in files if p in sizes)
        print(f"  {kind} {group}: replace {len(current[(kind, group)])} with {len(files)}"
              + (f" ({', '.join(f'{n} at {size}' for size, n in counts.items())})" if counts else "") + ": "
              + ", ".join(p.name for p in files) + (f" (poster at {poster})" if kind == PREVIEW and poster else ""))
    if dry_run:
        return 0

    # Upload every distinct file once, and wait until each is processed. Apple wants each asset's reference name
    # unique, so it ends with a hash of the contents; an asset the library already has under that name is reused.
    library = client.call("GET", f"/v1/apps/{app_id}/assetLibrary")["data"]["id"]
    uploaded: dict[Path, str] = {}
    for (kind, group), files in plan.items():
        category = "CREATIVE_ASSETS" if kind in (HEADER, SEARCH) else "APP_SCREENSHOTS_AND_PREVIEWS"
        for path in files:
            if path in uploaded:
                continue
            collection, resource, _ = library_kind(path)
            data = path.read_bytes()
            digest = hashlib.sha256(data).hexdigest()[:8]
            name = f"{app} {path.parent.name} {path.stem}"[:91] + f" {digest}"
            found = [a for a in client.get(f"/v1/appAssetLibraries/{library}/{collection}?filter[referenceName]="
                                           f"{urllib.parse.quote(name)}&limit=5")
                     if a["attributes"].get("state") != "FAILED"]
            if found:
                uploaded[path] = found[0]["id"]
                print(f"  {path.name}: already in the library")
                if resource == "appAssetLibraryVideos" and poster and found[0]["attributes"].get("previewFrameTimeCode") != poster:
                    client.call("PATCH", f"/v1/{resource}/{found[0]['id']}", {"data": {
                        "type": resource, "id": found[0]["id"], "attributes": {"previewFrameTimeCode": poster}}})
                    print(f"  {path.name}: poster frame moved to {poster}")
                continue
            attributes = {"fileName": path.name, "fileSize": len(data), "category": category, "referenceName": name}
            if resource == "appAssetLibraryVideos" and poster:
                attributes["previewFrameTimeCode"] = poster
            asset = client.call("POST", f"/v1/{resource}", {"data": {
                "type": resource, "attributes": attributes,
                "relationships": {"assetLibrary": {"data": {"type": "appAssetLibraries", "id": library}}}}})["data"]
            transfer(asset["attributes"]["uploadOperations"], data)
            client.call("PATCH", f"/v1/{resource}/{asset['id']}",
                        {"data": {"type": resource, "id": asset["id"], "attributes": {"uploaded": True}}})
            uploaded[path] = asset["id"]
            print(f"  uploaded {path.name}")
    minutes = 20 if any(library_kind(p)[0] == "videos" for p in uploaded) else 10
    deadline = time.time() + minutes * 60
    waiting = dict(uploaded)
    while waiting:
        for path, asset_id in list(waiting.items()):
            attributes = client.call("GET", f"/v1/{library_kind(path)[1]}/{asset_id}")["data"]["attributes"]
            if attributes["state"] == "PREPARE_FOR_SUBMISSION":
                del waiting[path]
            elif attributes["state"] == "FAILED":
                raise RuntimeError(f"{path.name} failed processing: {attributes.get('stateDetails')}. The listing is unchanged.")
        if waiting:
            if time.time() > deadline:
                raise RuntimeError(f"still processing after {minutes} minutes: {', '.join(p.name for p in waiting)}. "
                                   "The listing is unchanged; run again to retry.")
            time.sleep(5)
    print(f"  {len(uploaded)} files processed")

    # Swap the placements, then put each screenshot group in order.
    for (kind, group), files in plan.items():
        for old in current[(kind, group)]:
            client.call("DELETE", f"/v1/appAssetLibraryPlacements/{old['id']}")
        placed = []
        for path in files:
            _, resource, relationship = library_kind(path)
            placement = client.call("POST", "/v1/appAssetLibraryPlacements", {"data": {
                "type": "appAssetLibraryPlacements",
                "attributes": {"placementType": kind, "placementGroup": group},
                "relationships": {
                    relationship: {"data": {"type": resource, "id": uploaded[path]}},
                    "appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations",
                                                             "id": localization["id"]}}}}})["data"]
            placed.append(placement["id"])
        if kind == SCREENSHOT and len(placed) > 1:
            client.call("POST", "/v1/appAssetLibraryPlacementOrderingRequests", {"data": {
                "type": "appAssetLibraryPlacementOrderingRequests",
                "attributes": {"placementGroup": group},
                "relationships": {
                    "orderedPlacements": {"data": [{"type": "appAssetLibraryPlacements", "id": i} for i in placed]},
                    "appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations",
                                                             "id": localization["id"]}}}}})
        print(f"  {kind} {group}: {len(placed)} placed")
    return 0


# --------------------------------------------------------------------------------------------------------------------
# The in-app purchase

def purchase(app: str, screenshot: Path | None, dry_run: bool) -> int:
    """Sets up each of the app's in-app purchases so it reaches Ready to Submit: creates it if App Store Connect doesn't
    have it (with `PURCHASE_SETUP`'s settings), then fills in whatever's missing: its localizations from the files, its
    price, its availability (the app's own territories), and its review screenshot. Never changes a price or
    availability that's already set; a new --screenshot replaces the review screenshot."""
    if validate([app]):
        print("Fix the text before setting up a purchase.")
        return 1
    if screenshot:
        if screenshot.suffix.lower() not in {".png", ".jpg", ".jpeg"}:
            raise SystemExit(f"{screenshot}: the review screenshot is a .png or .jpg")
        if screenshot.suffix.lower() == ".png" and png_info(screenshot)[2]:
            raise SystemExit(f"{screenshot}: has an alpha channel; save it as a JPEG or flatten it")
        print(f"review screenshot: {screenshot.name}")
    load_credentials()
    app_id = os.environ.get(APPS[app]["app_id_env"])
    if not app_id:
        raise SystemExit(f"missing {APPS[app]['app_id_env']} in the 1Password Environment")
    client = Client()
    print(f"{app}" + (" — dry run, nothing is written" if dry_run else ""))
    for folder, product_id in APPS[app]["iap"].items():
        setup = PURCHASE_SETUP.get(product_id)
        found = client.get(f"/v1/apps/{app_id}/inAppPurchasesV2?filter[productId]={product_id}&limit=1")
        if found:
            iap = found[0]
            print(f"  {product_id}: exists ({iap['attributes'].get('state')})")
        elif setup is None:
            print(f"  {product_id}: not in App Store Connect, and PURCHASE_SETUP has no settings for it; skipped")
            continue
        elif dry_run:
            print(f"  {product_id}: would be created: {setup['type']}, \"{setup['reference_name']}\", "
                  f"${setup['price']}, Family Sharing {'on' if setup['family_sharable'] else 'off'}")
            print(f"  then its localizations, price, availability (the app's territories), and review screenshot")
            continue
        else:
            iap = client.call("POST", "/v2/inAppPurchases", {"data": {
                "type": "inAppPurchases",
                "attributes": {"name": setup["reference_name"], "productId": product_id,
                               "inAppPurchaseType": setup["type"], "familySharable": setup["family_sharable"]},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}})["data"]
            print(f"  {product_id}: created")
        iap_id = iap["id"]

        # Localizations, from the files.
        locs = {l["attributes"]["locale"]: l
                for l in client.get(f"/v2/inAppPurchases/{iap_id}/inAppPurchaseLocalizations?limit=50")}
        for locale in locales(app):
            fields = purchases(app, locale).get(folder)
            if fields:
                upsert(client, "inAppPurchaseLocalizations", locs.get(locale), fields,
                       ("inAppPurchaseV2", "inAppPurchases", iap_id), locale, dry_run, f"  {locale}")

        # The price, set once in the base territory.
        schedule = client.get_one(f"/v2/inAppPurchases/{iap_id}/iapPriceSchedule")
        if schedule:
            print("  price: already set, left alone")
        elif setup is None:
            print("  price: not set, and PURCHASE_SETUP has none for it")
        else:
            points = client.get_all(f"/v2/inAppPurchases/{iap_id}/pricePoints?filter[territory]=USA&limit=200")
            point = next((p for p in points if p["attributes"].get("customerPrice") == setup["price"]), None)
            if point is None:
                raise RuntimeError(f"no US price point of ${setup['price']}")
            print(f"  price: ${setup['price']} in the US" + (" would be set" if dry_run else ""))
            if not dry_run:
                client.call("POST", "/v1/inAppPurchasePriceSchedules", {
                    "data": {"type": "inAppPurchasePriceSchedules", "relationships": {
                        "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                        "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                        "manualPrices": {"data": [{"type": "inAppPurchasePrices", "id": "${price}"}]}}},
                    "included": [{"type": "inAppPurchasePrices", "id": "${price}",
                                  "attributes": {"startDate": None},
                                  "relationships": {"inAppPurchasePricePoint": {
                                      "data": {"type": "inAppPurchasePricePoints", "id": point["id"]}}}}]})

        # Availability: wherever the app itself is sold, and new territories as Apple adds them. Before the app's own
        # availability is chosen, every territory, as App Store Connect does by default; a purchase is only ever sold
        # where its app is.
        if client.get_one(f"/v2/inAppPurchases/{iap_id}/inAppPurchaseAvailability"):
            print("  availability: already set, left alone")
        else:
            app_availability = client.get_one(f"/v1/apps/{app_id}/appAvailabilityV2")
            if app_availability:
                territories = [t["relationships"]["territory"]["data"]["id"] for t in client.get_all(
                    f"/v2/appAvailabilities/{app_availability['id']}/territoryAvailabilities?include=territory&limit=200")
                    if t["attributes"].get("available")]
                where = f"the app's {len(territories)} territories"
            else:
                territories = [t["id"] for t in client.get_all("/v1/territories?limit=200")]
                where = f"all {len(territories)} territories (the app's own availability isn't chosen yet)"
            print(f"  availability: {where}" + (" would be set" if dry_run else ""))
            if not dry_run:
                client.call("POST", "/v1/inAppPurchaseAvailabilities", {"data": {
                    "type": "inAppPurchaseAvailabilities", "attributes": {"availableInNewTerritories": True},
                    "relationships": {
                        "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                        "availableTerritories": {"data": [{"type": "territories", "id": t} for t in territories]}}}})

        # The review screenshot.
        current = client.get_one(f"/v2/inAppPurchases/{iap_id}/appStoreReviewScreenshot")
        data = screenshot.read_bytes() if screenshot else None
        checksum = hashlib.md5(data).hexdigest() if data else None
        if data is None:
            print(f"  review screenshot: {'there' if current else 'missing: give --screenshot'}")
        elif current and current["attributes"].get("sourceFileChecksum") == checksum:
            print("  review screenshot: already this one")
        elif dry_run:
            print(f"  review screenshot: would {'replace the current one' if current else 'upload'}")
        else:
            if current:
                client.call("DELETE", f"/v1/inAppPurchaseAppStoreReviewScreenshots/{current['id']}")
            shot = client.call("POST", "/v1/inAppPurchaseAppStoreReviewScreenshots", {"data": {
                "type": "inAppPurchaseAppStoreReviewScreenshots",
                "attributes": {"fileName": screenshot.name, "fileSize": len(data)},
                "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}}}})["data"]
            transfer(shot["attributes"]["uploadOperations"], data)
            client.call("PATCH", f"/v1/inAppPurchaseAppStoreReviewScreenshots/{shot['id']}", {"data": {
                "type": "inAppPurchaseAppStoreReviewScreenshots", "id": shot["id"],
                "attributes": {"uploaded": True, "sourceFileChecksum": checksum}}})
            print("  review screenshot: uploaded")
        if not dry_run:
            state = client.call("GET", f"/v2/inAppPurchases/{iap_id}")["data"]["attributes"].get("state")
            print(f"  {product_id}: {state}")
    return 0


# --------------------------------------------------------------------------------------------------------------------
# TestFlight: the test information testers and Beta App Review see, and the tester groups

# Text from appstore/<app>/testflight/: <locale>/description.txt (the beta app description), <locale>/what_to_test.txt
# (a build's What to Test) and review_notes.txt (notes for Beta App Review). The feedback email and the review contact
# are personal, so they come from the 1Password Environment, not the repo: ASCC_BETA_FEEDBACK_EMAIL, and
# ASCC_REVIEW_FIRST_NAME, ASCC_REVIEW_LAST_NAME, ASCC_REVIEW_PHONE, ASCC_REVIEW_EMAIL. Missing ones are left as they are.
TESTFLIGHT_LIMIT = 4000
# Tester groups to have. An internal group (App Store Connect users) gets every build; an external one gets the builds
# added to it, each version's first after Beta App Review. A public link lets anyone with it join, no invite needed.
TESTFLIGHT_GROUPS = [{"name": "Internal", "internal": True},
                     {"name": "Friends", "internal": False, "public_link": True}]


def testflight_text(app: str) -> tuple[dict[str, dict[str, str]], str | None]:
    base = HERE / app / "testflight"
    per_locale = {}
    if base.exists():
        for folder in sorted(p for p in base.iterdir() if p.is_dir()):
            fields = {n: t for n in ("description", "what_to_test") if (t := read(folder / f"{n}.txt")) is not None}
            if fields:
                per_locale[folder.name] = fields
    return per_locale, read(base / "review_notes.txt")


def testflight_problems(app: str) -> list[str]:
    per_locale, notes = testflight_text(app)
    texts = [(f"{loc} {n}", t) for loc, f in per_locale.items() for n, t in f.items()]
    if notes is not None:
        texts.append(("review_notes", notes))
    return [f"{name} is {len(text)} characters (limit {TESTFLIGHT_LIMIT})" if text.strip() else f"{name} is empty"
            for name, text in texts if len(text) > TESTFLIGHT_LIMIT or not text.strip()]


def testflight(app: str, build_number: str | None, submit: bool, invite: list[str], dry_run: bool) -> int:
    if found := testflight_problems(app):
        raise SystemExit("Fix the TestFlight text first:\n  - " + "\n  - ".join(found))
    per_locale, notes = testflight_text(app)
    load_credentials()
    app_id = os.environ.get(APPS[app]["app_id_env"])
    if not app_id:
        raise SystemExit(f"missing {APPS[app]['app_id_env']} (the app's numeric Apple ID) in the 1Password Environment")
    client = Client()
    print(f"{app}: TestFlight" + (" — dry run, nothing is written" if dry_run else ""))
    changes = 0

    # Test information, per locale: description, feedback email, and the listing's privacy policy and marketing links.
    locs = {l["attributes"]["locale"]: l for l in client.get(f"/v1/apps/{app_id}/betaAppLocalizations?limit=50")}
    for locale, fields in per_locale.items():
        print(f"[{locale}]")
        attrs = {}
        if "description" in fields:
            attrs["description"] = fields["description"]
        if os.environ.get("ASCC_BETA_FEEDBACK_EMAIL"):
            attrs["feedbackEmail"] = os.environ["ASCC_BETA_FEEDBACK_EMAIL"]
        else:
            print("  feedback email: ASCC_BETA_FEEDBACK_EMAIL isn't set, left as it is")
        text = listing(app, locale)
        for name, attribute in (("privacy_policy_url", "privacyPolicyUrl"), ("marketing_url", "marketingUrl")):
            if name in text:
                attrs[attribute] = text[name]
        changes += upsert(client, "betaAppLocalizations", locs.get(locale), attrs, ("app", "apps", app_id),
                          locale, dry_run, "test information")

    # Beta App Review: the notes, the contact, and no sign-in needed.
    detail = client.get_one(f"/v1/apps/{app_id}/betaAppReviewDetail")
    if detail:
        wanted = {"demoAccountRequired": False}
        if notes is not None:
            wanted["notes"] = notes
        contact = {"contactFirstName": "ASCC_REVIEW_FIRST_NAME", "contactLastName": "ASCC_REVIEW_LAST_NAME",
                   "contactPhone": "ASCC_REVIEW_PHONE", "contactEmail": "ASCC_REVIEW_EMAIL"}
        for attribute, env in contact.items():
            if os.environ.get(env):
                wanted[attribute] = os.environ[env]
        missing = [env for env in contact.values() if not os.environ.get(env)]
        if missing:
            print(f"  review contact: {', '.join(missing)} not set, left as they are")
        current = detail.get("attributes", {})
        changed = {k: v for k, v in wanted.items() if current.get(k) != v}
        for k in wanted:
            print(f"  review.{k}: {'changes' if k in changed else 'same'}")
        if changed and not dry_run:
            client.call("PATCH", f"/v1/betaAppReviewDetails/{detail['id']}",
                        {"data": {"type": "betaAppReviewDetails", "id": detail["id"], "attributes": changed}})
        changes += bool(changed)

    # Tester groups.
    groups = {g["attributes"]["name"]: g for g in client.get(f"/v1/apps/{app_id}/betaGroups?limit=50")}
    for spec in TESTFLIGHT_GROUPS:
        if spec["name"] in groups:
            print(f"  group {spec['name']}: exists")
            continue
        print(f"  group {spec['name']}: {'would be created' if dry_run else 'created'}"
              f" ({'internal, every build' if spec['internal'] else 'external'})")
        changes += 1
        if not dry_run:
            attrs = {"name": spec["name"], "isInternalGroup": spec["internal"]}
            if spec["internal"]:
                attrs["hasAccessToAllBuilds"] = True
            created = client.call("POST", "/v1/betaGroups", {"data": {"type": "betaGroups", "attributes": attrs,
                                  "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}})
            groups[spec["name"]] = created["data"]

    external = [spec["name"] for spec in TESTFLIGHT_GROUPS if not spec["internal"]]

    # Testers: invited by email to the external group. Their addresses come from the command line, never the repo.
    if invite:
        group = groups.get(external[0])
        on_group = {t["attributes"].get("email", "").lower()
                    for t in client.get_all(f"/v1/betaGroups/{group['id']}/betaTesters?limit=200")} if group else set()
        for email in invite:
            if email.lower() in on_group:
                print(f"  tester {email}: already in {external[0]}")
                continue
            # Someone already testing another of the account's apps is added as they are; creating them again fails.
            known = client.get(f"/v1/betaTesters?filter[email]={urllib.parse.quote(email)}&limit=1")
            print(f"  tester {email}{' (an existing tester)' if known else ''}: "
                  f"{'would be invited' if dry_run else 'invited'} to {external[0]}")
            changes += 1
            if dry_run:
                continue
            if known:
                client.call("POST", f"/v1/betaGroups/{group['id']}/relationships/betaTesters",
                            {"data": [{"type": "betaTesters", "id": known[0]["id"]}]})
            else:
                client.call("POST", "/v1/betaTesters", {"data": {"type": "betaTesters", "attributes": {"email": email},
                            "relationships": {"betaGroups": {"data": [{"type": "betaGroups", "id": group["id"]}]}}}})

    # A build: its What to Test, and with --submit, the external group and Beta App Review. Build numbers can repeat
    # across versions, so this takes the newest upload with that number.
    if build_number:
        builds = client.get(f"/v1/builds?filter[app]={app_id}&filter[version]={build_number}&sort=-uploadedDate"
                            "&limit=1&include=preReleaseVersion")
        if not builds:
            print(f"  build {build_number}: not in App Store Connect yet (still uploading or processing?)")
            return 1
        build = builds[0]
        state = build["attributes"].get("processingState")
        print(f"  build {build_number}: {state}, uploaded {build['attributes'].get('uploadedDate', '?')[:10]}")
        build_locs = {l["attributes"]["locale"]: l
                      for l in client.get(f"/v1/builds/{build['id']}/betaBuildLocalizations?limit=50")}
        for locale, fields in per_locale.items():
            if "what_to_test" in fields:
                changes += upsert(client, "betaBuildLocalizations", build_locs.get(locale),
                                  {"whatsNew": fields["what_to_test"]}, ("build", "builds", build["id"]),
                                  locale, dry_run, f"build {build_number} [{locale}]")
        if submit:
            if state != "VALID":
                raise SystemExit(f"build {build_number} is {state}: wait until it has finished processing")
            for name in external:
                group = groups.get(name)
                # A build's groups can't be listed, so look for the build among the group's.
                if group and build["id"] in {b["id"] for b in
                                             client.get_all(f"/v1/betaGroups/{group['id']}/builds?limit=200")}:
                    print(f"  build {build_number} -> group {name}: already added")
                    continue
                print(f"  build {build_number} -> group {name}: {'would be added' if dry_run else 'added'}")
                changes += 1
                if not dry_run:
                    client.call("POST", f"/v1/betaGroups/{group['id']}/relationships/builds",
                                {"data": [{"type": "builds", "id": build["id"]}]})
            review = client.get_one(f"/v1/builds/{build['id']}/betaAppReviewSubmission")
            if review:
                print(f"  beta review: already submitted ({review['attributes'].get('betaReviewState')})")
            else:
                print(f"  beta review: {'would be submitted' if dry_run else 'submitted'}")
                changes += 1
                if not dry_run:
                    client.call("POST", "/v1/betaAppReviewSubmissions", {"data": {
                        "type": "betaAppReviewSubmissions",
                        "relationships": {"build": {"data": {"type": "builds", "id": build["id"]}}}}})

    # Public links, after any build was added: testers who open one before a build is approved are told to wait.
    for spec in TESTFLIGHT_GROUPS:
        if not spec.get("public_link"):
            continue
        group = groups.get(spec["name"])
        attrs = group["attributes"] if group else {}
        if attrs.get("publicLinkEnabled"):
            print(f"  group {spec['name']} public link: {attrs.get('publicLink')}")
            continue
        print(f"  group {spec['name']} public link: {'would be turned on' if dry_run else 'turned on'}")
        changes += 1
        if not dry_run:
            updated = client.call("PATCH", f"/v1/betaGroups/{group['id']}", {"data": {
                "type": "betaGroups", "id": group["id"], "attributes": {"publicLinkEnabled": True}}})
            print(f"    {updated['data']['attributes'].get('publicLink')}")
    print(f"{changes} change{'' if changes == 1 else 's'} {'would be made' if dry_run else 'made'}.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("check", help="whether the credentials work, and each app's Apple ID; prints nothing secret")
    checks = sub.add_parser("validate", help="check every app's text against Apple's limits; no network")
    checks.add_argument("--app", choices=APPS)
    send = sub.add_parser("push", help="push an app's text to its editable version")
    send.add_argument("--app", choices=APPS, required=True)
    send.add_argument("--only", help="comma-separated fields to push (file names, or iap)")
    send.add_argument("--dry-run", action="store_true", help="show what would change; write nothing")
    images = sub.add_parser("media", help="replace the editable version's screenshots and creative assets")
    images.add_argument("--app", choices=APPS, required=True)
    images.add_argument("--locale", default="en-US")
    images.add_argument("--screenshots", type=Path, nargs="*", default=[],
                        help="folders of PNGs, one per device size, uploaded in name order")
    images.add_argument("--creative", type=Path, help="a 5244x2950 PNG for the product page header and search results")
    images.add_argument("--header", type=Path, help="a 5244x2950 PNG for the product page header only")
    images.add_argument("--search", type=Path, help="a 5244x2950 PNG for the search results asset only")
    images.add_argument("--preview", type=Path, nargs="*", default=[],
                        help="app preview videos, each to the devices its size fits: 886x1920 for the 6.9\" and 6.5\" "
                             "iPhones and the iPhone Duo, 1200x1600 for the 13\" iPad")
    images.add_argument("--poster", help="the previews' poster frame, the still shown before one plays (HH:MM:SS:FF)")
    images.add_argument("--dry-run", action="store_true", help="show what would change; write nothing")
    buy = sub.add_parser("purchase", help="create the app's in-app purchases and fill in what they're missing")
    buy.add_argument("--app", choices=APPS, required=True)
    buy.add_argument("--screenshot", type=Path, help="a PNG or JPEG of the purchase screen, for App Review")
    buy.add_argument("--dry-run", action="store_true", help="show what would change; write nothing")
    beta = sub.add_parser("testflight", help="TestFlight's test information, groups, and a build's What to Test")
    beta.add_argument("--app", choices=APPS, required=True)
    beta.add_argument("--build", help="a build number (CFBundleVersion): set its What to Test")
    beta.add_argument("--submit", action="store_true",
                      help="with --build: add it to the external group and submit it for Beta App Review")
    beta.add_argument("--invite", action="append", default=[], metavar="EMAIL",
                      help="invite a tester to the external group (repeatable)")
    beta.add_argument("--dry-run", action="store_true", help="show what would change; write nothing")
    args = parser.parse_args()
    if args.command == "check":
        return check()
    if args.command == "testflight":
        if args.submit and not args.build:
            raise SystemExit("--submit needs --build")
        try:
            return testflight(args.app, args.build, args.submit, args.invite, args.dry_run)
        except RuntimeError as error:
            print(f"error: {error}", file=sys.stderr)
            return 2
    if args.command == "media":
        creatives = {kind: path for kind, path in ((HEADER, args.header or args.creative),
                                                   (SEARCH, args.search or args.creative)) if path}
        if args.poster and not args.preview:
            raise SystemExit("--poster sets the frame of the --preview videos it comes with")
        if not args.screenshots and not creatives and not args.preview:
            raise SystemExit("nothing to do: give --screenshots folders, a --creative (or --header, --search) image, "
                             "or --preview videos")
        try:
            return media(args.app, args.locale, args.screenshots, creatives, args.preview, args.poster, args.dry_run)
        except RuntimeError as error:
            print(f"error: {error}", file=sys.stderr)
            return 2
    if args.command == "purchase":
        try:
            return purchase(args.app, args.screenshot, args.dry_run)
        except RuntimeError as error:
            print(f"error: {error}", file=sys.stderr)
            return 2
    if args.command == "validate":
        return validate([args.app] if args.app else [a for a in APPS if (HERE / a).exists()])
    only = set(args.only.split(",")) if args.only else None
    if only and only - set(FIELDS) - {"iap"}:
        raise SystemExit(f"unknown fields: {', '.join(sorted(only - set(FIELDS) - {'iap'}))}")
    try:
        return push(args.app, only, args.dry_run)
    except RuntimeError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
