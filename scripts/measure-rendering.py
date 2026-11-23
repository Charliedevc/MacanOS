#!/usr/bin/env python3
"""Capture real simulator windows and summarize active unified-media frame timing."""
import argparse
import json
import math
import os
from pathlib import Path
import statistics
import subprocess
import sys
import tempfile
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
ROLES = ("driver", "passenger")


def wait_for(predicate, description):
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        if result := predicate():
            return result
        time.sleep(0.04)
    raise RuntimeError(f"Timed out waiting for {description}")


def read_state(path):
    try:
        return json.loads(path.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def complete_png(path):
    try:
        return path.read_bytes().endswith(b"\x00\x00\x00\x00IEND\xaeB`\x82")
    except FileNotFoundError:
        return False


def metrics(timestamps, start, end):
    active = [stamp for stamp in timestamps if start <= stamp <= end]
    deltas = [(b - a) / 1_000_000 for a, b in zip(active, active[1:])]
    if not deltas:
        raise RuntimeError("Frame timing capture contains no active-window intervals")
    return {
        "frames": len(active),
        "fps": round((len(active) - 1) * 1_000_000_000 / (active[-1] - active[0]), 2),
        "p50Ms": round(statistics.median(deltas), 2),
        "p95Ms": round(sorted(deltas)[math.ceil(.95 * len(deltas)) - 1], 2),
        "worstMs": round(max(deltas), 2),
        "intervalsOver20Ms": sum(delta > 20 for delta in deltas),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", default=ROOT / "build", type=Path)
    parser.add_argument("--output", default=ROOT / "artifacts" / "v0.7", type=Path)
    parser.add_argument("--width", type=int, default=1280)
    parser.add_argument("--height", type=int, default=480)
    args = parser.parse_args()
    if not sys.platform.startswith("linux"):
        parser.error("This measurement uses Linux monotonic timestamps")
    args.output.mkdir(parents=True, exist_ok=True)
    output = Path(tempfile.mkdtemp(prefix="desktop-", dir=args.output.resolve()))
    print(f"Evidence: {output}", flush=True)

    def state(role):
        return read_state(output / f"{role}.json")

    def ready(mode, page):
        states = [state(role) for role in ROLES]
        for current in states:
            model = current.get("state", {})
            transition = model.get("transition", {})
            if (not current.get("online") or not model.get("bothReady")
                    or current.get("mode") != mode
                    or (page and current.get("selectedApp") != page)
                    or current.get("serverTime", 0) < transition.get("startMs", 0)
                    + transition.get("durationMs", 0) + 100):
                return False
        return states[0]["state"]["sessionId"] == states[1]["state"]["sessionId"]

    def command(role, operation, **arguments):
        path = output / f"{role}.control.json"
        temporary = path.with_suffix(".new")
        sequence = uuid.uuid4().hex
        temporary.write_text(json.dumps({"sequence": sequence, "op": operation,
                                         "args": arguments}))
        temporary.replace(path)
        return sequence

    def capture(name):
        for role in ROLES:
            path = output / f"{name}-{role}.png"
            sequence = command(role, "screenshot", path=str(path))
            wait_for(lambda: complete_png(path) and state(role).get("controlResult") ==
                     {"sequence": sequence, "ok": True}, path.name)

    env = os.environ | {"MACANOS_FRAME_LOG_DIR": str(output),
                        "MACANOS_REDUCED_MOTION": "0"}
    launcher_args = [sys.executable, str(ROOT / "scripts/run-simulator.py"),
                     "--build", str(args.build.resolve()), "--state-dir", str(output),
                     "--width", str(args.width), "--height", str(args.height), "--port", "0"]
    with (output / "launcher.log").open("w") as log:
        launcher = subprocess.Popen(launcher_args, cwd=ROOT, env=env, stdout=log, stderr=log)
        try:
            wait_for(lambda: ready("INDEPENDENT", None), "both clients")
            capture("independent")
            for mode in ("SHARED", "UNIFIED"):
                command("passenger", "setMode", mode=mode)
                wait_for(lambda: ready(mode, None), mode)
                capture(mode.lower())
            command("passenger", "setUnifiedScene", scene="media")
            wait_for(lambda: ready("UNIFIED", "media"), "unified media")
            start = time.monotonic_ns()
            while time.monotonic_ns() - start < 8_000_000_000:
                if not ready("UNIFIED", "media"):
                    raise RuntimeError("A client left unified media during the timing sample")
                time.sleep(.1)
            end = time.monotonic_ns()
            capture("unified-media")
            if not ready("UNIFIED", "media"):
                raise RuntimeError("A client left unified media during screenshot capture")
            for role in ROLES:
                command(role, "quit")
                wait_for(lambda: (output / f"{role}-frames.txt").is_file(), f"{role} frame log")
            if launcher.wait(timeout=10) != 0:
                raise RuntimeError("Simulator launcher failed to shut down cleanly")
        finally:
            if launcher.poll() is None:
                launcher.terminate()
                launcher.wait(timeout=10)
    result = {
        "logicalWidth": args.width,
        "logicalHeight": args.height,
        "platform": env.get("QT_QPA_PLATFORM", "default"),
        "quickBackend": env.get("QT_QUICK_BACKEND", "default"),
        "scene": "unified media, both windows, reduced motion off",
        "seconds": round((end - start) / 1e9, 3),
        "roles": {
            role: metrics([int(line) for line in (output / f"{role}-frames.txt").read_text()
                           .splitlines()], start, end)
            for role in ROLES
        },
    }
    report = json.dumps(result, indent=2)
    (output / "timing.json").write_text(report + "\n")
    print(report)


if __name__ == "__main__":
    main()
