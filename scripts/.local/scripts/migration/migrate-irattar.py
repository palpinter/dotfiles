#!/usr/bin/env python3
"""
Irattár → PARA Migration Script
Migrates files from ~/Irattár to PARA structure based on YAML mapping file
"""

import os
import sys
import yaml
import shutil
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List

# Color codes
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'

class IrattarMigrator:
    def __init__(self, mapping_file: str, dry_run: bool = True):
        self.dry_run = dry_run
        self.mapping_file = Path(mapping_file)
        self.home = Path.home()
        self.irattar_dir = self.home / "Irattár"
        self.para_dir = self.home / "Dokumentumok/1_Munkaterület"

        # Logs and rollback
        self.log_dir = self.home / ".local/backups/logs"
        self.log_dir.mkdir(parents=True, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.log_file = self.log_dir / f"irattar-migration-{timestamp}.log"
        self.rollback_file = self.log_dir / f"irattar-rollback-{timestamp}.sh"

        # Statistics
        self.stats = {
            'total': 0,
            'skipped': 0,
            'moved': 0,
            'copied': 0,
            'errors': 0,
            'manual_review': 0
        }

    def log(self, message: str, level: str = "INFO"):
        """Write to log file and optionally print"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] [{level}] {message}"

        with open(self.log_file, 'a') as f:
            f.write(log_entry + '\n')

        # Print with colors
        if level == "ERROR":
            print(f"{Colors.RED}{message}{Colors.NC}")
        elif level == "WARNING":
            print(f"{Colors.YELLOW}{message}{Colors.NC}")
        elif level == "SUCCESS":
            print(f"{Colors.GREEN}{message}{Colors.NC}")
        else:
            print(message)

    def add_rollback_entry(self, src: Path, dest: Path, action: str):
        """Add rollback command to rollback script"""
        with open(self.rollback_file, 'a') as f:
            if action == "move":
                f.write(f"# Rollback: {src} → {dest}\n")
                f.write(f"mv \"{dest}\" \"{src}\"\n\n")
            elif action == "copy":
                f.write(f"# Rollback: copied {src} → {dest}\n")
                f.write(f"rm -rf \"{dest}\"\n\n")

    def load_mapping(self) -> List[Dict]:
        """Load YAML mapping file"""
        try:
            with open(self.mapping_file, 'r') as f:
                data = yaml.safe_load(f)
                return data.get('mappings', [])
        except Exception as e:
            self.log(f"Error loading mapping file: {e}", "ERROR")
            sys.exit(1)

    def find_category_in_irattar(self, category_name: str) -> Path:
        """Find category in alphabetic Irattár structure"""
        # Try to find the category in alphabetic subdirectories
        for alpha_dir in self.irattar_dir.iterdir():
            if alpha_dir.is_dir():
                category_path = alpha_dir / category_name
                if category_path.exists():
                    return category_path

        # Not found
        return self.irattar_dir / category_name

    def migrate_category(self, mapping: Dict) -> bool:
        """Migrate a single category"""
        source_rel = mapping['source']
        dest_rel = mapping['dest']
        action = mapping.get('action', 'move')
        mtype = mapping.get('type', 'unknown')

        # Find category in alphabetic structure
        category_name = source_rel
        source = self.find_category_in_irattar(category_name)
        dest = self.para_dir / dest_rel

        self.stats['total'] += 1

        # Skip manual review items
        if mtype == 'manual' or action == 'skip':
            self.log(f"SKIP: {source_rel} (manual review needed)", "WARNING")
            self.stats['manual_review'] += 1
            self.stats['skipped'] += 1
            return True

        # Check if source exists
        if not source.exists():
            self.log(f"ERROR: Source not found: {source}", "ERROR")
            self.stats['errors'] += 1
            return False

        # Prepare destination
        dest.parent.mkdir(parents=True, exist_ok=True)

        # Check if dest already exists
        if dest.exists():
            self.log(f"WARNING: Destination exists: {dest}", "WARNING")
            dest = dest.parent / f"{dest.name}_irattar_migration"
            self.log(f"  → Renamed to: {dest.name}", "WARNING")

        # Dry run mode
        if self.dry_run:
            self.log(f"DRY-RUN: {action.upper()} {source_rel} → {dest_rel}", "INFO")
            self.stats[f"{action}d" if action == 'move' or action == 'copy' else 'skipped'] += 1
            return True

        # Execute migration
        try:
            if action == 'move':
                self.log(f"MOVE: {source} → {dest}", "SUCCESS")
                shutil.move(str(source), str(dest))
                self.add_rollback_entry(source, dest, 'move')
                self.stats['moved'] += 1

            elif action == 'copy':
                self.log(f"COPY: {source} → {dest}", "SUCCESS")
                if source.is_dir():
                    shutil.copytree(str(source), str(dest))
                else:
                    shutil.copy2(str(source), str(dest))
                self.add_rollback_entry(source, dest, 'copy')
                self.stats['copied'] += 1

            return True

        except Exception as e:
            self.log(f"ERROR: Failed to {action} {source}: {e}", "ERROR")
            self.stats['errors'] += 1
            return False

    def run(self):
        """Execute migration"""
        mode = "DRY-RUN" if self.dry_run else "LIVE"
        print(f"{Colors.BLUE}{'='*50}{Colors.NC}")
        print(f"{Colors.BLUE}📦 Irattár → PARA Migration ({mode} MODE){Colors.NC}")
        print(f"{Colors.BLUE}{'='*50}{Colors.NC}\n")

        self.log(f"Starting migration in {mode} mode")
        self.log(f"Mapping file: {self.mapping_file}")
        self.log(f"Source: {self.irattar_dir}")
        self.log(f"Destination: {self.para_dir}")

        # Initialize rollback script
        with open(self.rollback_file, 'w') as f:
            f.write("#!/bin/bash\n")
            f.write("# Irattár Migration Rollback Script\n")
            f.write(f"# Generated: {datetime.now()}\n\n")
            f.write("set -e\n\n")

        os.chmod(self.rollback_file, 0o755)

        # Load mappings
        mappings = self.load_mapping()
        print(f"Loaded {len(mappings)} categories from mapping file\n")

        # Process each mapping
        for i, mapping in enumerate(mappings, 1):
            print(f"[{i}/{len(mappings)}] Processing: {mapping['source']}")
            self.migrate_category(mapping)

        # Print statistics
        print(f"\n{Colors.BLUE}{'='*50}{Colors.NC}")
        print(f"{Colors.BLUE}📊 Migration Statistics{Colors.NC}")
        print(f"{Colors.BLUE}{'='*50}{Colors.NC}")
        print(f"Total categories:      {self.stats['total']}")
        print(f"  → Moved:             {self.stats['moved']}")
        print(f"  → Copied:            {self.stats['copied']}")
        print(f"  → Skipped:           {self.stats['skipped']}")
        print(f"  → Manual review:     {self.stats['manual_review']}")
        print(f"  → Errors:            {self.stats['errors']}")
        print(f"{Colors.BLUE}{'='*50}{Colors.NC}\n")

        if not self.dry_run:
            print(f"{Colors.GREEN}✅ Migration completed!{Colors.NC}")
            print(f"Log file: {self.log_file}")
            print(f"Rollback script: {self.rollback_file}\n")
        else:
            print(f"{Colors.YELLOW}💡 This was a dry-run. No files were moved.{Colors.NC}")
            print(f"To execute migration, run with --live flag\n")

        if self.stats['manual_review'] > 0:
            print(f"{Colors.YELLOW}⚠️  {self.stats['manual_review']} categories need manual review{Colors.NC}")
            print(f"{Colors.YELLOW}   Update mapping file and re-run migration{Colors.NC}\n")

def main():
    parser = argparse.ArgumentParser(
        description='Migrate Irattár to PARA structure')

    parser.add_argument(
        '--mapping',
        default=str(Path.home() / 'Dokumentumok/1_Munkaterület/Területek/Adminisztráció/irattar-para-mapping.yaml'),
        help='Path to YAML mapping file')

    parser.add_argument(
        '--live',
        action='store_true',
        help='Execute migration (default is dry-run)')

    args = parser.parse_args()

    # Confirmation for live mode
    if args.live:
        print(f"{Colors.RED}⚠️  WARNING: You are about to execute LIVE migration!{Colors.NC}")
        print(f"{Colors.RED}   This will move 45GB of files (55,058 files){Colors.NC}\n")

        response = input("Are you sure you want to continue? (type 'yes' to confirm): ")
        if response.lower() != 'yes':
            print("Migration cancelled.")
            sys.exit(0)

    # Run migration
    migrator = IrattarMigrator(args.mapping, dry_run=not args.live)
    migrator.run()

if __name__ == '__main__':
    main()
