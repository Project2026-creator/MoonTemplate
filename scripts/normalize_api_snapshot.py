from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SNAPSHOT = ROOT / "src/moontemplate/pkg.generated.mbti"


def main() -> None:
    text = SNAPSHOT.read_text(encoding="utf-8")
    normalized = text.rstrip("\r\n") + "\n"
    if normalized != text:
        with SNAPSHOT.open("w", encoding="utf-8", newline="\n") as handle:
            handle.write(normalized)


if __name__ == "__main__":
    main()
