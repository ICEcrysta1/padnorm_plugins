#!/usr/bin/env python3
"""扫描 plugins/*/*/manifest.yaml 并生成 online_repo.yaml。"""

import sys
from pathlib import Path
from urllib.parse import quote

try:
    import yaml
except ImportError:
    sys.exit("缺少 PyYAML，请先执行：pip install pyyaml")

ROOT = Path(__file__).resolve().parents[1]
PLUGINS_DIR = ROOT / "plugins"
OUTPUT = ROOT / "online_repo.yaml"

# 插件清单的下载地址前缀，需与仓库实际托管位置一致
RAW_BASE = "https://raw.githubusercontent.com/ICEcrysta1/padnorm_plugins/refs/heads/main"

# 从清单中读取的字段；author 取自 plugins/<author>/<id> 目录
FIELDS = ("id", "guid", "version", "default_language", "license", "name", "description")


def load_entry(manifest_path):
    with manifest_path.open(encoding="utf-8") as f:
        manifest = yaml.safe_load(f)

    missing = [key for key in FIELDS if key not in manifest]
    if missing:
        raise SystemExit(f"{manifest_path} 缺少字段: {', '.join(missing)}")

    entry = {key: manifest[key] for key in ("id", "guid", "version")}
    entry["author"] = manifest_path.parents[1].name
    for key in ("default_language", "license", "name", "description"):
        entry[key] = manifest[key]
    # 中文等非 ASCII 路径需百分号编码，否则下载端可能无法请求
    rel_path = manifest_path.relative_to(ROOT).as_posix()
    entry["download_url"] = f"{RAW_BASE}/{quote(rel_path)}"
    return entry


def main():
    manifest_paths = sorted(PLUGINS_DIR.glob("*/*/manifest.yaml"))
    if not manifest_paths:
        raise SystemExit(f"未找到任何插件清单: {PLUGINS_DIR}")

    entries = [load_entry(path) for path in manifest_paths]
    with OUTPUT.open("w", encoding="utf-8", newline="\n") as f:
        yaml.safe_dump(entries, f, allow_unicode=True, sort_keys=False, width=100000)


if __name__ == "__main__":
    main()
