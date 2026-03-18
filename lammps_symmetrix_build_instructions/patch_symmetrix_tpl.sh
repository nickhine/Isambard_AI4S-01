#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./patch_symmetrix_cuda_tpls.sh /path/to/symmetrix
#
# Example:
#   ./patch_symmetrix_cuda_tpls.sh /projects/u6ek/fraser/symmetrix

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/symmetrix" >&2
  exit 1
fi

symmetrix_root=$1
modules_dir="${symmetrix_root}/libsymmetrix/external/kokkos-kernels/cmake/Modules"

if [[ ! -d "$modules_dir" ]]; then
  echo "Could not find KokkosKernels CMake module directory:" >&2
  echo "  $modules_dir" >&2
  exit 1
fi

for tpl in CUBLAS CUSOLVER CUSPARSE; do
  file="${modules_dir}/FindTPL${tpl}.cmake"

  if [[ ! -f "$file" ]]; then
    echo "Missing file: $file" >&2
    exit 1
  fi

  cp -a "$file" "${file}.bak"

  lower=$(echo "$tpl" | tr '[:upper:]' '[:lower:]')

  sed -i "/list(GET kk_${lower}_include_dir_list 0 kk_${lower}_include_dir)/d" "$file"
  sed -i "s|HEADER_PATHS \${kk_${lower}_include_dir}|HEADER_PATHS \${kk_${lower}_include_dir_list}|g" "$file"

  echo "=== Diff for ${file} ==="
  diff -u "${file}.bak" "$file" || true
  echo
done

echo "Done. Backups saved as *.bak"
