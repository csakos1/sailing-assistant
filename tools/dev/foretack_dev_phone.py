#!/usr/bin/env python3
"""Telefon nélküli „Foretack app" a helyi webes belépés próbájához.

Csak fejlesztéshez (ADR 0051 Addendum 7 P8): a szerverbe és a telefonra
nem kerül. Ugyanazt a protokollt beszéli, mint a telefonos app (ADR 0051
D4, Addendum 3 K1–K3): két P-256 kulcs, kanonikus aláírt üzenetek,
`X-Foretack-Client: phone`. Ujjlenyomat nincs, a kulcsok egy helyi
állapotfájlban vannak, ezért éles szerveren SOHA ne használd.

Parancsok:

  enroll <qr-szöveg>
      A `create_owner_enrollment` kimenetével regisztrál tulajdonosként,
      és kiírja a 10 helyreállító kódot (ezekkel a tartalék belépés is
      kipróbálható).

  approve <qr-szöveg> | approve --image <képernyőkép.png>
      Egy webes belépési QR-t megnyit és jóváhagy. A böngésző QR-ját
      képként a `zbarimg` (Arch: `pacman -S zbar`) olvassa ki.

  join-requests
      A függő csatlakozási kérelmek listája (a tulajdonos nevében).

  approve-join <kérelem-id> [--member <userId>]
      Egy kérelem jóváhagyása: alapból új tag, a `--member`-rel egy
      meglévő legénységi tag új telefonja (ADR 0051 Addendum 5 M6).

  reject-join <kérelem-id>
      Egy kérelem elutasítása; a telefon „nincs jóváhagyva"-t kap.

Függőség: a `cryptography` csomag (Arch: `pacman -S python-cryptography`).
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import platform
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

try:
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import ec
except ImportError:  # pragma: no cover - csak a hiányzó csomagot jelzi
    sys.exit("Hiányzik a cryptography csomag: pacman -S python-cryptography")

LOGIN_PREFIX = "foretack-login:v1:"
ENROLL_PREFIX = "foretack-enroll:v1:"
DEFAULT_STATE = Path.home() / ".config" / "foretack-dev-phone" / "state.json"


# --- Kódolás -----------------------------------------------------------


def b64url_decode(text: str) -> bytes:
    """Kitöltés nélküli base64url, ahogy a QR hordozza (Addendum 2 J2)."""
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))


def b64(data: bytes) -> str:
    """Szabványos base64: a kulcsok és az aláírások alakja (Addendum 4 L2)."""
    return base64.b64encode(data).decode("ascii")


def read_qr(text: str, prefix: str) -> dict[str, str]:
    """A QR JSON-tartalma; más előtagnál leáll."""
    text = text.strip()
    if not text.startswith(prefix):
        sys.exit(f"Nem {prefix} kezdetű QR-szöveg.")
    return json.loads(b64url_decode(text[len(prefix):]))


def canonical(lines: list[str]) -> bytes:
    """A kanonikus aláírt üzenet: `\\n`-nel, záró sortörés nélkül (J3)."""
    for line in lines:
        if not line or "\n" in line or "\r" in line:
            raise ValueError(f"Üres vagy többsoros mező: {line!r}")
    return "\n".join(lines).encode("utf-8")


def spki(key: ec.EllipticCurvePrivateKey) -> bytes:
    """A nyilvános kulcs 91 bájtos X.509 SPKI DER alakja (Addendum 1 H5)."""
    return key.public_key().public_bytes(
        serialization.Encoding.DER,
        serialization.PublicFormat.SubjectPublicKeyInfo,
    )


def sign(key: ec.EllipticCurvePrivateKey, message: bytes) -> str:
    """DER ECDSA-aláírás SHA-256-tal, base64-ben."""
    return b64(key.sign(message, ec.ECDSA(hashes.SHA256())))


# --- Állapot -----------------------------------------------------------


def pem(key: ec.EllipticCurvePrivateKey) -> str:
    return key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    ).decode("ascii")


def load_key(text: str) -> ec.EllipticCurvePrivateKey:
    key = serialization.load_pem_private_key(text.encode("ascii"), None)
    if not isinstance(key, ec.EllipticCurvePrivateKey):
        sys.exit("Az állapotfájl kulcsa nem P-256.")
    return key


def save_state(path: Path, state: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    # A kulcsok titkok: csak a felhasználó olvashatja.
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    # Egy korábbi, lazább jogú fájl módját is szigorítja.
    os.fchmod(fd, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as file:
        json.dump(state, file, indent=2)


def load_state(path: Path) -> dict[str, str]:
    if not path.exists():
        sys.exit(f"Nincs regisztrált teszt-telefon: {path} (előbb: enroll).")
    return json.loads(path.read_text(encoding="utf-8"))


# --- HTTP --------------------------------------------------------------


def post(
    origin: str,
    path: str,
    body: dict[str, object],
    token: str | None = None,
) -> dict[str, object] | None:
    """JSON-POST a telefon fejlécével; hibánál a választ kiírja és kilép."""
    headers = {
        "content-type": "application/json; charset=utf-8",
        "x-foretack-client": "phone",
    }
    if token is not None:
        headers["authorization"] = f"Bearer {token}"
    request = urllib.request.Request(
        origin + path,
        data=json.dumps(body).encode("utf-8"),
        headers=headers,
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            raw = response.read()
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", "replace")
        sys.exit(f"{path}: HTTP {error.code} {detail}")
    except urllib.error.URLError as error:
        sys.exit(f"{path}: a szerver nem érhető el ({error.reason}).")
    return json.loads(raw) if raw else None


def get_json(origin: str, path: str, token: str) -> dict[str, object]:
    """JSON-GET eszköz-tokennel; hibánál a választ kiírja és kilép."""
    request = urllib.request.Request(
        origin + path,
        headers={
            "authorization": f"Bearer {token}",
            "x-foretack-client": "phone",
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            result = json.loads(response.read())
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", "replace")
        sys.exit(f"{path}: HTTP {error.code} {detail}")
    except urllib.error.URLError as error:
        sys.exit(f"{path}: a szerver nem érhető el ({error.reason}).")
    if not isinstance(result, dict):
        sys.exit(f"{path}: váratlan, nem objektum válasz.")
    return result


def post_json(
    origin: str,
    path: str,
    body: dict[str, object],
    token: str | None = None,
) -> dict[str, object]:
    """Mint a `post`, de a válaszban JSON-objektumot vár."""
    result = post(origin, path, body, token=token)
    if not isinstance(result, dict):
        sys.exit(f"{path}: váratlan, üres vagy nem objektum válasz.")
    return result


def device_token(state: dict[str, str]) -> str:
    """15 perces eszköz-token az eszközkulccsal (Addendum 3 K3)."""
    origin, device_id = state["origin"], state["deviceId"]
    challenge = post_json(
        origin, "/api/auth/device-challenges", {"deviceId": device_id}
    )
    value = str(challenge["value"])
    message = canonical(["foretack-device-v1", origin, device_id, value])
    issued = post_json(
        origin,
        "/api/auth/device-tokens",
        {
            "deviceId": device_id,
            "challenge": value,
            "signature": sign(load_key(state["deviceKey"]), message),
        },
    )
    return str(issued["value"])


# --- Parancsok ---------------------------------------------------------


def enroll(args: argparse.Namespace) -> None:
    payload = read_qr(args.qr, ENROLL_PREFIX)
    origin, token = payload["origin"], payload["token"]
    signing, device = ec.generate_private_key(ec.SECP256R1()), ec.generate_private_key(
        ec.SECP256R1()
    )
    message = canonical(
        ["foretack-enroll-v1", origin, token, b64(spki(signing)), b64(spki(device))]
    )
    result = post_json(
        origin,
        "/api/auth/enrollments",
        {
            "token": token,
            "publicKey": b64(spki(signing)),
            "deviceKey": b64(spki(device)),
            "deviceName": args.device_name,
            "model": f"Dev ({platform.system()})",
            "signature": sign(signing, message),
        },
    )
    save_state(
        args.state,
        {
            "origin": origin,
            "deviceId": str(result["deviceId"]),
            "signingKey": pem(signing),
            "deviceKey": pem(device),
        },
    )
    account = result["account"]
    if not isinstance(account, dict):
        sys.exit("A regisztráció válaszában nincs fiók.")
    print(f"Regisztrálva: {account['name']} ({account['role']}) — {origin}")
    print(f"Eszköz: {result['deviceId']}; állapot: {args.state}")
    print("Helyreállító kódok (a tartalék belépéshez):")
    codes = result["recoveryCodes"]
    if not isinstance(codes, list):
        sys.exit("A regisztráció válaszában nincsenek kódok.")
    for code in codes:
        print(f"  {code}")


def qr_text_of(args: argparse.Namespace) -> str:
    if args.image is None:
        if args.qr is None:
            sys.exit("Add meg a QR-szöveget vagy a --image képet.")
        return args.qr
    try:
        output = subprocess.run(
            ["zbarimg", "-q", "--raw", str(args.image)],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
    except FileNotFoundError:
        sys.exit("Nincs zbarimg: pacman -S zbar")
    except subprocess.CalledProcessError:
        sys.exit(f"A képen nincs olvasható QR-kód: {args.image}")
    return output.strip().splitlines()[0]


def approve(args: argparse.Namespace) -> None:
    state = load_state(args.state)
    payload = read_qr(qr_text_of(args), LOGIN_PREFIX)
    origin = payload["origin"]
    if origin != state["origin"]:
        sys.exit(f"Más szerver QR-ja: {origin} (regisztrálva: {state['origin']}).")
    request_id, challenge = payload["requestId"], payload["challenge"]
    token = device_token(state)
    details = post(
        origin,
        f"/api/auth/login-requests/{request_id}/open",
        {"challenge": challenge},
        token=token,
    )
    print(f"Megnyitva: {json.dumps(details, ensure_ascii=False)}")
    message = canonical(
        ["foretack-login-v1", origin, request_id, challenge, state["deviceId"]]
    )
    post(
        origin,
        f"/api/auth/login-requests/{request_id}/approval",
        {
            "deviceId": state["deviceId"],
            "signature": sign(load_key(state["signingKey"]), message),
        },
    )
    print("Jóváhagyva: a böngésző a következő lekérdezéssel belép.")


def local_minute(epoch_ms: object) -> str:
    """Egy UTC epoch-ms időpont helyi időben, percre."""
    if not isinstance(epoch_ms, int):
        return "?"
    return datetime.fromtimestamp(epoch_ms / 1000).strftime("%Y-%m-%d %H:%M")


def join_requests(args: argparse.Namespace) -> None:
    state = load_state(args.state)
    token = device_token(state)
    listed = get_json(state["origin"], "/api/auth/join-requests", token)
    requests = listed.get("joinRequests")
    if not isinstance(requests, list) or not requests:
        print("Nincs függő csatlakozási kérelem.")
        return
    for request in requests:
        if not isinstance(request, dict):
            continue
        place = ", ".join(
            str(part)
            for part in (request.get("city"), request.get("country"))
            if part
        )
        print(f"{request['id']}")
        print(f"  {request['name']} · {request['deviceName']} ({request['model']})")
        print(f"  {request['ip']} {place}".rstrip())
        print(
            f"  beküldve {local_minute(request.get('createdAt'))}, "
            f"lejár {local_minute(request.get('expiresAt'))}"
        )


def approve_join(args: argparse.Namespace) -> None:
    state = load_state(args.state)
    origin, device_id = state["origin"], state["deviceId"]
    token = device_token(state)
    challenge = str(
        post_json(origin, "/api/auth/action-challenges", {}, token=token)["value"]
    )
    # A cél „<kérelem>:new" vagy „<kérelem>:<tag>" (joinApprovalTarget).
    member = args.member or None
    target = f"{args.id}:{member or 'new'}"
    message = canonical(
        ["foretack-action-v1", origin, device_id, challenge, "approveJoin", target]
    )
    body: dict[str, object] = {
        "challenge": challenge,
        "signature": sign(load_key(state["signingKey"]), message),
    }
    if member is not None:
        body["memberId"] = member
    approved = post_json(
        origin, f"/api/auth/join-requests/{args.id}/approval", body, token=token
    )
    account = approved.get("account")
    name = account.get("name") if isinstance(account, dict) else "?"
    print(f"Jóváhagyva: {name}. A várakozó böngésző a következő lekérdezéssel belép.")


def reject_join(args: argparse.Namespace) -> None:
    state = load_state(args.state)
    token = device_token(state)
    post(
        state["origin"],
        f"/api/auth/join-requests/{args.id}/rejection",
        {},
        token=token,
    )
    print("Elutasítva.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--state",
        type=Path,
        default=DEFAULT_STATE,
        help=f"az állapotfájl (alapból {DEFAULT_STATE})",
    )
    commands = parser.add_subparsers(dest="command", required=True)
    enroll_parser = commands.add_parser("enroll", help="tulajdonosi regisztráció")
    enroll_parser.add_argument("qr", help="a create_owner_enrollment kimenete")
    enroll_parser.add_argument("--device-name", default="Dev telefon")
    enroll_parser.set_defaults(run=enroll)
    approve_parser = commands.add_parser("approve", help="webes belépés jóváhagyása")
    approve_parser.add_argument("qr", nargs="?", help="a belépési QR szövege")
    approve_parser.add_argument("--image", type=Path, help="képernyőkép a QR-ról")
    approve_parser.set_defaults(run=approve)
    list_parser = commands.add_parser("join-requests", help="függő kérelmek")
    list_parser.set_defaults(run=join_requests)
    approve_join_parser = commands.add_parser(
        "approve-join", help="csatlakozási kérelem jóváhagyása"
    )
    approve_join_parser.add_argument("id", help="a kérelem azonosítója")
    approve_join_parser.add_argument(
        "--member", help="egy meglévő legénységi tag azonosítója"
    )
    approve_join_parser.set_defaults(run=approve_join)
    reject_join_parser = commands.add_parser(
        "reject-join", help="csatlakozási kérelem elutasítása"
    )
    reject_join_parser.add_argument("id", help="a kérelem azonosítója")
    reject_join_parser.set_defaults(run=reject_join)
    args = parser.parse_args()
    args.run(args)


if __name__ == "__main__":
    main()
