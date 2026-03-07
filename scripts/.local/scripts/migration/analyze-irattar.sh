#!/bin/bash
# Analyze ~/Irattár structure and categorize for PARA migration

set -e

IRATTAR_DIR="$HOME/Irattár"
OUTPUT_DIR="$HOME/Dokumentumok/1_Munkaterület/Területek/Adminisztráció"
ANALYSIS_FILE="$OUTPUT_DIR/irattar-analysis-$(date +%Y%m%d_%H%M%S).md"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📊 Analyzing Irattár structure...${NC}"
echo -e "${BLUE}Source: $IRATTAR_DIR${NC}"
echo -e "${BLUE}Output: $ANALYSIS_FILE${NC}\n"

# Create analysis report
cat > "$ANALYSIS_FILE" << 'MDEOF'
# Irattár Analízis és PARA Migráció Terve

**Generálva:** $(date '+%Y-%m-%d %H:%M:%S')

## Összefoglalás

MDEOF

# Gather statistics
echo "Gathering statistics..."
total_size=$(du -sh "$IRATTAR_DIR" | awk '{print $1}')
total_files=$(find "$IRATTAR_DIR" -type f | wc -l)
total_dirs=$(find "$IRATTAR_DIR" -type d | wc -l)
second_level_dirs=$(find "$IRATTAR_DIR" -maxdepth 2 -mindepth 2 -type d | wc -l)

cat >> "$ANALYSIS_FILE" << STATEOF
- **Teljes méret:** $total_size
- **Fájlok száma:** $total_files
- **Könyvtárak száma:** $total_dirs
- **Második szintű könyvtárak:** $second_level_dirs

## Fájltípus Eloszlás (Top 20)

\`\`\`
STATEOF

find "$IRATTAR_DIR" -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20 >> "$ANALYSIS_FILE"

cat >> "$ANALYSIS_FILE" << 'TYPEEOF'
```

## Legnagyobb Könyvtárak (Top 50)

| Méret | Kategória | PARA Javaslat |
|-------|-----------|---------------|
TYPEEOF

# Analyze largest directories and suggest PARA categories
du -sh "$IRATTAR_DIR"/*/* 2>/dev/null | sort -rh | head -50 | while IFS=$'\t' read -r size path; do
    category=$(basename "$path")
    parent=$(basename "$(dirname "$path")")

    # Suggest PARA category based on keywords
    para_suggestion=""

    # Projects - specific client/project names
    if echo "$category" | grep -qiE "(Szenior|Leadex|BE Aerospace|BCSS|Annax|TriGránit|Maokom|Consero|Denon|Dreher|Citroen|Credo|Dignitas|PL Invest|JJP|Promei|PMOffice)"; then
        para_suggestion="📁 Projektek/Archívum (befejezett projekt)"

    # Programming languages/technologies - Areas
    elif echo "$category" | grep -qiE "(Nodejs|Python|Javascript|Perl|Java|PHP|Ruby|DevOps|Docker|Linux|Cloud|BPM|CMDB)"; then
        para_suggestion="🔧 Területek/Tudásbázis/Programozás"

    # Languages - Areas
    elif echo "$category" | grep -qiE "(Német|Angol|Francia|Olasz|Japán)"; then
        para_suggestion="🌍 Területek/Tudásbázis/Nyelvek"

    # Books - Resources
    elif echo "$category" | grep -qiE "(Pact Publishing|Pocket book|Kindle|könyv)"; then
        para_suggestion="📚 Források/Típus_szerint/Könyvek"

    # Methodologies - Areas
    elif echo "$category" | grep -qiE "(Project menedzsment|Projekt módszertan|Agile|Scrum|MBA)"; then
        para_suggestion="📊 Területek/Tudásbázis/Módszertanok"

    # Psychology/Self-development - Areas or Resources
    elif echo "$category" | grep -qiE "(Pszichológia|NLP|Dharma|Pránanadi|Villámolvasás|Boldogság|Agykontroll)"; then
        para_suggestion="🧠 Területek/Tudásbázis/Önfejlesztés vagy Források/Téma_szerint"

    # Personal - Areas
    elif echo "$category" | grep -qiE "(Pintér Pál|Iván Éva|CV)"; then
        para_suggestion="👤 Területek/Személyes_Dokumentumok"

    # Hobbies - Areas or Resources
    elif echo "$category" | grep -qiE "(Zene|Barkácsolás|Manóvár|Paleolit)"; then
        para_suggestion="🎨 Források/Téma_szerint vagy Területek"

    # Design/Documentation - Resources
    elif echo "$category" | grep -qiE "(Design|Documentation|Tutorial)"; then
        para_suggestion="📖 Források/Típus_szerint/Dokumentációk"

    # Administrative/Legal - Areas
    elif echo "$category" | grep -qiE "(Cégkapu|Cégszolgálat|Domain|EU támogatások|Zugló)"; then
        para_suggestion="📋 Területek/Adminisztráció"

    else
        para_suggestion="❓ Manuális kategorizálás szükséges"
    fi

    echo "| $size | $parent/$category | $para_suggestion |" >> "$ANALYSIS_FILE"
done

cat >> "$ANALYSIS_FILE" << 'RULESEOF'

## PARA Migrációs Szabályok

### 1. Projektek (Projects)
- **Céljuk:** Konkrét, befejezett projektek/kliensek
- **Irattár kategóriák:**
  - Szenior Zrt., Leadex, BE Aerospace, BCSS, Annax, TriGránit, Maokom, Consero, stb.
- **Cél helye:**
  - `~/Dokumentumok/1_Munkaterület/Archívum/YYYY/Projektek/{project_name}`

### 2. Területek (Areas)
- **Céljuk:** Folyamatos felelősségi körök, tudásterületek
- **Irattár kategóriák:**
  - Programozás: Nodejs, Python, Javascript, Perl, DevOps, Linux, Docker
  - Nyelvek: Német, Angol, Francia, Olasz
  - Módszertanok: Project menedzsment, MBA, Agile
  - Önfejlesztés: Pszichológia, NLP, Villámolvasás
  - Személyes: Pintér Pál dokumentumok, CV
- **Cél helye:**
  - `~/Dokumentumok/1_Munkaterület/Területek/Tudásbázis/{category}/{subcategory}`
  - `~/Dokumentumok/1_Munkaterület/Területek/Személyes_dokumentumok/`

### 3. Források (Resources)
- **Céljuk:** Referencia anyagok, könyvek, tutorialok
- **Irattár kategóriák:**
  - Könyvek: Pact Publishing könyvek, Pocket book, Kindle
  - Dokumentációk: Design docs, tutorials
  - Média: Videók, hanganyagok
- **Cél helye:**
  - `~/Dokumentumok/1_Munkaterület/Források/Típus_szerint/Könyvek/`
  - `~/Dokumentumok/1_Munkaterület/Források/Típus_szerint/Dokumentációk/`
  - `~/Dokumentumok/1_Munkaterület/Források/Típus_szerint/Multimédia/`

### 4. Archívum (Archive)
- **Céljuk:** Régi, befejezett, ritkán használt anyagok
- **Irattár kategóriák:**
  - Minden 2020 előtti projekt
  - Elavult technológiák
  - Befejezett tanfolyamok
- **Cél helye:**
  - `~/Dokumentumok/1_Munkaterület/Archívum/2020/`

## Migráció Stratégia

### Fázis 1: Automatikus Kategorizálás
1. Készíts mapping fájlt: `irattar-para-mapping.yaml`
2. Kulcsszavak alapján automatikus besorolás
3. Dry-run mód: csak terv készítése, fájlmozgatás nélkül

### Fázis 2: Manuális Felülvizsgálat
1. Review mapping fájl
2. Korrekcio ahol szükséges
3. Manuális kategorizálás az "❓" kategóriákhoz

### Fázis 3: Migráció Végrehajtás
1. Backup létrehozása: `tar -czf ~/irattar-backup-YYYYMMDD.tar.gz ~/Irattár`
2. Migration log file: minden művelet naplózva
3. Rollback plan: minden mozgatás visszavonható

### Fázis 4: Ellenőrzés
1. Fájlszám egyezés (előtte/utána)
2. Méret egyezés
3. Szemantikus ellenőrzés (random minták)
4. Duplikátumok keresése

## Következő Lépések

1. [ ] Mapping fájl generálása (`generate-irattar-mapping.sh`)
2. [ ] Mapping fájl manuális review
3. [ ] Migration script írása dry-run móddal
4. [ ] Dry-run teszt végrehajtása
5. [ ] Backup készítése
6. [ ] Éles migráció végrehajtása
7. [ ] Post-migration ellenőrzés
8. [ ] Irattár törlése (csak ellenőrzés után!)

## Megjegyzések

- Az Irattár **45GB** és **55,058 fájl** - nagy művelet
- A legnagyobb kategóriák (Nodejs 6.3GB, Német 5.2GB) kézi ellenőrzést igényelhetnek
- Sok PDF könyv (2894 db) - Calibre integráció később
- Video tutorialok (Python .mp4) - XDG Videók mappába?
- Webes projektek (PHP, JS, CSS) - Git repo-ba költöztetés?

RULESEOF

echo -e "${GREEN}✅ Analysis complete!${NC}"
echo -e "${GREEN}Report saved to: $ANALYSIS_FILE${NC}\n"

# Print summary
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}📊 Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "Total size:         $total_size"
echo -e "Total files:        $total_files"
echo -e "Total directories:  $total_dirs"
echo -e "Categories (L2):    $second_level_dirs"
echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

echo -e "${YELLOW}💡 Next step: Review the analysis report and create mapping file${NC}"
echo -e "${YELLOW}   File location: $ANALYSIS_FILE${NC}"
