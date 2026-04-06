#!/usr/bin/env python3
"""Exporta e aplica configuração do Obsidian entre Windows, Snap e .deb.

Escopo:
- Configuração global do app (obsidian.json e demais *.json no diretório do app).
- Configuração de cada vault (.obsidian), incluindo plugins e data.json do Remotely Save.

Uso rápido:
  python3 obsidian_profile_portability.py export --source auto --out /tmp/obsidian-bundle
  python3 obsidian_profile_portability.py apply  --target deb  --bundle /tmp/obsidian-bundle
  python3 obsidian_profile_portability.py apply  --target snap --bundle /tmp/obsidian-bundle
  python3 obsidian_profile_portability.py apply  --target windows \
      --bundle /tmp/obsidian-bundle \
      --windows-root /mnt \
      --map '/home/lucas/Documentos/ObsidianLocal=C:\\Users\\Lucas\\Documents\\ObsidianLocal'
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import shutil
import sys
from pathlib import Path
from typing import Dict, Iterable, List, Tuple


DEFAULT_SNAP_APP_DIR = Path.home() / "snap/obsidian/current/.config/obsidian"
DEFAULT_DEB_APP_DIR = Path.home() / ".config/obsidian"


def now_ts() -> str:
    return dt.datetime.now().strftime("%Y%m%d-%H%M%S")


def log(msg: str) -> None:
    print(f"[obsidian-portability] {msg}")


def fail(msg: str, code: int = 1) -> None:
    print(f"[obsidian-portability][erro] {msg}", file=sys.stderr)
    raise SystemExit(code)


def parse_map_entries(entries: Iterable[str]) -> List[Tuple[str, str]]:
    pairs: List[Tuple[str, str]] = []
    for raw in entries:
        if "=" not in raw:
            fail(f"Mapeamento inválido '{raw}'. Use FORMATO antigo=novo")
        old, new = raw.split("=", 1)
        old = old.strip()
        new = new.strip()
        if not old or not new:
            fail(f"Mapeamento inválido '{raw}'. Lados antigo e novo são obrigatórios")
        pairs.append((old, new))
    return pairs


def replace_prefix(text: str, pairs: List[Tuple[str, str]]) -> str:
    for old, new in pairs:
        if text == old or text.startswith(old.rstrip("/") + "/"):
            suffix = text[len(old.rstrip("/")) :]
            return new.rstrip("/") + suffix
    return text


def default_windows_app_dir(windows_user: str | None = None) -> Path:
    if os.name == "nt":
        appdata = os.environ.get("APPDATA")
        if not appdata:
            fail("APPDATA não definido no Windows")
        return Path(appdata) / "Obsidian"

    if not windows_user:
        fail("No Linux, informe --windows-user para resolver diretório do Obsidian no Windows")
    return Path("C:/") / "Users" / windows_user / "AppData/Roaming/Obsidian"


def windows_style_path(path: str) -> str:
    return path.replace("/", "\\")


def windows_to_posix_path(win_path: str, windows_root: Path) -> Path:
    normalized = win_path.replace("/", "\\")
    if len(normalized) < 3 or normalized[1:3] != ":\\":
        fail(
            f"Caminho Windows inválido '{win_path}'. Use formato como C:\\Users\\..."
        )
    drive = normalized[0].lower()
    rest = normalized[3:].replace("\\", "/")
    return windows_root / drive / rest


def resolve_app_dir(
    kind: str,
    explicit_app_dir: str | None,
    windows_user: str | None,
) -> Tuple[str, Path]:
    if explicit_app_dir:
        return kind, Path(explicit_app_dir).expanduser()

    if kind == "snap":
        return kind, DEFAULT_SNAP_APP_DIR
    if kind == "deb":
        return kind, DEFAULT_DEB_APP_DIR
    if kind == "windows":
        return kind, default_windows_app_dir(windows_user)

    # auto
    candidates = [
        ("snap", DEFAULT_SNAP_APP_DIR),
        ("deb", DEFAULT_DEB_APP_DIR),
    ]

    if os.name == "nt":
        candidates.insert(0, ("windows", default_windows_app_dir(windows_user)))

    for candidate_kind, candidate_path in candidates:
        if candidate_path.exists():
            return candidate_kind, candidate_path

    fail(
        "Não foi possível detectar instalação do Obsidian. Use --source/--target explícito e --app-dir"
    )
    raise AssertionError("unreachable")


def read_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"Arquivo não encontrado: {path}")
    except json.JSONDecodeError as exc:
        fail(f"JSON inválido em {path}: {exc}")
    raise AssertionError("unreachable")


def write_json(path: Path, payload: dict, dry_run: bool) -> None:
    if dry_run:
        log(f"[dry-run] escrever JSON em {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def backup_path(path: Path, dry_run: bool) -> Path | None:
    if not path.exists():
        return None
    backup = path.parent / f"{path.name}.backup-{now_ts()}"
    if dry_run:
        log(f"[dry-run] backup {path} -> {backup}")
        return backup
    shutil.move(str(path), str(backup))
    return backup


def copy_tree(src: Path, dst: Path, dry_run: bool) -> None:
    if not src.exists():
        fail(f"Origem não encontrada: {src}")
    if dry_run:
        log(f"[dry-run] copiar árvore {src} -> {dst}")
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(src, dst, dirs_exist_ok=True)


def copy_file(src: Path, dst: Path, dry_run: bool) -> None:
    if not src.exists():
        fail(f"Arquivo origem não encontrado: {src}")
    if dry_run:
        log(f"[dry-run] copiar arquivo {src} -> {dst}")
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def export_bundle(args: argparse.Namespace) -> None:
    source_kind, app_dir = resolve_app_dir(args.source, args.app_dir, args.windows_user)
    obsidian_json_path = app_dir / "obsidian.json"
    obsidian_json = read_json(obsidian_json_path)

    out_dir = Path(args.out).expanduser()
    if out_dir.exists() and not args.force:
        fail(f"Diretório de saída já existe: {out_dir}. Use --force para sobrescrever")

    if out_dir.exists() and args.force and not args.dry_run:
        shutil.rmtree(out_dir)

    app_bundle = out_dir / "app"
    vaults_bundle = out_dir / "vaults"

    # Copia JSONs globais do app (obsidian.json, <vaultid>.json etc.)
    for candidate in app_dir.glob("*.json"):
        copy_file(candidate, app_bundle / candidate.name, args.dry_run)

    vaults_info: Dict[str, dict] = obsidian_json.get("vaults", {})
    exported = 0
    skipped = 0

    for vault_id, info in vaults_info.items():
        vault_path = Path(info.get("path", "")).expanduser()
        obsidian_dir = vault_path / ".obsidian"
        bundle_target = vaults_bundle / vault_id / ".obsidian"
        if obsidian_dir.exists():
            copy_tree(obsidian_dir, bundle_target, args.dry_run)
            exported += 1
        else:
            skipped += 1
            log(f"Aviso: vault '{vault_id}' sem pasta .obsidian em {obsidian_dir}")

    manifest = {
        "created_at": dt.datetime.now().isoformat(),
        "source_kind": source_kind,
        "source_app_dir": str(app_dir),
        "vault_count": len(vaults_info),
        "exported_vault_count": exported,
        "skipped_vault_count": skipped,
    }
    write_json(out_dir / "manifest.json", manifest, args.dry_run)

    log(f"Bundle exportado em: {out_dir}")
    log(f"Vaults exportados: {exported}, ignorados: {skipped}")


def resolve_target_vault_path(
    original_path: str,
    target_kind: str,
    map_pairs: List[Tuple[str, str]],
) -> str:
    mapped = replace_prefix(original_path, map_pairs)

    if target_kind == "windows":
        mapped = windows_style_path(mapped)

    return mapped


def apply_bundle(args: argparse.Namespace) -> None:
    bundle_dir = Path(args.bundle).expanduser()
    if not bundle_dir.exists():
        fail(f"Bundle não encontrado: {bundle_dir}")

    app_bundle = bundle_dir / "app"
    vaults_bundle = bundle_dir / "vaults"
    source_obsidian_json = read_json(app_bundle / "obsidian.json")

    target_kind, target_app_dir = resolve_app_dir(args.target, args.app_dir, args.windows_user)
    map_pairs = parse_map_entries(args.map or [])

    if target_kind == "windows" and os.name != "nt":
        if not args.windows_root:
            fail("Para aplicar no Windows a partir do Linux, informe --windows-root (ex: /mnt)")
        windows_root = Path(args.windows_root).expanduser()
    else:
        windows_root = None

    # Backup dos JSONs globais do app
    if target_app_dir.exists():
        for existing_json in target_app_dir.glob("*.json"):
            backup_path(existing_json, args.dry_run)

    # Copia JSONs globais do bundle, exceto obsidian.json (será reescrito com paths mapeados)
    for bundled_json in app_bundle.glob("*.json"):
        if bundled_json.name == "obsidian.json":
            continue
        copy_file(bundled_json, target_app_dir / bundled_json.name, args.dry_run)

    source_vaults: Dict[str, dict] = source_obsidian_json.get("vaults", {})
    target_vaults: Dict[str, dict] = {}

    for vault_id, vault_info in source_vaults.items():
        original_path = str(vault_info.get("path", "")).strip()
        if not original_path:
            log(f"Aviso: vault '{vault_id}' sem path válido. Ignorando")
            continue

        mapped_path = resolve_target_vault_path(original_path, target_kind, map_pairs)

        if target_kind == "windows":
            if os.name == "nt":
                local_vault_path = Path(mapped_path)
            else:
                local_vault_path = windows_to_posix_path(mapped_path, windows_root)  # type: ignore[arg-type]
        else:
            local_vault_path = Path(mapped_path).expanduser()

        if not local_vault_path.exists():
            if args.create_missing_vaults:
                if args.dry_run:
                    log(f"[dry-run] criar vault ausente: {local_vault_path}")
                else:
                    local_vault_path.mkdir(parents=True, exist_ok=True)
            else:
                log(
                    f"Aviso: vault '{vault_id}' não existe em {local_vault_path}. Use --create-missing-vaults para criar"
                )
                continue

        target_obsidian_dir = local_vault_path / ".obsidian"
        backup_path(target_obsidian_dir, args.dry_run)

        source_obsidian_dir = vaults_bundle / vault_id / ".obsidian"
        if source_obsidian_dir.exists():
            copy_tree(source_obsidian_dir, target_obsidian_dir, args.dry_run)
        else:
            log(f"Aviso: bundle sem .obsidian para vault '{vault_id}'")

        target_vaults[vault_id] = {
            **vault_info,
            "path": mapped_path,
        }

    rewritten = {
        **source_obsidian_json,
        "vaults": target_vaults,
    }
    write_json(target_app_dir / "obsidian.json", rewritten, args.dry_run)

    log(f"Configuração aplicada em: {target_app_dir}")
    log(f"Vaults configurados: {len(target_vaults)}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Portabilidade de configuração do Obsidian (vaults, plugins e Remotely Save)"
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    export_parser = subparsers.add_parser("export", help="Exporta configuração para bundle")
    export_parser.add_argument("--source", choices=["auto", "snap", "deb", "windows"], default="auto")
    export_parser.add_argument("--app-dir", help="Diretório do app Obsidian (override manual)")
    export_parser.add_argument("--windows-user", help="Usuário Windows (quando source=windows em Linux)")
    export_parser.add_argument("--out", required=True, help="Diretório de saída do bundle")
    export_parser.add_argument("--force", action="store_true", help="Sobrescreve bundle existente")
    export_parser.add_argument("--dry-run", action="store_true", help="Simula sem escrever")

    apply_parser = subparsers.add_parser("apply", help="Aplica bundle em alvo")
    apply_parser.add_argument("--target", choices=["auto", "snap", "deb", "windows"], required=True)
    apply_parser.add_argument("--app-dir", help="Diretório do app Obsidian (override manual)")
    apply_parser.add_argument("--windows-user", help="Usuário Windows para resolver AppData")
    apply_parser.add_argument(
        "--windows-root",
        help="Raiz dos drives Windows no Linux (ex: /mnt, onde C: vira /mnt/c)",
    )
    apply_parser.add_argument("--bundle", required=True, help="Diretório do bundle exportado")
    apply_parser.add_argument(
        "--map",
        action="append",
        help="Mapeia prefixo de path: antigo=novo (pode repetir)",
    )
    apply_parser.add_argument(
        "--create-missing-vaults",
        action="store_true",
        help="Cria pastas de vault ausentes no destino",
    )
    apply_parser.add_argument("--dry-run", action="store_true", help="Simula sem escrever")

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "export":
        export_bundle(args)
    elif args.command == "apply":
        apply_bundle(args)
    else:
        fail(f"Comando desconhecido: {args.command}")


if __name__ == "__main__":
    main()
