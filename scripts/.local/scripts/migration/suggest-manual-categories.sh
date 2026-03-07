#!/bin/bash
# Suggest PARA categories for manual review items

IRATTAR_DIR="$HOME/Irattár"
MAPPING_FILE="$HOME/Dokumentumok/1_Munkaterület/Területek/Adminisztráció/irattar-para-mapping.yaml"

echo "📋 Analyzing manual review categories..."
echo ""

# Find all remaining categories and suggest PARA placement
find "$IRATTAR_DIR" -maxdepth 2 -mindepth 2 -type d | while read -r dir; do
    category=$(basename "$dir")
    size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')

    # Suggest category based on name patterns
    suggestion=""

    # Programming/Tech tools
    if echo "$category" | grep -qiE "(Git|Github|Gimp|Inkscape|Fluxbox|Haskell|Golang|Wordpress|QML)"; then
        suggestion="Területek/Tudásbázis/Programozás/$category"

    # Companies/Projects
    elif echo "$category" | grep -qiE "(Adjkirály|KOFIR|Fodor|Active Ageing|SkyPort|TheraMed|TMSZK|Samsung|Matáv|KRE|RERI|Nyíregyháza|Seagate|Oracle|Globenet|Wirecorner|Orgware|Calypso|IKEA|IBM|Erste|Synergon|Netafim)"; then
        suggestion="Archívum/2020/Projektek/$category"

    # Government/Public sector
    elif echo "$category" | grep -qiE "(Önkormányzat|Nemzeti Vállalkozói|Microsoft.*eÖnkormányzat|eGov|EU|Tiszaújváros|Mezőkovácsháza|NAV|OSZK|OTP)"; then
        suggestion="Területek/Adminisztráció/$category"

    # Education/Training
    elif echo "$category" | grep -qiE "(Villámolvasás|NLP Intézet|Virtuális.*Akadémia|IQSoft|ITIL)"; then
        suggestion="Területek/Tudásbázis/Önfejlesztés/$category"

    # Science/Knowledge
    elif echo "$category" | grep -qiE "(Filozófia|Evolúció|Magyar őstörténet|Közgazdaságtan|Vallás|Madarak|Logika)"; then
        suggestion="Források/Téma_szerint/Tudomány/$category"

    # Business/Economics
    elif echo "$category" | grep -qiE "(Üzleti|CSR|Datacenter|IT\$|IPR|Horizon2020|Vezetői számvitel)"; then
        suggestion="Területek/Tudásbázis/Üzlet/$category"

    # Infrastructure/Services
    elif echo "$category" | grep -qiE "(Datacenter|GDrive|Smart metering|Vízgazdálkodás)"; then
        suggestion="Területek/Tudásbázis/Infrastruktúra/$category"

    # Personal/Misc
    elif echo "$category" | grep -qiE "(Machu Picchu|Gitár|Futás|Rajzolás|Észlény)"; then
        suggestion="Források/Téma_szerint/Hobbik/$category"

    # Politics (skip - sensitive)
    elif echo "$category" | grep -qiE "(Fidesz|Politika)"; then
        suggestion="SKIP - Sensitive/Political content"

    # Generic IT
    elif echo "$category" | grep -qiE "(IT|IGEN)"; then
        suggestion="Területek/Tudásbázis/IT/$category"

    # Unknown - need manual decision
    else
        suggestion="MANUAL - Need investigation"
    fi

    printf "%-50s %8s → %s\n" "$category" "$size" "$suggestion"

done | sort -k2 -rh

echo ""
echo "Legend:"
echo "  Területek/Tudásbázis/* - Ongoing knowledge areas"
echo "  Archívum/2020/Projektek/* - Completed projects"
echo "  Források/* - Reference materials"
echo "  SKIP - Should not be migrated"
echo "  MANUAL - Needs investigation"
