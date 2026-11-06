
import json
import sys
from pathlib import Path


def validate_sbom(file_path: str) -> None:
    path = Path(file_path)

    if not path.exists():
        print(f"ERROR: SBOM file does not exist: {path}")
        sys.exit(1)

    if path.stat().st_size == 0:
        print("ERROR: SBOM file is empty.")
        sys.exit(1)

    try:
        with path.open("r", encoding="utf-8") as file:
            sbom = json.load(file)
    except json.JSONDecodeError as error:
        print(f"ERROR: Invalid SBOM JSON: {error}")
        sys.exit(1)

    if not isinstance(sbom, dict):
        print("ERROR: SBOM root must be a JSON object.")
        sys.exit(1)

    if sbom.get("bomFormat") != "CycloneDX":
        print("ERROR: SBOM is not in CycloneDX format.")
        sys.exit(1)

    spec_version = sbom.get("specVersion")

    if not isinstance(spec_version, str) or not spec_version:
        print("ERROR: CycloneDX specification version is missing.")
        sys.exit(1)

    components = sbom.get("components")

    if not isinstance(components, list):
        print("ERROR: SBOM components must be a JSON array.")
        sys.exit(1)

    if not components:
        print("ERROR: SBOM contains no components.")
        sys.exit(1)

    serial_number = sbom.get("serialNumber")

    if not isinstance(serial_number, str) or not serial_number:
        print("ERROR: SBOM serial number is missing.")
        sys.exit(1)

    print("SBOM validation successful.")
    print(f"Format: {sbom['bomFormat']}")
    print(f"Specification: {spec_version}")
    print(f"Components: {len(components)}")
    print(f"Serial number: {serial_number}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python scripts/validate_sbom.py <sbom-file>")
        sys.exit(1)

    validate_sbom(sys.argv[1])
