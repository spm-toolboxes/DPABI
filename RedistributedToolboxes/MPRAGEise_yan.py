#!/usr/bin/env python3
"""
MPRAGEise_yan.py

Compatibility version of MPRAGEise for environments where only AFNI's
`3dUnifize` is available. This variant adds safer defaults for United Imaging
5T eT1W/UNI data by:

1. Optionally applying the vendor-recommended UNI rescaling internally
   (equivalent to: fslmaths UNI -add 500 -mul 4 -thr 0 -min 4095)
2. Using robust percentile-based normalization of the estimated bias field
3. Clipping negative bias factors and zeroing obvious background voxels

It remains backward-compatible with standard INV2 + UNI inputs.
"""

import argparse
import datetime
import os
import shutil
import subprocess
import sys
from pathlib import Path

import nibabel as nib
import numpy as np

os.environ["AFNI_NIFTI_TYPE_WARN"] = "NO"
os.environ["AFNI_ENVIRON_WARNINGS"] = "NO"

VERBOSE = False


def log(message):
    if VERBOSE:
        print(message)


def get_afni_version():
    """Return a best-effort AFNI version string."""
    for cmd in (["afni", "-ver"], ["3dUnifize", "-help"]):
        try:
            result = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=False,
            )
        except FileNotFoundError:
            continue

        output = (result.stdout or result.stderr).strip()
        if output:
            first_line = output.splitlines()[0].strip()
            return first_line
    return "Unknown"


def parse_arguments():
    italic_start = "\033[3m"
    italic_end = "\033[0m"
    epilog_text = (
        f"{italic_start}Nota bene:{italic_end}\n"
        f"   {italic_start}1. The default output is set to the directory of the INV2 image.{italic_end}\n"
        f"   {italic_start}2. This compatibility version supports NIfTI inputs (.nii/.nii.gz).{italic_end}\n"
        f"   {italic_start}3. Do not use this script for the MP2RAGE T1 map.{italic_end}\n"
        f"   {italic_start}4. For United Imaging 5T raw eT1W/UNI with negative values, UNI rescaling can be done internally.{italic_end}\n"
    )
    parser = argparse.ArgumentParser(
        description=(
            "Background denoise MP2RAGE UNI images (MPRAGEising) whilst either "
            "removing or reintroducing the bias field."
        ),
        epilog=epilog_text,
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument(
        "-i",
        "--inv2",
        required=True,
        help="MP2RAGE INV2 image (NIfTI: .nii or .nii.gz).",
    )
    parser.add_argument(
        "-u",
        "--uni",
        required=True,
        help="MP2RAGE UNI / eT1W image (NIfTI: .nii or .nii.gz).",
    )
    parser.add_argument(
        "-r",
        "--re_bias",
        default="0",
        help="Reintroduce bias-field (default=0, optional).",
    )
    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help="Output folder for processed files.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        default=False,
        help="Overwrite existing output files.",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        default=False,
        help="Enable verbose logging of command execution and debug information.",
    )

    parser.add_argument(
        "--uni-adjust-mode",
        choices=["auto", "none", "umr5t"],
        default="auto",
        help=(
            "Internal preprocessing for UNI/eT1W before MPRAGEising.\n"
            "  auto  : apply uMR 5T-style rescaling only if UNI contains negative values (default)\n"
            "  none  : do not rescale UNI\n"
            "  umr5t : always apply (UNI + offset) * scale, then clip"
        ),
    )
    parser.add_argument(
        "--uni-offset",
        type=float,
        default=500.0,
        help="Offset used in internal UNI rescaling (default=500).",
    )
    parser.add_argument(
        "--uni-scale",
        type=float,
        default=4.0,
        help="Scale used in internal UNI rescaling (default=4).",
    )
    parser.add_argument(
        "--uni-clip-min",
        type=float,
        default=0.0,
        help="Minimum UNI value after internal rescaling (default=0).",
    )
    parser.add_argument(
        "--uni-clip-max",
        type=float,
        default=4095.0,
        help="Maximum UNI value after internal rescaling (default=4095).",
    )
    parser.add_argument(
        "--save-adjusted-uni",
        action="store_true",
        default=False,
        help="Save the internally adjusted UNI image for QC.",
    )

    parser.add_argument(
        "--bias-norm-mode",
        choices=["robust", "minmax"],
        default="robust",
        help=(
            "How to normalize the estimated bias field.\n"
            "  robust : use percentiles inside foreground support (default)\n"
            "  minmax : use simple min/max inside foreground support"
        ),
    )
    parser.add_argument(
        "--bias-p-low",
        type=float,
        default=1.0,
        help="Lower percentile for robust bias normalization (default=1).",
    )
    parser.add_argument(
        "--bias-p-high",
        type=float,
        default=99.0,
        help="Upper percentile for robust bias normalization (default=99).",
    )
    parser.add_argument(
        "--bias-clip-min",
        type=float,
        default=0.0,
        help="Lower clipping bound for normalized bias (default=0).",
    )
    parser.add_argument(
        "--bias-clip-max",
        type=float,
        default=2.0,
        help="Upper clipping bound for normalized bias (default=2). Use a negative value to disable.",
    )
    parser.add_argument(
        "--keep-background",
        action="store_true",
        default=False,
        help="Do not force obvious background voxels to zero in the output.",
    )
    return parser.parse_args()


def get_basename_and_extension(filename):
    if filename.endswith(".nii.gz"):
        return os.path.basename(filename)[:-7], ".nii.gz"
    if filename.endswith(".nii"):
        return os.path.basename(filename)[:-4], ".nii"
    raise ValueError(
        f"Unsupported input format for '{filename}'. "
        "This compatibility script only supports .nii and .nii.gz files."
    )


def ensure_exists(path_str, label):
    if not os.path.exists(path_str):
        sys.exit(f"Error: {label} does not exist: {path_str}")


def ensure_command_available(command_name):
    cmd_path = shutil.which(command_name)
    if not cmd_path:
        sys.exit(
            f"Error: Required command '{command_name}' was not found in PATH. "
            "This compatibility script still requires AFNI's 3dUnifize."
        )
    log(f"Using {command_name} at {cmd_path}")


def run_command(cmd):
    log("Running command: " + " ".join(cmd))
    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
    except FileNotFoundError as exc:
        sys.exit(f"Error: External command not found: {exc.filename}")

    if VERBOSE:
        print("Command stdout:", result.stdout)
        print("Command stderr:", result.stderr)

    if result.returncode != 0:
        print("Error running command:", " ".join(cmd))
        print("Stdout:", result.stdout)
        print("Stderr:", result.stderr)
        sys.exit(1)
    return result.stdout.strip()


def load_nifti(path_str):
    try:
        image = nib.load(path_str)
    except Exception as exc:
        sys.exit(f"Error: Unable to read NIfTI image '{path_str}': {exc}")
    data = image.get_fdata(dtype=np.float32)
    return image, data


def save_like(reference_img, data, output_path, overwrite=False):
    if os.path.exists(output_path) and not overwrite:
        sys.exit(
            f"Error: Output file already exists: {output_path}. "
            "Use --overwrite to replace it."
        )

    out_header = reference_img.header.copy()
    out_image = nib.Nifti1Image(
        np.asarray(data, dtype=np.float32),
        reference_img.affine,
        out_header,
    )
    out_image.set_data_dtype(np.float32)
    nib.save(out_image, output_path)
    log(f"Saved image: {output_path}")


def remove_if_exists(path_str):
    try:
        if os.path.exists(path_str):
            os.remove(path_str)
            log(f"Removed temporary file: {path_str}")
    except Exception as exc:
        print(f"Warning: Could not remove temporary file {path_str}: {exc}")


def validate_compatible(inv2_img, uni_img, inv2_path, uni_path):
    if inv2_img.shape != uni_img.shape:
        sys.exit(
            "Error: INV2 and UNI images have different shapes: "
            f"{inv2_path} {inv2_img.shape} vs {uni_path} {uni_img.shape}"
        )


def preprocess_uni(uni_data, mode, offset, scale, clip_min, clip_max):
    finite_mask = np.isfinite(uni_data)
    if not np.any(finite_mask):
        sys.exit("Error: UNI image contains no finite voxels.")

    data_min = float(np.nanmin(uni_data))
    data_max = float(np.nanmax(uni_data))
    log(f"UNI intensity range before preprocessing: min={data_min}, max={data_max}")

    apply_umr5t = False
    if mode == "umr5t":
        apply_umr5t = True
    elif mode == "auto":
        apply_umr5t = data_min < 0

    if apply_umr5t:
        log(
            "Applying internal UNI rescaling: "
            f"(UNI + {offset}) * {scale}, then clip to [{clip_min}, {clip_max}]"
        )
        out = (uni_data + offset) * scale
        out = np.clip(out, clip_min, clip_max)
        return out, "umr5t"

    log("Leaving UNI intensities unchanged.")
    return uni_data.copy(), "none"


def compute_support_mask(inv2_data, uni_data):
    finite = np.isfinite(inv2_data) & np.isfinite(uni_data)
    if not np.any(finite):
        sys.exit("Error: No finite overlapping voxels between INV2 and UNI.")

    uni_vals = uni_data[finite]
    uni_floor = float(np.percentile(uni_vals, 2.0))
    support = finite & (uni_data > uni_floor)

    # Fall back to a simpler finite mask if the support becomes too small.
    support_fraction = float(np.count_nonzero(support)) / float(np.count_nonzero(finite))
    if support_fraction < 0.05:
        inv2_vals = inv2_data[finite]
        inv2_floor = float(np.percentile(inv2_vals, 5.0))
        support = finite & ((uni_data > uni_floor) | (inv2_data > inv2_floor))

    support_fraction = float(np.count_nonzero(support)) / float(np.count_nonzero(finite))
    log(
        f"Foreground support uses {np.count_nonzero(support)} voxels "
        f"({support_fraction * 100:.2f}% of finite overlap)."
    )
    return support


def compute_normalized_bias(
    inv2_data,
    bfc_data,
    support_mask,
    mode="robust",
    p_low=1.0,
    p_high=99.0,
    clip_min=0.0,
    clip_max=2.0,
):
    vals = bfc_data[support_mask]
    vals = vals[np.isfinite(vals)]
    if vals.size == 0:
        sys.exit("Error: No valid voxels available to estimate the normalized bias field.")

    if mode == "robust":
        low = float(np.percentile(vals, p_low))
        high = float(np.percentile(vals, p_high))
    else:
        low = float(np.min(vals))
        high = float(np.max(vals))

    if not np.isfinite(low) or not np.isfinite(high) or high <= low:
        sys.exit(
            "Error: Invalid bias normalization range. "
            f"low={low}, high={high}"
        )

    log(f"Bias normalization range ({mode}): low={low}, high={high}")
    normalized = (bfc_data - low) / (high - low)

    if clip_min is not None:
        normalized = np.maximum(normalized, clip_min)
    if clip_max is not None and clip_max >= 0:
        normalized = np.minimum(normalized, clip_max)

    normalized[~np.isfinite(normalized)] = 0.0
    return normalized


def maybe_zero_background(output_data, support_mask, keep_background=False):
    if keep_background:
        return output_data
    out = output_data.copy()
    out[~support_mask] = 0.0
    return out


def main():
    global VERBOSE

    args = parse_arguments()
    VERBOSE = args.verbose

    if args.overwrite:
        print(
            "\n++++ WARNING: The --overwrite option is enabled; existing output files may be overwritten.\n"
        )

    inv2_image = args.inv2
    uni_image = args.uni
    re_bias = args.re_bias.strip() != "0"

    ensure_exists(inv2_image, "INV2 image")
    ensure_exists(uni_image, "UNI image")
    ensure_command_available("3dUnifize")

    inv2_basename, file_ext = get_basename_and_extension(inv2_image)
    uni_basename, _ = get_basename_and_extension(uni_image)

    if args.output is None:
        output_folder = os.path.dirname(os.path.abspath(inv2_image))
    else:
        output_folder = args.output

    Path(output_folder).mkdir(parents=True, exist_ok=True)
    if not os.access(output_folder, os.W_OK):
        sys.exit(f"Error: Output folder '{output_folder}' is not writable.")

    print()
    print("--------------------------------------")
    print("  MPRAGEise compat (uMR5T-aware) runs.")
    print("--------------------------------------")
    print()
    print("AFNI Version:", get_afni_version())
    print("Run Date:", datetime.datetime.now().strftime("%c"))
    print()
    print("Input files:")
    print("  INV2 image:", inv2_image)
    print("  UNI image :", uni_image)

    bfc_prefix = os.path.join(output_folder, f"{inv2_basename}_bfc{file_ext}")
    if re_bias:
        print("\n++++ Reintroducing bias-field.")
        bfc_path = inv2_image
        out_name = os.path.join(output_folder, f"{uni_basename}_rebiased_clean{file_ext}")
    else:
        print("\n++++ Removing bias-field.")
        run_command(["3dUnifize", "-quiet", "-prefix", bfc_prefix, inv2_image])
        bfc_path = bfc_prefix
        out_name = os.path.join(output_folder, f"{uni_basename}_unbiased_clean{file_ext}")

    inv2_img, inv2_data = load_nifti(inv2_image)
    uni_img, uni_data = load_nifti(uni_image)
    bfc_img, bfc_data = load_nifti(bfc_path)

    validate_compatible(inv2_img, uni_img, inv2_image, uni_image)
    validate_compatible(inv2_img, bfc_img, inv2_image, bfc_path)

    preprocessed_uni, uni_adjust_applied = preprocess_uni(
        uni_data,
        mode=args.uni_adjust_mode,
        offset=args.uni_offset,
        scale=args.uni_scale,
        clip_min=args.uni_clip_min,
        clip_max=args.uni_clip_max,
    )

    if args.save_adjusted_uni and uni_adjust_applied != "none":
        adjusted_uni_name = os.path.join(output_folder, f"{uni_basename}_internally_adjusted{file_ext}")
        save_like(uni_img, preprocessed_uni, adjusted_uni_name, overwrite=args.overwrite)

    support_mask = compute_support_mask(inv2_data, preprocessed_uni)

    normalized_bias = compute_normalized_bias(
        inv2_data,
        bfc_data,
        support_mask=support_mask,
        mode=args.bias_norm_mode,
        p_low=args.bias_p_low,
        p_high=args.bias_p_high,
        clip_min=args.bias_clip_min,
        clip_max=args.bias_clip_max,
    )

    print("\n++++ MPRAGEising the UNI image.")
    output_data = preprocessed_uni * normalized_bias
    output_data = maybe_zero_background(
        output_data,
        support_mask=support_mask,
        keep_background=args.keep_background,
    )
    output_data[~np.isfinite(output_data)] = 0.0
    save_like(uni_img, output_data, out_name, overwrite=args.overwrite)

    if not re_bias:
        remove_if_exists(bfc_prefix)

    print("\n++++ Done.\n")
    print(f"UNI adjustment applied: {uni_adjust_applied}")
    print(f"Output file: {out_name}")
    print()


if __name__ == "__main__":
    main()
