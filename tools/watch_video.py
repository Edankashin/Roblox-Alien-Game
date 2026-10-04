#!/usr/bin/env python3
"""Turn a short video into things a text-and-image reader can consume.

For each input video this writes, under <outdir>/<stem>/:
  frames/f_0001.jpg ...   one frame per second (scaled to 540px wide)
  sheet_01.jpg ...        contact sheets, 4x4 tiles, 16 seconds each, with timestamps
  audio.wav               16 kHz mono audio
  transcript.txt          speech-to-text (sherpa-onnx whisper if a model is present,
                          otherwise pocketsphinx), with coarse timestamps
  info.json               duration, resolution, which STT backend ran

Usage: python3 tools/watch_video.py <video.mp4> [more.mp4 ...] [--out media/tiktok/out]
"""
import json
import os
import pathlib
import shutil
import subprocess
import sys
import wave


def run(cmd):
    return subprocess.run(cmd, check=True, capture_output=True, text=True)


def probe(path):
    out = run([
        "ffprobe", "-v", "error", "-select_streams", "v:0",
        "-show_entries", "stream=width,height:format=duration",
        "-of", "json", str(path),
    ]).stdout
    data = json.loads(out)
    stream = (data.get("streams") or [{}])[0]
    duration = float(data.get("format", {}).get("duration", 0) or 0)
    return stream.get("width"), stream.get("height"), duration


def extract_frames(video, frames_dir, fps=1.0):
    frames_dir.mkdir(parents=True, exist_ok=True)
    run([
        "ffmpeg", "-y", "-v", "error", "-i", str(video),
        "-vf", f"fps={fps},scale=540:-2",
        "-q:v", "3", str(frames_dir / "f_%04d.jpg"),
    ])
    return sorted(frames_dir.glob("f_*.jpg"))


def contact_sheets(video, outdir, fps=1.0, tiles=4):
    """4x4 sheets, each covering tiles*tiles seconds, with a timestamp burned in."""
    per_sheet = tiles * tiles
    run([
        "ffmpeg", "-y", "-v", "error", "-i", str(video),
        "-vf",
        (
            f"fps={fps},scale=360:-2,"
            "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:"
            "text='%{pts\\:hms}':x=8:y=8:fontsize=22:fontcolor=white:box=1:boxcolor=black@0.6,"
            f"tile={tiles}x{tiles}"
        ),
        "-q:v", "3", str(outdir / "sheet_%02d.jpg"),
    ])
    return sorted(outdir.glob("sheet_*.jpg")), per_sheet


def extract_audio(video, wav_path):
    run([
        "ffmpeg", "-y", "-v", "error", "-i", str(video),
        "-vn", "-ac", "1", "-ar", "16000", "-f", "wav", str(wav_path),
    ])


def stt_sherpa(wav_path):
    """Whisper via sherpa-onnx if a model dir is available (env SHERPA_WHISPER_DIR)."""
    model_dir = os.environ.get("SHERPA_WHISPER_DIR")
    if not model_dir or not os.path.isdir(model_dir):
        return None
    try:
        import sherpa_onnx  # noqa: F401
    except ImportError:
        return None
    d = pathlib.Path(model_dir)
    enc = next(d.glob("*encoder*.onnx"), None)
    dec = next(d.glob("*decoder*.onnx"), None)
    tok = next(d.glob("*tokens*.txt"), None)
    if not (enc and dec and tok):
        return None
    import sherpa_onnx
    rec = sherpa_onnx.OfflineRecognizer.from_whisper(
        encoder=str(enc), decoder=str(dec), tokens=str(tok),
        num_threads=2, language="en", task="transcribe",
    )
    # whisper models take <=30 s windows; chunk the file
    with wave.open(str(wav_path)) as w:
        sr = w.getframerate()
        frames = w.readframes(w.getnframes())
    import array
    samples = array.array("h", frames)
    floats = [s / 32768.0 for s in samples]
    chunk = 30 * sr
    lines = []
    for i in range(0, len(floats), chunk):
        piece = floats[i:i + chunk]
        s = rec.create_stream()
        s.accept_waveform(sr, piece)
        rec.decode_stream(s)
        text = s.result.text.strip()
        if text:
            lines.append(f"[{i // sr:>4d}s] {text}")
    return "sherpa-onnx whisper", "\n".join(lines)


def stt_pocketsphinx(wav_path):
    try:
        from pocketsphinx import AudioFile
    except ImportError:
        return None
    lines = []
    for phrase in AudioFile(audio_file=str(wav_path)):
        seg_start = None
        for seg in phrase.seg():
            seg_start = seg.start_frame / 100.0
            break
        text = str(phrase).strip()
        if text:
            stamp = f"[{int(seg_start):>4d}s] " if seg_start is not None else ""
            lines.append(stamp + text)
    return "pocketsphinx (low accuracy; cross-check against on-screen captions)", "\n".join(lines)


def process(video, out_root, fps):
    video = pathlib.Path(video)
    outdir = out_root / video.stem
    if outdir.exists():
        shutil.rmtree(outdir)
    outdir.mkdir(parents=True)
    w, h, dur = probe(video)
    frames = extract_frames(video, outdir / "frames", fps)
    sheets, per_sheet = contact_sheets(video, outdir, fps)
    wav = outdir / "audio.wav"
    extract_audio(video, wav)
    result = stt_sherpa(wav) or stt_pocketsphinx(wav) or ("none", "")
    backend, text = result
    (outdir / "transcript.txt").write_text(text + "\n", encoding="utf-8")
    info = {
        "video": str(video), "width": w, "height": h, "duration_s": round(dur, 1),
        "frames": len(frames), "sheets": [p.name for p in sheets],
        "seconds_per_sheet": per_sheet / fps, "stt_backend": backend,
    }
    (outdir / "info.json").write_text(json.dumps(info, indent=2), encoding="utf-8")
    print(f"{video.name}: {dur:.1f}s, {len(frames)} frames, {len(sheets)} sheets, stt={backend}")
    return info


def main(argv):
    out_root = pathlib.Path("media/tiktok/out")
    fps = 1.0
    videos = []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--out":
            out_root = pathlib.Path(argv[i + 1]); i += 2; continue
        if a == "--fps":
            fps = float(argv[i + 1]); i += 2; continue
        videos.append(a); i += 1
    if not videos:
        print(__doc__); return 1
    out_root.mkdir(parents=True, exist_ok=True)
    for v in videos:
        process(v, out_root, fps)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
