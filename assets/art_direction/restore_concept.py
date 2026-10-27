"""Restore the unchanged source concept from transport-sized base64 parts."""
from pathlib import Path
import base64
import hashlib

root = Path(__file__).resolve().parent
parts = sorted((root / "candidate-01-source").glob("*.b64"))
data = base64.b64decode("".join(p.read_text().strip() for p in parts), validate=True)
assert hashlib.sha256(data).hexdigest() == "df6b8de3e7189c1fadd713f2460352798a3f8ba51c30d16defcb7a6e1d66eb7b"
(root / "candidate-01.png").write_bytes(data)
print("Restored candidate-01.png; SHA256 verified")
