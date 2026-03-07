#!/bin/bash
# Generate YAML mapping file for Irattár → PARA migration

set -e

IRATTAR_DIR="$HOME/Irattár"
OUTPUT_DIR="$HOME/Dokumentumok/1_Munkaterület/Területek/Adminisztráció"
MAPPING_FILE="$OUTPUT_DIR/irattar-para-mapping.yaml"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📝 Generating Irattár → PARA mapping file...${NC}"
echo -e "${BLUE}Source: $IRATTAR_DIR${NC}"
echo -e "${BLUE}Output: $MAPPING_FILE${NC}\n"

# Create mapping file header
cat > "$MAPPING_FILE" << 'YAMLEOF'
# Irattár → PARA Migration Mapping
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
#
# Format:
#   source: Path relative to ~/Irattár
#   dest: Path relative to ~/Dokumentumok/1_Munkaterület
#   type: project | area | resource | archive
#   action: move | copy | skip
#   notes: Optional notes

mappings:
YAMLEOF

# Function to categorize and add to mapping
categorize() {
    local category=$1
    local size=$2
    local type=""
    local dest=""
    local action="move"
    local notes=""

    # Projects - specific client/project names (all to Archive/2020 since from 2020)
    if echo "$category" | grep -qiE "^(Szenior|Leadex|BE Aerospace|BCSS|Annax|TriGránit|Maokom|Consero|Denon|Dreher|Citroen|Credo|Dignitas|PL Invest|JJP|Promei|PMOffice)"; then
        type="archive"
        dest="Archívum/2020/Projektek/$category"
        notes="Befejezett projekt (2020 előtti)"

    # Programming languages - Areas/Tudásbázis
    elif echo "$category" | grep -qiE "^(Nodejs|Python|Javascript|Perl|Java|PHP|Ruby|DevOps|Docker|Linux|Cloud|BPM|CMDB|Vim|Programozás)$"; then
        type="area"
        dest="Területek/Tudásbázis/Programozás/$category"
        notes="Programozási tudásterület"

    # Languages - Areas/Tudásbázis
    elif echo "$category" | grep -qiE "^(Német|Angol|Francia|Olasz|Japán|Spanyol)$"; then
        type="area"
        dest="Területek/Tudásbázis/Nyelvek/$category"
        notes="Nyelvtanulás"

    # Books - Resources
    elif echo "$category" | grep -qiE "^(Pact Publishing|Pocket book|Kindle|E-könyv)"; then
        type="resource"
        dest="Források/Típus_szerint/Könyvek/$category"
        notes="Könyvgyűjtemény - később Calibre integráció"

    # Methodologies - Areas/Tudásbázis
    elif echo "$category" | grep -qiE "^(Project menedzsment|Projekt módszertan|Agile|Scrum|MBA)$"; then
        type="area"
        dest="Területek/Tudásbázis/Módszertanok/$category"
        notes="Menedzsment módszertan"

    # Psychology/Self-development - Areas/Tudásbázis
    elif echo "$category" | grep -qiE "^(Pszichológia|NLP|Dharma|Pránanadi|Villámolvasás|Boldogság|Agykontroll|Önfejlesztés)$"; then
        type="area"
        dest="Területek/Tudásbázis/Önfejlesztés/$category"
        notes="Önfejlesztési anyagok"

    # Personal - Areas/Személyes_Dokumentumok
    elif echo "$category" | grep -qiE "^(Pintér Pál|Iván Éva|CV)"; then
        type="area"
        dest="Területek/Személyes_dokumentumok/$category"
        notes="Személyes dokumentumok"

    # Hobbies - Resources/Téma_szerint
    elif echo "$category" | grep -qiE "^(Zene|Barkácsolás|Manóvár|Paleolit)"; then
        type="resource"
        dest="Források/Téma_szerint/Hobbik/$category"
        notes="Hobbi anyagok"

    # Design/Documentation - Resources
    elif echo "$category" | grep -qiE "^(Design)$"; then
        type="resource"
        dest="Források/Típus_szerint/Dokumentációk/$category"
        notes="Design dokumentáció"

    # Administrative/Legal - Areas
    elif echo "$category" | grep -qiE "^(Cégkapu|Cégszolgálat|Domain|EU támogatások|Zugló)$"; then
        type="area"
        dest="Területek/Adminisztráció/$category"
        notes="Adminisztrációs anyagok"

    # Sciences - Resources
    elif echo "$category" | grep -qiE "^(Természettudomány|Történelem|Szociológia)$"; then
        type="resource"
        dest="Források/Téma_szerint/Tudomány/$category"
        notes="Tudományos anyagok"

    # Marketing - Area
    elif echo "$category" | grep -qiE "^(Marketing)$"; then
        type="area"
        dest="Területek/Tudásbázis/Marketing"
        notes="Marketing tudásterület"

    # Uncluttering - Area
    elif echo "$category" | grep -qiE "^(Uncluttering)$"; then
        type="area"
        dest="Területek/Tudásbázis/Önfejlesztés/Rendszerezés"
        notes="Rendszerezési módszertan"

    # Unknown - needs manual categorization
    else
        type="manual"
        dest="MANUAL_REVIEW_NEEDED/$category"
        action="skip"
        notes="Manuális kategorizálás szükséges"
    fi

    # Add to YAML
    cat >> "$MAPPING_FILE" << ITEMEOF
  - source: "$category"
    dest: "$dest"
    type: $type
    action: $action
    size: "$size"
    notes: "$notes"
ITEMEOF
}

# Get all second-level directories with sizes
echo "Processing categories..."
processed=0

find "$IRATTAR_DIR" -maxdepth 2 -mindepth 2 -type d | while read -r dir; do
    category_path=$(echo "$dir" | sed "s|$IRATTAR_DIR/||")
    parent=$(dirname "$category_path")
    category=$(basename "$category_path")
    size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')

    categorize "$category" "$size"
    ((processed++)) || true

    if ((processed % 10 == 0)); then
        echo "  Processed $processed categories..."
    fi
done

echo ""
echo -e "${GREEN}✅ Mapping file generated!${NC}"
echo -e "${GREEN}File: $MAPPING_FILE${NC}\n"

# Count statistics
total=$(grep -c "^  - source:" "$MAPPING_FILE" || echo 0)
manual=$(grep -c "type: manual" "$MAPPING_FILE" || echo 0)
projects=$(grep -c "type: archive" "$MAPPING_FILE" || echo 0)
areas=$(grep -c "type: area" "$MAPPING_FILE" || echo 0)
resources=$(grep -c "type: resource" "$MAPPING_FILE" || echo 0)

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}📊 Mapping Statistics${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "Total categories:   $total"
echo -e "  → Archive:        $projects"
echo -e "  → Areas:          $areas"
echo -e "  → Resources:      $resources"
echo -e "  → Manual review:  $manual"
echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

if [ "$manual" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $manual categories need manual review${NC}"
    echo -e "${YELLOW}   Edit $MAPPING_FILE and update the mappings${NC}"
    echo -e "${YELLOW}   Look for 'type: manual' entries${NC}\n"
fi

echo -e "${YELLOW}💡 Next step: Review and edit mapping file, then run migration dry-run${NC}"
