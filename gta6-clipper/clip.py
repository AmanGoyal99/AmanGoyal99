#!/usr/bin/env python3
"""Turn a moment from a landscape video into a 1080x1920 vertical clip.

Adds a hook line at the top, a credit line at the bottom and optional
burned-in captions. Needs ffmpeg on PATH. Use it only on footage you
recorded yourself or have permission to share.

One clip:
  python3 clip.py stream.mp4 --start 1:02:10 --end 1:02:38 \
      --hook "SHE DID NOT WAIT FOR JASON" --credit "@creator" -o out.mp4

Many clips from a CSV with columns input,start,end,hook,credit,out[,srt,mode]:
  python3 clip.py --plan plan.csv
"""
import argparse, csv, os, shutil, subprocess, sys, tempfile, textwrap

FONTS = [
    "/usr/share/fonts/opentype/inter/Inter-ExtraBold.otf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "C:/Windows/Fonts/arialbd.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
]


def seconds(ts):
    """'90', '1:30' or '1:02:10.5' -> seconds."""
    total = 0.0
    for part in str(ts).strip().split(":"):
        total = total * 60 + float(part)
    return total


def esc(path):
    """Escape a path for use inside an ffmpeg filter argument."""
    return path.replace("\\", "/").replace(":", "\\:").replace("'", "\\'")


def find_font(font):
    for f in ([font] if font else []) + FONTS:
        if f and os.path.exists(f):
            return f
    sys.exit("No bold font found. Pass one with --font /path/to/font.ttf")


def make_clip(src, start, end, hook, credit, out, srt=None, mode="blur", font=None):
    if not os.path.exists(src):
        sys.exit(f"Input not found: {src}")
    s, e = seconds(start), seconds(end)
    if e <= s:
        sys.exit(f"End ({end}) must be after start ({start})")
    font = esc(find_font(font))
    tmp = tempfile.mkdtemp(prefix="clip_")
    try:
        if mode == "crop":  # fill the frame, losing the sides
            chain = ["[0:v]scale=-2:1920,crop=1080:1920,setsar=1[base]"]
        else:               # full picture in the middle over a blurred copy
            chain = [
                "[0:v]split[a][b]",
                "[a]scale=1080:1920:force_original_aspect_ratio=increase,"
                "crop=1080:1920,boxblur=30:2,eq=brightness=-0.12[bg]",
                "[b]scale=1080:-2[fg]",
                "[bg][fg]overlay=(W-w)/2:(H-h)/2,setsar=1[base]",
            ]
        last = "base"
        if hook:
            lines = textwrap.wrap(hook.upper(), 20)[:3]
            for i, line in enumerate(lines):
                f = os.path.join(tmp, f"hook{i}.txt")
                open(f, "w", encoding="utf-8").write(line)
                chain.append(
                    f"[{last}]drawtext=fontfile='{font}':textfile='{esc(f)}':fontsize=84:"
                    f"fontcolor=white:borderw=7:bordercolor=black@0.9:"
                    f"x=(w-text_w)/2:y={250 + i * 104}[h{i}]")
                last = f"h{i}"
        if credit:
            f = os.path.join(tmp, "credit.txt")
            open(f, "w", encoding="utf-8").write(credit)
            chain.append(
                f"[{last}]drawtext=fontfile='{font}':textfile='{esc(f)}':fontsize=40:"
                f"fontcolor=white@0.95:borderw=4:bordercolor=black@0.8:"
                f"x=(w-text_w)/2:y=1480[cr]")
            last = "cr"
        if srt:
            chain.append(
                f"[{last}]subtitles='{esc(os.path.abspath(srt))}':force_style="
                "'FontName=Inter,Bold=1,FontSize=15,Outline=2,Alignment=2,MarginV=70'[sub]")
            last = "sub"
        cmd = ["ffmpeg", "-y", "-loglevel", "error", "-ss", str(s), "-i", src, "-t", str(e - s),
               "-filter_complex", ";".join(chain), "-map", f"[{last}]", "-map", "0:a?",
               "-c:v", "libx264", "-preset", "medium", "-crf", "19", "-pix_fmt", "yuv420p",
               "-r", "30", "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart", out]
        subprocess.run(cmd, check=True)
        print(f"wrote {out} ({e - s:.1f}s)")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("input", nargs="?")
    p.add_argument("--start"), p.add_argument("--end")
    p.add_argument("--hook", default=""), p.add_argument("--credit", default="")
    p.add_argument("--srt", help="caption file, timed from the start of the clip")
    p.add_argument("--mode", choices=["blur", "crop"], default="blur")
    p.add_argument("--font"), p.add_argument("-o", "--out", default="clip.mp4")
    p.add_argument("--plan", help="CSV of clips to make in one go")
    a = p.parse_args()
    if not shutil.which("ffmpeg"):
        sys.exit("ffmpeg is not installed or not on PATH")
    if a.plan:
        with open(a.plan, newline="", encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                make_clip(row["input"], row["start"], row["end"], row.get("hook", ""),
                          row.get("credit", ""), row["out"], row.get("srt") or None,
                          row.get("mode") or "blur", a.font)
    elif a.input and a.start and a.end:
        make_clip(a.input, a.start, a.end, a.hook, a.credit, a.out, a.srt, a.mode, a.font)
    else:
        p.error("give an input with --start and --end, or --plan")


if __name__ == "__main__":
    main()
