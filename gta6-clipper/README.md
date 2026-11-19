# gta6-clipper

Cuts a moment out of a landscape video and exports a 1080x1920 vertical clip
with a hook line, a credit line and optional burned-in captions.

Needs Python 3 and ffmpeg. Use it only on footage you recorded yourself or
have permission to share.

```
python3 clip.py stream.mp4 --start 1:02:10 --end 1:02:38 \
    --hook "SHE DID NOT WAIT FOR JASON" --credit "@creator" -o out.mp4
```

- `--mode blur` (default) keeps the whole picture over a blurred background.
- `--mode crop` fills the frame and cuts off the sides.
- `--srt captions.srt` burns in captions timed from the start of the clip.
- `--plan plan.csv` makes many clips; columns: `input,start,end,hook,credit,out` (optional `srt,mode`).
