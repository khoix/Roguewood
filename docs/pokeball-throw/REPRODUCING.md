# Reproducing the model and analysis

Run commands from `docs/pokeball-throw/`. The model and its seven tests use only
Python's standard library:

```sh
python3 -m unittest -v test_physics.py
python3 physics.py --swipe 1.2 3.0 --spin -0.8 > trajectory.csv
```

For the illustrative plot, install matplotlib and run `python3 demo_plot.py`.
The plot writes PNG and SVG files under `evidence/`. It does not compare against
gameplay recordings. The Unity 6 example requires a separate Unity project; it
is not a Godot script and has not been compiled or playtested in Unity.

## Optional static analysis

The helpers are specific to the ARM64 0.435.2/build 2026110702 artifacts. Do not
reuse their method indices, RVAs or asset IDs against another version. Exact
input sizes and SHA-256 hashes are in `evidence/provenance.json`. Its acquisition
URL contains `version=latest` and is a historical source record, not a permanent
version pin. Verify the hashes before applying these helpers.

Install the Python dependencies in a separate environment:

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements-analysis.txt
```

Supply these inputs locally; they are deliberately excluded from Git:

- `input/extracted/libil2cpp.so`: from the ARM64 split APK's
  `lib/arm64-v8a/libil2cpp.so`.
- `input/extracted/global-metadata.dat`: from the base APK's
  `assets/bin/Data/Managed/Metadata/global-metadata.dat`.
- `input/assets/`: the base APK's Unity `assets/bin/Data/` contents, preserving
  relative paths and associated asset files.
- `evidence/metadata.json`: REA 6.9.0's complete evidence JSON from
  `inspect_il2cpp_metadata` for that metadata file. Preserve the outer
  `normalized_result` field; the helpers read the tables inside it.

REA is available at <https://github.com/morluto/rea>. Use its metadata inspection
operation through its documented interface. REA's native-link step did not
successfully map this build; the custom ELF mapper below supplies that step.
The README records the failed attempts and avoids treating them as evidence.

With the matching inputs in place:

```sh
.venv/bin/python tools/map_methods.py
.venv/bin/python tools/read_types.py
.venv/bin/python tools/extract_assets.py
.venv/bin/python tools/annotate_asm.py
.venv/bin/python tools/verify_native_math.py
```

The mapper creates `evidence/method-map.json`; type reading creates `types.json`
and `signatures.tsv`. Asset extraction uses those types and writes extracted
property evidence plus intermediate binary records. Assembly annotation and
native verification consume the method map. Paths are relative to each script's
parent project directory, so relocating this folder does not require edits.

`verify_native_math.py` checks only 12 cases of the target-speed arithmetic
against the ARM64 instruction slice, with mocked gravity and libm calls. It
updates `evidence/native-math-validation.json`. It does not install or launch the
APK, connect to the game service, or validate the complete throw pipeline.

## Ghidra helper

`tools/DumpThrows.java` was used with Ghidra 12.2 and Java 25 on an imported ARM64
`libil2cpp.so`. It accepts a function-list TSV, an output directory and an optional
signature TSV (from `read_types.py`). Each function-list row is a hexadecimal RVA,
a tab, and a unique name ending in `_METHOD_INDEX`; append a tab and `target` to
functions selected for decompilation. Generate the list from the method map,
including adjacent function starts so the helper can establish boundaries.
The README identifies the important RVAs. The script adds the imported image
base to them. Use a disposable Ghidra project: with the signature argument, the
script removes existing function definitions before preparing selected targets.
The historical function lists and full decompiler project are not bundled.

The included evidence is sufficient to inspect the reported results without
these optional inputs. Regenerating native analysis requires the exact binaries
and metadata inventory; the standalone model tests do not.
