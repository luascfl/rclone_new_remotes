#!/usr/bin/env python3
"""Exporta, aplica e verifica configuração do Obsidian entre Windows, Snap e .deb.

Escopo:
- Configuração global do app (obsidian.json e demais *.json no diretório do app).
- Configuração de cada vault (.obsidian), incluindo plugins e data.json do Remotely Save.

Comportamento de plataforma:
- Se source/target for windows em Linux, o script faz no-op e encerra sem alterar nada.
- Para snap e deb, o script sempre roda verificação de configuração antes da operação.

Uso rápido:
  python3 obsidian_profile_portability.py verify --kind snap
  python3 obsidian_profile_portability.py export --source auto --out /tmp/obsidian-bundle
  python3 obsidian_profile_portability.py apply  --target deb --bundle /tmp/obsidian-bundle
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


def is_windows_noop(kind: str) -> bool:
    return kind == "windows" and os.name != "nt"


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


def default_windows_app_dir() -> Path:
    if os.name != "nt":
        fail("Diretório padrão do Windows só é resolvido no próprio Windows")
    appdata = os.environ.get("APPDATA")
    if not appdata:
        fail("APPDATA não definido no Windows")
    return Path(appdata) / "Obsidian"


def windows_style_path(path: str) -> str:
    return path.replace("/", "\\")


def resolve_app_dir(kind: str, explicit_app_dir: str | None) -> Tuple[str, Path]:
    if explicit_app_dir:
        return kind, Path(explicit_app_dir).expanduser()

    if kind == "snap":
        return kind, DEFAULT_SNAP_APP_DIR
    if kind == "deb":
        return kind, DEFAULT_DEB_APP_DIR
    if kind == "windows":
        return kind, default_windows_app_dir()

    # auto
    if os.name == "nt":
        windows_dir = default_windows_app_dir()
        if windows_dir.exists():
            return "windows", windows_dir

    candidates = [
        ("snap", DEFAULT_SNAP_APP_DIR),
        ("deb", DEFAULT_DEB_APP_DIR),
    ]
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


def inspect_obsidian_config(kind: str, app_dir: Path) -> dict:
    report = {
        "kind": kind,
        "app_dir": str(app_dir),
        "skipped": False,
        "errors": [],
        "app_dir_exists": app_dir.exists(),
        "obsidian_json_exists": False,
        "obsidian_json_valid": False,
        "vault_total": 0,
        "vault_existing_path": 0,
        "vault_with_obsidian_dir": 0,
        "vault_with_remotely_save": 0,
        "vault_missing_paths": [],
        "ready": False,
    }

    if is_windows_noop(kind):
        report["skipped"] = True
        report["ready"] = True
        return report

    if not app_dir.exists():
        report["errors"].append("diretório do app não existe")
        return report

    obsidian_json_path = app_dir / "obsidian.json"
    if not obsidian_json_path.exists():
        report["errors"].append("obsidian.json não encontrado")
        return report

    report["obsidian_json_exists"] = True

    try:
        payload = json.loads(obsidian_json_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        report["errors"].append(f"obsidian.json inválido: {exc}")
        return report

    report["obsidian_json_valid"] = True

    vaults = payload.get("vaults", {})
    if not isinstance(vaults, dict):
        report["errors"].append("campo 'vaults' não é objeto")
        return report

    report["vault_total"] = len(vaults)

    for vault_id, vault_info in vaults.items():
        vault_path_raw = str(vault_info.get("path", "")).strip()
        if not vault_path_raw:
            report["vault_missing_paths"].append(f"{vault_id}:<vazio>")
            continue

        vault_path = Path(vault_path_raw).expanduser()
        if vault_path.exists():
            report["vault_existing_path"] += 1
        else:
            report["vault_missing_paths"].append(f"{vault_id}:{vault_path_raw}")
            continue

        obsidian_dir = vault_path / ".obsidian"
        if obsidian_dir.exists():
            report["vault_with_obsidian_dir"] += 1

            remotely_data = obsidian_dir / "plugins/remotely-save/data.json"
            if remotely_data.exists():
                report["vault_with_remotely_save"] += 1

    report["ready"] = report["obsidian_json_valid"]
    return report


def print_report(title: str, report: dict) -> None:
    log(f"{title} | kind={report['kind']} | app={report['app_dir']}")
    if report["skipped"]:
        log("Verificação ignorada: windows em Linux (no-op)")
        return

    log(
        "Resumo: "
        f"app_dir_exists={report['app_dir_exists']} "
        f"obsidian_json_exists={report['obsidian_json_exists']} "
        f"obsidian_json_valid={report['obsidian_json_valid']} "
        f"vault_total={report['vault_total']} "
        f"vault_existing_path={report['vault_existing_path']} "
        f"vault_with_obsidian_dir={report['vault_with_obsidian_dir']} "
        f"vault_with_remotely_save={report['vault_with_remotely_save']}"
    )

    for err in report["errors"]:
        log(f"Erro: {err}")

    missing = report["vault_missing_paths"]
    if missing:
        preview = ", ".join(missing[:5])
        suffix = " ..." if len(missing) > 5 else ""
        log(f"Vaults com path ausente/ inválido ({len(missing)}): {preview}{suffix}")


def verify_config(args: argparse.Namespace) -> None:
    if is_windows_noop(args.kind):
        log("kind=windows em Linux, nenhuma ação executada (no-op)")
        return

    kind, app_dir = resolve_app_dir(args.kind, args.app_dir)
    report = inspect_obsidian_config(kind, app_dir)
    print_report("Verificação", report)

    if args.strict and not report["ready"]:
        fail("Verificação falhou em modo --strict")


def export_bundle(args: argparse.Namespace) -> None:
    if is_windows_noop(args.source):
        log("source=windows em Linux, nenhuma ação executada (no-op)")
        return

    source_kind, app_dir = resolve_app_dir(args.source, args.app_dir)
    source_report = inspect_obsidian_config(source_kind, app_dir)
    print_report("Pré-verificação (export)", source_report)
    if not source_report["ready"]:
        fail("Configuração de origem inválida para exportar")

    obsidian_json_path = app_dir / "obsidian.json"
    obsidian_json = read_json(obsidian_json_path)

    out_dir = Path(args.out).expanduser()
    if out_dir.exists() and not args.force:
        fail(f"Diretório de saída já existe: {out_dir}. Use --force para sobrescrever")

    if out_dir.exists() and args.force and not args.dry_run:
        shutil.rmtree(out_dir)

    app_bundle = out_dir / "app"
    vaults_bundle = out_dir / "vaults"

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
    if is_windows_noop(args.target):
        log("target=windows em Linux, nenhuma ação executada (no-op)")
        return

    bundle_dir = Path(args.bundle).expanduser()
    if not bundle_dir.exists():
        fail(f"Bundle não encontrado: {bundle_dir}")

    app_bundle = bundle_dir / "app"
    vaults_bundle = bundle_dir / "vaults"
    source_obsidian_json = read_json(app_bundle / "obsidian.json")

    target_kind, target_app_dir = resolve_app_dir(args.target, args.app_dir)
    map_pairs = parse_map_entries(args.map or [])

    pre_report = inspect_obsidian_config(target_kind, target_app_dir)
    print_report("Pré-verificação (apply)", pre_report)

    if target_app_dir.exists():
        for existing_json in target_app_dir.glob("*.json"):
            backup_path(existing_json, args.dry_run)

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
        local_vault_path = Path(mapped_path).expanduser()

        if target_kind == "windows" and os.name == "nt":
            local_vault_path = Path(mapped_path)

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

    post_report = inspect_obsidian_config(target_kind, target_app_dir)
    print_report("Pós-verificação (apply)", post_report)

    log(f"Configuração aplicada em: {target_app_dir}")
    log(f"Vaults configurados: {len(target_vaults)}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Portabilidade de configuração do Obsidian (vaults, plugins e Remotely Save)"
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    verify_parser = subparsers.add_parser("verify", help="Verifica integridade da configuração")
    verify_parser.add_argument("--kind", choices=["auto", "snap", "deb", "windows"], default="auto")
    verify_parser.add_argument("--app-dir", help="Diretório do app Obsidian (override manual)")
    verify_parser.add_argument("--strict", action="store_true", help="Falha com exit code != 0 se inválido")

    export_parser = subparsers.add_parser("export", help="Exporta configuração para bundle")
    export_parser.add_argument("--source", choices=["auto", "snap", "deb", "windows"], default="auto")
    export_parser.add_argument("--app-dir", help="Diretório do app Obsidian (override manual)")
    export_parser.add_argument("--out", required=True, help="Diretório de saída do bundle")
    export_parser.add_argument("--force", action="store_true", help="Sobrescreve bundle existente")
    export_parser.add_argument("--dry-run", action="store_true", help="Simula sem escrever")

    apply_parser = subparsers.add_parser("apply", help="Aplica bundle em alvo")
    apply_parser.add_argument("--target", choices=["auto", "snap", "deb", "windows"], required=True)
    apply_parser.add_argument("--app-dir", help="Diretório do app Obsidian (override manual)")
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

    if args.command == "verify":
        verify_config(args)
    elif args.command == "export":
        export_bundle(args)
    elif args.command == "apply":
        apply_bundle(args)
    else:
        fail(f"Comando desconhecido: {args.command}")


if __name__ == "__main__":
    main()
