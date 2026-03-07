#!/usr/bin/env python3
"""
Update YAML mapping file based on categorization suggestions
"""

import yaml
import re
from pathlib import Path

MAPPING_FILE = Path.home() / "Dokumentumok/1_Munkaterület/Területek/Adminisztráció/irattar-para-mapping.yaml"

def categorize(category: str) -> dict:
    """Categorize based on name patterns (same logic as suggest-manual-categories.sh)"""

    # Programming/Tech tools
    if re.search(r'(Github|Gimp|Inkscape|Fluxbox|Haskell|Golang|Wordpress|QML)$', category, re.I):
        return {
            'type': 'area',
            'dest': f'Területek/Tudásbázis/Programozás/{category}',
            'action': 'move',
            'notes': 'Programozási eszközök és technológiák'
        }

    # Git (exact match, not Gitár)
    if re.search(r'^Git$', category, re.I):
        return {
            'type': 'area',
            'dest': f'Területek/Tudásbázis/Programozás/{category}',
            'action': 'move',
            'notes': 'Verziókezelés'
        }

    # Companies/Projects (large list)
    if re.search(r'(Adjkirály|KOFIR|Fodor|Active Ageing|SkyPort|TheraMed|TMSZK|Samsung|Matáv|KRE|'
                 r'Nyíregyháza|Seagate|Globenet|Wirecorner|IKEA|Orgware|Calypso|IBM|Erste|'
                 r'Netafim|Synergon|RERI SaaS|Oracle)', category, re.I):
        return {
            'type': 'archive',
            'dest': f'Archívum/2020/Projektek/{category}',
            'action': 'move',
            'notes': 'Befejezett projekt (2020 előtti)'
        }

    # Government/Public sector
    if re.search(r'(Önkormányzat|Nemzeti Vállalkozói|Microsoft.*eÖnkormányzat|eGov|EU$|'
                 r'Tiszaújváros|Mezőkovácsháza|NAV|OSZK|OTP)', category, re.I):
        return {
            'type': 'area',
            'dest': f'Területek/Adminisztráció/{category}',
            'action': 'move',
            'notes': 'Közigazgatási dokumentumok'
        }

    # Education/Training
    if re.search(r'(Villámolvasás|NLP Intézet|Virtuális.*Akadémia|IQSoft|ITIL)', category, re.I):
        return {
            'type': 'area',
            'dest': f'Területek/Tudásbázis/Önfejlesztés/{category}',
            'action': 'move',
            'notes': 'Oktatás és képzés'
        }

    # Science/Knowledge
    if re.search(r'(Filozófia|Evolúció|Magyar őstörténet|Közgazdaságtan|Vallás|Madarak|Logika)',
                 category, re.I):
        return {
            'type': 'resource',
            'dest': f'Források/Téma_szerint/Tudomány/{category}',
            'action': 'move',
            'notes': 'Tudományos anyagok'
        }

    # Business/Economics
    if re.search(r'(Üzleti|CSR|IT$|IPR|Horizon2020|Vezetői számvitel|Kínai-magyar Üzleti)',
                 category, re.I):
        return {
            'type': 'area',
            'dest': f'Területek/Tudásbázis/Üzlet/{category}',
            'action': 'move',
            'notes': 'Üzleti anyagok'
        }

    # Infrastructure/Services
    if re.search(r'(Datacenter|GDrive|Smart metering|Vízgazdálkodás)', category, re.I):
        return {
            'type': 'area',
            'dest': f'Területek/Tudásbázis/Infrastruktúra/{category}',
            'action': 'move',
            'notes': 'Infrastruktúra és szolgáltatások'
        }

    # Personal/Misc hobbies
    if re.search(r'(Machu Picchu|Gitár|Futás|Rajzolás|Észlény)', category, re.I):
        return {
            'type': 'resource',
            'dest': f'Források/Téma_szerint/Hobbik/{category}',
            'action': 'move',
            'notes': 'Hobbi anyagok'
        }

    # Generic IT (but not "IT$" which was matched above)
    if re.search(r'(IGEN|Militia)', category, re.I):
        return {
            'type': 'area',
            'dest': f'Területek/Tudásbázis/IT/{category}',
            'action': 'move',
            'notes': 'IT anyagok'
        }

    # Politics (skip - sensitive)
    if re.search(r'(Fidesz|Politika)', category, re.I):
        return {
            'type': 'manual',
            'dest': f'SKIP/{category}',
            'action': 'skip',
            'notes': 'SKIP - Politikai tartalom, nem kerül migrálásra'
        }

    # Anitilla (special case - coaching/training)
    if re.search(r'Anitilla', category, re.I):
        return {
            'type': 'area',
            'dest': f'Területek/Tudásbázis/Önfejlesztés/{category}',
            'action': 'move',
            'notes': 'Coaching és tréning'
        }

    # Unknown - keep as manual
    return None

def main():
    print("📝 Updating YAML mapping file based on suggestions...")

    # Load YAML
    with open(MAPPING_FILE, 'r') as f:
        data = yaml.safe_load(f)

    updated_count = 0
    skipped_count = 0
    manual_count = 0

    # Update mappings
    for mapping in data['mappings']:
        if mapping.get('type') == 'manual' and mapping.get('action') == 'skip':
            category = mapping['source']
            suggestion = categorize(category)

            if suggestion:
                # Update the mapping
                mapping['type'] = suggestion['type']
                mapping['dest'] = suggestion['dest']
                mapping['action'] = suggestion['action']
                mapping['notes'] = suggestion['notes']
                updated_count += 1
                print(f"✅ Updated: {category} → {suggestion['dest']}")
            else:
                # Keep as manual
                manual_count += 1
                print(f"⚠️  Manual: {category} (needs investigation)")
        else:
            skipped_count += 1

    # Save updated YAML
    with open(MAPPING_FILE, 'w') as f:
        # Write header comment
        f.write("# Irattár → PARA Migration Mapping\n")
        f.write("# Updated with automated categorization suggestions\n")
        f.write("#\n")
        f.write("# Format:\n")
        f.write("#   source: Path relative to ~/Irattár\n")
        f.write("#   dest: Path relative to ~/Dokumentumok/1_Munkaterület\n")
        f.write("#   type: project | area | resource | archive\n")
        f.write("#   action: move | copy | skip\n")
        f.write("#   notes: Optional notes\n\n")

        # Write mappings
        yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

    print(f"\n✅ YAML file updated!")
    print(f"   Updated: {updated_count} categories")
    print(f"   Still manual: {manual_count} categories")
    print(f"   Already processed: {skipped_count} categories")
    print(f"\n📄 File: {MAPPING_FILE}")

if __name__ == '__main__':
    main()
