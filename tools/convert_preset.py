#!/usr/bin/env python3
"""Convert ViPER4Windows v1 preset JSON files to the v2 unified preset format.

Run as:

    python3 convert_preset.py preset.json
    python3 convert_preset.py --out converted.json preset.json
    python3 convert_preset.py --out v2_dir/ v1_dir/
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any

MULTIBAND_COMPRESSOR_BAND_COUNT = 5
DYNAMIC_EQ_BAND_CAPACITY = 10

FORBIDDEN_KEYS = {"mode", "fxType", "isHeadphone", "fx_type"}
REQUIRED_TOP_LEVEL_KEYS = {
    "schemaVersion",
    "name",
    "createdAt",
    "masterLimiter",
    "playbackGainControl",
    "lufs",
    "fetCompressor",
    "multibandCompressor",
    "ddc",
    "spectrumExtension",
    "equalizer",
    "dynamicEq",
    "convolver",
    "fieldSurround",
    "diffSurround",
    "stereoImager",
    "headphoneSurround",
    "reverb",
    "dynamicSystem",
    "psychoacousticBass",
    "bass",
    "bassMono",
    "clarity",
    "cure",
    "tubeSimulator",
    "analogX",
    "speakerCorrection",
}

RANGES: dict[tuple[str, str], tuple[float, float]] = {
    ("masterLimiter", "threshold"): (30, 100),
    ("masterLimiter", "outputVolume"): (1, 200),
    ("masterLimiter", "channelPan"): (-100, 100),
    ("playbackGainControl", "strength"): (50, 300),
    ("playbackGainControl", "maxGain"): (100, 1000),
    ("playbackGainControl", "outputThreshold"): (30, 100),
    ("lufs", "target"): (80, 240),
    ("lufs", "maxGain"): (0, 120),
    ("lufs", "speed"): (0, 2),
    ("fetCompressor", "threshold"): (-48, 0),
    ("fetCompressor", "ratio"): (0, 200),
    ("fetCompressor", "knee"): (0, 12),
    ("fetCompressor", "kneeMulti"): (0, 100),
    ("fetCompressor", "gain"): (0, 24),
    ("fetCompressor", "attack"): (1, 100),
    ("fetCompressor", "maxAttack"): (1, 100),
    ("fetCompressor", "release"): (5, 500),
    ("fetCompressor", "maxRelease"): (5, 500),
    ("fetCompressor", "crest"): (5, 300),
    ("fetCompressor", "adapt"): (0, 200),
    ("multibandCompressor", "crossovers"): (30, 16000),
    ("multibandCompressor", "thresholds"): (-48, 0),
    ("multibandCompressor", "ratios"): (0, 200),
    ("multibandCompressor", "gains"): (0, 24),
    ("multibandCompressor", "knees"): (0, 12),
    ("multibandCompressor", "kneeMultis"): (0, 100),
    ("multibandCompressor", "attacks"): (1, 100),
    ("multibandCompressor", "maxAttacks"): (1, 100),
    ("multibandCompressor", "releases"): (5, 500),
    ("multibandCompressor", "maxReleases"): (5, 500),
    ("multibandCompressor", "crests"): (5, 300),
    ("multibandCompressor", "adapts"): (0, 200),
    ("spectrumExtension", "strength"): (2200, 8200),
    ("spectrumExtension", "exciter"): (0, 100),
    ("equalizer", "bands"): (-12.0, 12.0),
    ("dynamicEq", "freqs"): (20, 20000),
    ("dynamicEq", "qs"): (50, 800),
    ("dynamicEq", "gains"): (-120, 120),
    ("dynamicEq", "thresholds"): (-800, 0),
    ("dynamicEq", "attacks"): (1, 100),
    ("dynamicEq", "releases"): (10, 500),
    ("convolver", "crossChannel"): (0, 100),
    ("fieldSurround", "widening"): (0, 8),
    ("fieldSurround", "midImage"): (0, 10),
    ("fieldSurround", "depth"): (0, 10),
    ("diffSurround", "delay"): (1, 20),
    ("diffSurround", "wetDryMix"): (0, 100),
    ("diffSurround", "lpCutoff"): (0, 20000),
    ("stereoImager", "lowWidth"): (0, 200),
    ("stereoImager", "midWidth"): (0, 200),
    ("stereoImager", "highWidth"): (0, 200),
    ("stereoImager", "lowCrossover"): (80, 400),
    ("stereoImager", "highCrossover"): (2000, 8000),
    ("headphoneSurround", "quality"): (0, 4),
    ("reverb", "roomSize"): (0, 10),
    ("reverb", "width"): (0, 10),
    ("reverb", "damp"): (0, 10),
    ("reverb", "wet"): (0, 100),
    ("reverb", "dry"): (0, 100),
    ("dynamicSystem", "strength"): (0, 100),
    ("dynamicSystem", "xLow"): (0, 2400),
    ("dynamicSystem", "xHigh"): (0, 12000),
    ("dynamicSystem", "yLow"): (0, 200),
    ("dynamicSystem", "yHigh"): (0, 300),
    ("dynamicSystem", "sideGainLow"): (0, 100),
    ("dynamicSystem", "sideGainHigh"): (0, 100),
    ("psychoacousticBass", "cutoff"): (60, 150),
    ("psychoacousticBass", "intensity"): (0, 100),
    ("psychoacousticBass", "harmonicOrder"): (2, 5),
    ("psychoacousticBass", "originalLevel"): (0, 100),
    ("bass", "frequency"): (0, 135),
    ("bass", "gain"): (50, 1000),
    ("bassMono", "frequency"): (0, 135),
    ("bassMono", "gain"): (50, 1000),
    ("clarity", "gain"): (0, 450),
}


def _clamp_value(value: Any, lo: float, hi: float) -> Any:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return value
    return max(lo, min(hi, value))


def _clamp_ranges(v2: dict[str, Any]) -> dict[str, Any]:
    for (group, field), (lo, hi) in RANGES.items():
        grp = v2.get(group)
        if not isinstance(grp, dict) or field not in grp:
            continue
        val = grp[field]
        if isinstance(val, list):
            grp[field] = [_clamp_value(x, lo, hi) for x in val]
        else:
            grp[field] = _clamp_value(val, lo, hi)
    return v2


def _convert_master_limiter(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "threshold": int(v1.get("limiter", 100)),
        "outputVolume": int(v1.get("outputVolume", 100)),
        "channelPan": int(v1.get("channelPan", 0)),
    }


def _convert_playback_gain_control(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("playbackGainEnabled", False)),
        "strength": int(v1.get("playbackGainStrength", 50)),
        "maxGain": int(v1.get("playbackGainMaxGain", 100)),
        "outputThreshold": int(v1.get("playbackGainOutputThreshold", 100)),
    }


def _convert_lufs(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("lufsEnabled", False)),
        "target": int(v1.get("lufsTarget", 140)),
        "maxGain": int(v1.get("lufsMaxGain", 60)),
        "speed": int(v1.get("lufsSpeed", 1)),
    }


def _convert_fet_compressor(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("fetCompressorEnabled", False)),
        "threshold": int(v1.get("fetCompressorThreshold", -18)),
        "ratio": int(v1.get("fetCompressorRatio", 100)),
        "kneeAuto": bool(v1.get("fetCompressorAutoKnee", True)),
        "knee": int(v1.get("fetCompressorKnee", 0)),
        "kneeMulti": int(v1.get("fetCompressorKneeMulti", 0)),
        "gainAuto": bool(v1.get("fetCompressorAutoGain", True)),
        "gain": int(v1.get("fetCompressorGain", 0)),
        "attackAuto": bool(v1.get("fetCompressorAutoAttack", True)),
        "attack": int(v1.get("fetCompressorAttack", 1)),
        "maxAttack": int(v1.get("fetCompressorMaxAttack", 44)),
        "releaseAuto": bool(v1.get("fetCompressorAutoRelease", True)),
        "release": int(v1.get("fetCompressorRelease", 100)),
        "maxRelease": int(v1.get("fetCompressorMaxRelease", 200)),
        "crest": int(v1.get("fetCompressorCrest", 100)),
        "adapt": int(v1.get("fetCompressorAdapt", 50)),
        "noClip": bool(v1.get("fetCompressorNoClip", True)),
    }


def _ints_n(values: Any, n: int, default: int) -> list[int]:
    if not isinstance(values, list):
        return [default] * n
    out: list[int] = []
    for i in range(n):
        if i < len(values):
            try:
                out.append(int(values[i]))
            except (TypeError, ValueError):
                out.append(default)
        else:
            out.append(default)
    return out


def _bools_n(values: Any, n: int, default: bool) -> list[bool]:
    if not isinstance(values, list):
        return [default] * n
    return [bool(values[i]) if i < len(values) else default for i in range(n)]


def _convert_multiband_compressor(v1: dict[str, Any]) -> dict[str, Any]:
    n = MULTIBAND_COMPRESSOR_BAND_COUNT
    return {
        "enable": bool(v1.get("mbcEnabled", False)),
        "bandEnables": _bools_n(v1.get("mbcBandEnables"), n, True),
        # v1 ships exactly N-1 crossovers (lower edges between bands).
        "crossovers": _ints_n(
            v1.get("mbcCrossovers", [120, 500, 4000, 8000]), n - 1, 0
        ),
        "thresholds": _ints_n(v1.get("mbcThresholds"), n, -18),
        "ratios": _ints_n(v1.get("mbcRatios"), n, 50),
        "gains": _ints_n(v1.get("mbcGains"), n, 0),
        "knees": _ints_n(v1.get("mbcKnees"), n, 0),
        "kneeMultis": _ints_n(v1.get("mbcKneeMultis"), n, 0),
        "attacks": _ints_n(v1.get("mbcAttacks"), n, 1),
        "maxAttacks": _ints_n(v1.get("mbcMaxAttacks"), n, 44),
        "releases": _ints_n(v1.get("mbcReleases"), n, 100),
        "maxReleases": _ints_n(v1.get("mbcMaxReleases"), n, 200),
        "crests": _ints_n(v1.get("mbcCrests"), n, 100),
        "adapts": _ints_n(v1.get("mbcAdapts"), n, 50),
        "kneeAutos": _bools_n(v1.get("mbcAutoKnees"), n, True),
        "gainAutos": _bools_n(v1.get("mbcAutoGains"), n, True),
        "attackAutos": _bools_n(v1.get("mbcAutoAttacks"), n, True),
        "releaseAutos": _bools_n(v1.get("mbcAutoReleases"), n, True),
        "noClips": _bools_n(v1.get("mbcNoClips"), n, True),
    }


def _convert_ddc(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("ddcEnabled", False)),
        "device": str(v1.get("ddcFilePath", "")),
    }


def _convert_spectrum_extension(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("spectrumExtensionEnabled", False)),
        "strength": int(v1.get("spectrumExtensionBark", 7600)),
        "exciter": int(v1.get("spectrumExtensionExciter", 0)),
    }


def _convert_equalizer(v1: dict[str, Any]) -> dict[str, Any]:
    band_count = int(v1.get("equalizerBandCount", 10))
    raw_bands = v1.get("equalizerBands")
    if isinstance(raw_bands, list):
        bands = [float(b) for b in raw_bands]
    else:
        bands = [0.0] * band_count
    return {
        "enable": bool(v1.get("equalizerEnabled", False)),
        "bandCount": band_count,
        "bands": bands,
        "presetId": None,
    }


def _convert_dynamic_eq(v1: dict[str, Any]) -> dict[str, Any]:
    n = max(0, min(int(v1.get("dynEqBandCount", 3)), DYNAMIC_EQ_BAND_CAPACITY))
    return {
        "enable": bool(v1.get("dynEqEnabled", False)),
        "bandCount": int(v1.get("dynEqBandCount", 3)),
        "freqs": _ints_n(v1.get("dynEqFreqs"), n, 60),
        "qs": _ints_n(v1.get("dynEqQs"), n, 100),
        "gains": _ints_n(v1.get("dynEqGains"), n, 0),
        "thresholds": _ints_n(v1.get("dynEqThresholds"), n, -200),
        "attacks": _ints_n(v1.get("dynEqAttacks"), n, 10),
        "releases": _ints_n(v1.get("dynEqReleases"), n, 100),
        "filterTypes": _ints_n(v1.get("dynEqFilterTypes"), n, 0),
    }


def _convert_convolver(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("convolutionEnabled", False)),
        "kernelFile": str(v1.get("convolutionKernelPath", "")),
        "crossChannel": int(v1.get("convolutionCrossChannel", 0)),
    }


def _convert_field_surround(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("fieldSurroundEnabled", False)),
        "widening": int(v1.get("fieldSurroundWidening", 0)),
        "midImage": int(v1.get("fieldSurroundMidImage", 5)),
        "depth": int(v1.get("fieldSurroundDepth", 0)),
    }


def _convert_diff_surround(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("diffSurroundEnabled", False)),
        "delay": int(v1.get("diffSurroundDelay", 5)),
        "reverse": bool(v1.get("diffSurroundReverse", False)),
        "wetDryMix": int(v1.get("diffSurroundWetDryMix", 100)),
        "lpCutoff": int(v1.get("diffSurroundLpCutoff", 0)),
    }


def _convert_stereo_imager(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("stereoImagerEnabled", False)),
        "lowWidth": int(v1.get("stereoImagerLowWidth", 100)),
        "midWidth": int(v1.get("stereoImagerMidWidth", 100)),
        "highWidth": int(v1.get("stereoImagerHighWidth", 100)),
        "lowCrossover": int(v1.get("stereoImagerLowCrossover", 200)),
        "highCrossover": int(v1.get("stereoImagerHighCrossover", 4000)),
    }


def _convert_headphone_surround(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("vheEnabled", False)),
        "quality": int(v1.get("vheQuality", 0)),
    }


def _convert_reverb(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("reverberationEnabled", False)),
        "roomSize": int(v1.get("reverberationRoomSize", 0)),
        "width": int(v1.get("reverberationRoomWidth", 0)),
        "damp": int(v1.get("reverberationRoomDampening", 0)),
        "wet": int(v1.get("reverberationWetSignal", 0)),
        "dry": int(v1.get("reverberationDrySignal", 50)),
    }


def _convert_dynamic_system(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("dynamicSystemEnabled", False)),
        "presetId": None,
        "device": int(v1.get("dynamicSystemDevice", 0)),
        "strength": int(v1.get("dynamicSystemStrength", 50)),
        "xLow": int(v1.get("dsXLow", 100)),
        "xHigh": int(v1.get("dsXHigh", 5600)),
        "yLow": int(v1.get("dsYLow", 40)),
        "yHigh": int(v1.get("dsYHigh", 80)),
        "sideGainLow": int(v1.get("dsSideGainLow", 50)),
        "sideGainHigh": int(v1.get("dsSideGainHigh", 50)),
    }


def _convert_psychoacoustic_bass(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("psychoBassEnabled", False)),
        "cutoff": int(v1.get("psychoBassCutoff", 80)),
        "intensity": int(v1.get("psychoBassIntensity", 50)),
        "harmonicOrder": int(v1.get("psychoBassHarmonicOrder", 3)),
        "originalLevel": int(v1.get("psychoBassOriginalLevel", 100)),
    }


def _convert_bass(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("viperBassEnabled", False)),
        "mode": int(v1.get("viperBassMode", 0)),
        "frequency": int(v1.get("viperBassFrequency", 55)),
        "gain": int(v1.get("viperBassGain", 50)),
        "antiPop": bool(v1.get("viperBassAntiPop", True)),
    }


def _convert_bass_mono(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("viperBassMonoEnabled", False)),
        "mode": int(v1.get("viperBassMonoMode", 0)),
        "frequency": int(v1.get("viperBassMonoFrequency", 55)),
        "gain": int(v1.get("viperBassMonoGain", 50)),
        "antiPop": bool(v1.get("viperBassMonoAntiPop", True)),
    }


def _convert_clarity(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("viperClarityEnabled", False)),
        "mode": int(v1.get("viperClarityMode", 0)),
        "gain": int(v1.get("viperClarityGain", 50)),
    }


def _convert_cure(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("cureEnabled", False)),
        "crossfeedPreset": int(v1.get("cureCrossfeedStrength", 0)),
    }


def _convert_tube_simulator(v1: dict[str, Any]) -> dict[str, Any]:
    return {"enable": bool(v1.get("tubeSimulatorEnabled", False))}


def _convert_analog_x(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("analogXEnabled", False)),
        "mode": int(v1.get("analogXMode", 0)),
    }


def _convert_speaker_correction(v1: dict[str, Any]) -> dict[str, Any]:
    return {
        "enable": bool(v1.get("speakerCorrectionEnabled", False)),
    }


def convert_v1_to_v2(v1: dict[str, Any]) -> dict[str, Any]:
    name = v1.get("name", "")
    created_at = v1.get("createdAt", int(time.time() * 1000))
    if not isinstance(name, str):
        name = str(name)
    if not isinstance(created_at, int):
        try:
            created_at = int(created_at)
        except (TypeError, ValueError):
            created_at = int(time.time() * 1000)

    v2 = {
        "schemaVersion": 2,
        "name": name,
        "createdAt": created_at,
        "masterLimiter": _convert_master_limiter(v1),
        "playbackGainControl": _convert_playback_gain_control(v1),
        "lufs": _convert_lufs(v1),
        "fetCompressor": _convert_fet_compressor(v1),
        "multibandCompressor": _convert_multiband_compressor(v1),
        "ddc": _convert_ddc(v1),
        "spectrumExtension": _convert_spectrum_extension(v1),
        "equalizer": _convert_equalizer(v1),
        "dynamicEq": _convert_dynamic_eq(v1),
        "convolver": _convert_convolver(v1),
        "fieldSurround": _convert_field_surround(v1),
        "diffSurround": _convert_diff_surround(v1),
        "stereoImager": _convert_stereo_imager(v1),
        "headphoneSurround": _convert_headphone_surround(v1),
        "reverb": _convert_reverb(v1),
        "dynamicSystem": _convert_dynamic_system(v1),
        "psychoacousticBass": _convert_psychoacoustic_bass(v1),
        "bass": _convert_bass(v1),
        "bassMono": _convert_bass_mono(v1),
        "clarity": _convert_clarity(v1),
        "cure": _convert_cure(v1),
        "tubeSimulator": _convert_tube_simulator(v1),
        "analogX": _convert_analog_x(v1),
        "speakerCorrection": _convert_speaker_correction(v1),
    }
    return _clamp_ranges(v2)


def validate_v2(v2: dict[str, Any]) -> None:
    missing = REQUIRED_TOP_LEVEL_KEYS - set(v2.keys())
    if missing:
        raise ValueError(f"v2 output missing keys: {sorted(missing)}")
    if v2["schemaVersion"] != 2:
        raise ValueError(f"schemaVersion must be 2, got {v2['schemaVersion']!r}")

    forbidden_top = FORBIDDEN_KEYS & set(v2.keys())
    if forbidden_top:
        raise ValueError(
            f"v2 output contains forbidden top-level keys: {sorted(forbidden_top)}"
        )

    mbc = v2["multibandCompressor"]
    n = MULTIBAND_COMPRESSOR_BAND_COUNT
    for field in (
        "bandEnables",
        "thresholds",
        "ratios",
        "gains",
        "knees",
        "kneeMultis",
        "attacks",
        "maxAttacks",
        "releases",
        "maxReleases",
        "crests",
        "adapts",
        "kneeAutos",
        "gainAutos",
        "attackAutos",
        "releaseAutos",
        "noClips",
    ):
        if len(mbc[field]) != n:
            raise ValueError(
                f"multibandCompressor.{field} must have {n} entries, got {len(mbc[field])}"
            )
    if len(mbc["crossovers"]) != n - 1:
        raise ValueError(
            f"multibandCompressor.crossovers must have {n - 1} entries, "
            f"got {len(mbc['crossovers'])}"
        )

    dyn = v2["dynamicEq"]
    band_count = dyn["bandCount"]
    if not 1 <= band_count <= DYNAMIC_EQ_BAND_CAPACITY:
        raise ValueError(
            f"dynamicEq.bandCount must be 1..{DYNAMIC_EQ_BAND_CAPACITY}, got {band_count}"
        )
    for field in (
        "freqs",
        "qs",
        "gains",
        "thresholds",
        "attacks",
        "releases",
        "filterTypes",
    ):
        if len(dyn[field]) != band_count:
            raise ValueError(
                f"dynamicEq.{field} must have bandCount ({band_count}) entries, "
                f"got {len(dyn[field])}"
            )

    sc = v2["speakerCorrection"]
    if set(sc.keys()) != {"enable"}:
        raise ValueError(
            f"speakerCorrection must contain only 'enable' (SCHEMA.md §6.2), "
            f"got keys {sorted(sc.keys())}"
        )


def _read_input(source: str) -> dict[str, Any]:
    if source == "-":
        return json.loads(sys.stdin.read())
    with open(source, "r", encoding="utf-8") as fh:
        return json.load(fh)


def _write_output(target: str, v2: dict[str, Any], pretty: bool) -> None:
    indent = 2 if pretty else None
    separators = (",", ": ") if pretty else (",", ":")
    payload = json.dumps(v2, indent=indent, separators=separators, ensure_ascii=False)
    if target == "-":
        sys.stdout.write(payload)
        if pretty:
            sys.stdout.write("\n")
        return
    with open(target, "w", encoding="utf-8") as fh:
        fh.write(payload)
        if pretty:
            fh.write("\n")


def _convert_path(input_path: Path, output_path: Path, pretty: bool) -> None:
    v1 = _read_input(str(input_path))
    v2 = convert_v1_to_v2(v1)
    validate_v2(v2)
    _write_output(str(output_path), v2, pretty)


def _default_output_for_file(input_path: Path) -> Path:
    return input_path.with_suffix(".v2.json")


def _run(args: argparse.Namespace) -> int:
    pretty = args.pretty if args.pretty is not None else True

    if args.input == "-":
        v1 = _read_input("-")
        v2 = convert_v1_to_v2(v1)
        validate_v2(v2)
        target = args.out if args.out else "-"
        _write_output(target, v2, pretty)
        return 0

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"error: input not found: {input_path}", file=sys.stderr)
        return 2

    if input_path.is_file():
        if args.out:
            output_path = Path(args.out)
            if output_path.is_dir() or str(args.out).endswith(("/", "\\")):
                output_path.mkdir(parents=True, exist_ok=True)
                output_path = output_path / _default_output_for_file(input_path).name
        else:
            output_path = _default_output_for_file(input_path)
        _convert_path(input_path, output_path, pretty)
        print(f"converted: {input_path} -> {output_path}", file=sys.stderr)
        return 0

    if input_path.is_dir():
        if args.out:
            output_dir = Path(args.out)
        else:
            output_dir = input_path / "v2"
        output_dir.mkdir(parents=True, exist_ok=True)
        files = sorted(p for p in input_path.glob("*.json") if p.is_file())
        if not files:
            print(f"error: no .json files in directory: {input_path}", file=sys.stderr)
            return 2
        for f in files:
            target = output_dir / f"{f.stem}.v2.json"
            _convert_path(f, target, pretty)
            print(f"converted: {f} -> {target}", file=sys.stderr)
        return 0

    print(f"error: unsupported input type: {input_path}", file=sys.stderr)
    return 2


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Convert ViPER4Windows v1 preset JSON files to the v2 unified format.",
    )
    parser.add_argument(
        "input",
        help="Input v1 preset path (.json file, directory of .json files, or '-' for stdin).",
    )
    parser.add_argument(
        "--out",
        help=(
            "Output path. For a file input, default is '<input>.v2.json'. "
            "For a directory input, default is '<input>/v2/'. "
            "Use '-' to write the converted JSON to stdout (only with file/stdin input)."
        ),
    )
    fmt = parser.add_mutually_exclusive_group()
    fmt.add_argument(
        "--pretty",
        dest="pretty",
        action="store_true",
        default=None,
        help="Pretty-print output (default).",
    )
    fmt.add_argument(
        "--compact",
        dest="pretty",
        action="store_false",
        help="Generate minified JSON (matches ViPER4Windows on-disk format).",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return _run(args)


if __name__ == "__main__":
    raise SystemExit(main())
