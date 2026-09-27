"""Bake Hue/Saturation tints into textures so a PSX-room .blend exports cleanly to glTF.

glTF can only store base colour as one constant RGBA or an image plugged straight
into Principled BSDF -> Base Color.  The room's materials tint a shared texture
through Blender "Hue/Saturation/Value" nodes, which the exporter cannot express, so
those materials came into Godot as plain white.

This script walks every material whose Base Color goes through a HUE_SAT node,
applies that node's hue/saturation/value to the upstream image (matching Blender's
linear-space maths), creates a new packed image, rewires the material to use it
directly and then exports a GLB.

Usage:
    blender -b PSX_Room_1987.blend -P tools/fix_blender_textures.py -- \
        assets/room.glb [PSX_Room_1987_fixed.blend]

If the optional second path is given the patched .blend is saved there too.
"""

import hashlib
import os
import sys

import bpy
import numpy as np

MAX_TINT_SIZE = 1024  # cap tinted copies so the GLB stays small


def log(*args):
    print("[fix-textures]", *args)


def srgb_to_linear(c):
    c = np.maximum(c, 0.0)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(c):
    c = np.clip(c, 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(c, 1.0 / 2.4) - 0.055)


def rgb_to_hsv(rgb):
    maxc = rgb.max(axis=1)
    minc = rgb.min(axis=1)
    delta = maxc - minc
    v = maxc
    s = np.where(maxc > 1e-8, delta / np.maximum(maxc, 1e-8), 0.0)
    r, g, b = rgb[:, 0], rgb[:, 1], rgb[:, 2]
    d = np.maximum(delta, 1e-8)
    h = np.zeros_like(maxc)
    is_r = (maxc == r) & (delta > 1e-8)
    is_g = (maxc == g) & (delta > 1e-8) & ~is_r
    is_b = (maxc == b) & (delta > 1e-8) & ~is_r & ~is_g
    h = np.where(is_r, ((g - b) / d) % 6.0, h)
    h = np.where(is_g, (b - r) / d + 2.0, h)
    h = np.where(is_b, (r - g) / d + 4.0, h)
    return (h / 6.0) % 1.0, s, v


def hsv_to_rgb(h, s, v):
    i = np.floor(h * 6.0).astype(np.int64) % 6
    f = h * 6.0 - np.floor(h * 6.0)
    p = v * (1.0 - s)
    q = v * (1.0 - s * f)
    t = v * (1.0 - s * (1.0 - f))
    r = np.choose(i, [v, q, p, p, t, v])
    g = np.choose(i, [t, v, v, q, p, p])
    b = np.choose(i, [p, p, t, v, v, q])
    return np.stack([r, g, b], axis=1)


def upstream_image(start_node):
    """Follow single-input links back from a Hue/Sat node to its image texture."""
    node = start_node
    for _ in range(16):
        if node.type == "TEX_IMAGE":
            return node
        src = next((i.links[0].from_node for i in node.inputs if i.is_linked), None)
        if src is None:
            return None
        node = src
    return None


def make_tinted(src, hue, sat, val, fac, name):
    w, h = src.size
    buf = np.empty(w * h * 4, dtype=np.float32)
    src.pixels.foreach_get(buf)
    rgba = buf.reshape(-1, 4)
    linear = srgb_to_linear(rgba[:, :3])
    hh, ss, vv = rgb_to_hsv(linear)
    hh = (hh + (hue - 0.5)) % 1.0
    ss = np.clip(ss * sat, 0.0, 1.0)
    vv = vv * val
    tinted = hsv_to_rgb(hh, ss, vv)
    linear = linear * (1.0 - fac) + tinted * fac
    rgba[:, :3] = linear_to_srgb(linear)

    new = bpy.data.images.new(name, width=w, height=h, alpha=True)
    new.colorspace_settings.name = src.colorspace_settings.name
    new.pixels.foreach_set(rgba.reshape(-1))
    if max(w, h) > MAX_TINT_SIZE:
        scale = MAX_TINT_SIZE / max(w, h)
        new.scale(max(1, round(w * scale)), max(1, round(h * scale)))
    new.pack()
    return new


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    blend_dir = os.path.dirname(bpy.data.filepath)
    out_glb = os.path.abspath(argv[0]) if argv else os.path.join(blend_dir, "assets", "room.glb")
    fixed_blend = os.path.abspath(argv[1]) if len(argv) > 1 else ""

    cache = {}
    fixed = 0
    skipped = 0

    for mat in bpy.data.materials:
        if not mat.use_nodes or mat.node_tree is None:
            continue
        nt = mat.node_tree
        bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if bsdf is None:
            continue
        base = bsdf.inputs.get("Base Color")
        if base is None or not base.is_linked:
            continue
        link = base.links[0]
        if link.from_node.type != "HUE_SAT":
            continue

        hue_sat = link.from_node
        tex = upstream_image(hue_sat)
        if tex is None or tex.image is None:
            log("skip (no image):", mat.name)
            skipped += 1
            continue
        try:
            tex.image.pixels[0]
        except Exception as exc:  # image data not available
            log("skip (image unreadable):", mat.name, exc)
            skipped += 1
            continue

        hue = hue_sat.inputs["Hue"].default_value
        sat = hue_sat.inputs["Saturation"].default_value
        val = hue_sat.inputs["Value"].default_value
        fac = hue_sat.inputs["Fac"].default_value
        key = (tex.image.name, round(hue, 4), round(sat, 4), round(val, 4), round(fac, 4))

        if key not in cache:
            digest = hashlib.md5(repr(key).encode("utf-8")).hexdigest()[:10]
            cache[key] = make_tinted(tex.image, hue, sat, val, fac, "tint_%s" % digest)
            log("baked", mat.name, "->", cache[key].name, "hue=%.2f sat=%.2f val=%.2f" % (hue, sat, val))

        tex.image = cache[key]
        nt.links.new(tex.outputs["Color"], base)
        fixed += 1

    log("materials fixed:", fixed, "skipped:", skipped, "new textures:", len(cache))

    os.makedirs(os.path.dirname(out_glb), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=out_glb,
        export_format="GLB",
        export_image_format="AUTO",
        export_materials="EXPORT",
        export_yup=True,
    )
    log("exported", out_glb, "(%d bytes)" % os.path.getsize(out_glb))

    if fixed_blend:
        bpy.ops.wm.save_as_mainfile(filepath=fixed_blend)
        log("saved patched blend", fixed_blend)


if __name__ == "__main__":
    main()
