#!/bin/bash
# Analyze book library structure and generate cleanup report

set -e

BOOKS_DIR="$HOME/Dokumentumok/1_Munkaterület/Források/Típus_szerint/Könyvek"
OUTPUT_DIR="$HOME/Dokumentumok/1_Munkaterület/Területek/Adminisztráció"
ANALYSIS_FILE="$OUTPUT_DIR/book-library-analysis-$(date +%Y%m%d_%H%M%S).md"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📚 Analyzing Book Library...${NC}"
echo -e "${BLUE}Source: $BOOKS_DIR${NC}"
echo -e "${BLUE}Output: $ANALYSIS_FILE${NC}\n"

# Create analysis report
cat > "$ANALYSIS_FILE" << 'MDEOF'
# Book Library Analysis

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')

## Summary

MDEOF

# Gather statistics
echo "Gathering statistics..."

total_files=$(find "$BOOKS_DIR" -type f | wc -l)
total_size=$(du -sh "$BOOKS_DIR" | awk '{print $1}')

# Count by category
kindle_files=$(find "$BOOKS_DIR/Kindle" -type f 2>/dev/null | wc -l)
pact_files=$(find "$BOOKS_DIR/Pact Publishing könyvek" -type f 2>/dev/null | wc -l)
pocket_files=$(find "$BOOKS_DIR/Pocket book" -type f 2>/dev/null | wc -l)
ekonyv_files=$(find "$BOOKS_DIR/E-könyv" -type f 2>/dev/null | wc -l)

# Count actual books
mobi_count=$(find "$BOOKS_DIR" -name "*.mobi" | wc -l)
epub_count=$(find "$BOOKS_DIR" -name "*.epub" | wc -l)
pdf_count=$(find "$BOOKS_DIR" -name "*.pdf" | wc -l)
azw_count=$(find "$BOOKS_DIR" -name "*.azw*" | wc -l)
prc_count=$(find "$BOOKS_DIR" -name "*.prc" | wc -l)

actual_books=$((mobi_count + epub_count + pdf_count + azw_count + prc_count))

# Count metadata files
apnx_count=$(find "$BOOKS_DIR" -name "*.apnx" | wc -l)
mbp_count=$(find "$BOOKS_DIR" -name "*.mbp*" | wc -l)
mbs_count=$(find "$BOOKS_DIR" -name "*.mbs" | wc -l)
metadata_total=$((apnx_count + mbp_count + mbs_count))

cat >> "$ANALYSIS_FILE" << STATEOF
- **Total files:** $total_files
- **Total size:** $total_size
- **Actual books:** $actual_books
- **Metadata files:** $metadata_total (can be deleted)

### By Category
- **Kindle:** $kindle_files files
- **Pact Publishing:** $pact_files files (tech books)
- **Pocket book:** $pocket_files files
- **E-könyv:** $ekonyv_files files

### By Format (Books Only)
- **MOBI:** $mobi_count
- **EPUB:** $epub_count
- **PDF:** $pdf_count
- **AZW (Amazon):** $azw_count
- **PRC:** $prc_count

## File Type Distribution

\`\`\`
STATEOF

find "$BOOKS_DIR" -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -30 >> "$ANALYSIS_FILE"

cat >> "$ANALYSIS_FILE" << 'TYPEEOF'
```

## Cleanup Recommendations

### 1. Delete Metadata Files (~1100 files, ~50MB)

**Kindle metadata (safe to delete):**
- `.apnx` files: Amazon reading position data
- `.mbp1` files: Mobipocket metadata
- `.mbs` files: Mobipocket metadata
- `.azw3f` files: Font files
- `.azw3r` files: Resource files
- `.dic` files: Dictionary files
- `.cfg` files: Configuration
- `.dat` files: Data files
- `.asc` files: ASCII metadata

**Other cleanup:**
- `.lnk` files: Windows shortcuts
- `.back` files: Backup files

### 2. Review Image Files

**PNG/JPG files (128 + 10 = 138 files):**
- Could be book covers (keep if useful)
- Could be extracted images (delete if duplicates)

### 3. Extract ZIP Files

**ZIP files (53):**
- May contain books that should be extracted
- Check and extract before deleting

### 4. Organize by PARA Structure

**Current structure:**
- `Kindle/` - Mixed formats, lots of metadata
- `Pact Publishing könyvek/` - Tech books (3.9GB)
- `Pocket book/` - Various books
- `E-könyv/` - E-books

**Recommended PARA structure:**

```
~/Dokumentumok/1_Munkaterület/Források/Típus_szerint/Könyvek/
├── Formátum_szerint/
│   ├── EPUB/
│   ├── MOBI/
│   ├── PDF/
│   └── AZW/
├── Szerzők_szerint/
│   ├── [Author Name]/
│   │   └── [Book Title].[ext]
├── Témák_szerint/
│   ├── Programming/
│   │   ├── Python/
│   │   ├── JavaScript/
│   │   ├── DevOps/
│   ├── Science/
│   ├── Fiction/
│   └── Non-Fiction/
├── Sorozatok_szerint/
│   └── [Series Name]/
│       └── [Book N].[ext]
└── Státusz_szerint/
    ├── To_Read/
    ├── Reading/
    ├── Completed/
    └── Reference/
```

## Migration Strategy

### Phase 1: Cleanup (Safe deletions)
1. Delete metadata files (`.apnx`, `.mbp*`, `.mbs`, `.azw3f/r`, `.dic`, `.cfg`, `.dat`, `.asc`)
2. Delete Windows shortcuts (`.lnk`)
3. Delete backup files (`.back`)
4. **Estimated cleanup:** ~1100 files, ~50-100MB

### Phase 2: Extract Archives
1. Extract `.zip` files
2. Verify contents
3. Delete archives after extraction

### Phase 3: Categorize by Topic
1. Analyze book titles/authors
2. Create topic-based categories:
   - Programming (Python, JavaScript, DevOps, etc.)
   - Science & Technology
   - Business & Economics
   - Fiction & Literature
   - Personal Development
3. Move books to appropriate folders

### Phase 4: GTD Integration
1. Track reading status (To Read, Reading, Completed)
2. Create reading goals in GTD
3. Add book notes to knowledge base

## Sample Books from Pact Publishing

TYPEEOF

# List sample Pact books
echo "Listing sample books..."
ls "$BOOKS_DIR/Pact Publishing könyvek" 2>/dev/null | head -30 >> "$ANALYSIS_FILE" || echo "  (No files)" >> "$ANALYSIS_FILE"

cat >> "$ANALYSIS_FILE" << 'SCRIPTSEOF'

## Cleanup Scripts

### Quick Metadata Cleanup

```bash
#!/bin/bash
# cleanup-book-metadata.sh - Delete Kindle metadata files

BOOKS_DIR="$HOME/Dokumentumok/1_Munkaterület/Források/Típus_szerint/Könyvek"

echo "🧹 Cleaning up book metadata..."

# Count before
total_before=$(find "$BOOKS_DIR" -type f | wc -l)

# Delete metadata files
find "$BOOKS_DIR" -name "*.apnx" -delete
find "$BOOKS_DIR" -name "*.mbp1" -delete
find "$BOOKS_DIR" -name "*.mbs" -delete
find "$BOOKS_DIR" -name "*.azw3f" -delete
find "$BOOKS_DIR" -name "*.azw3r" -delete
find "$BOOKS_DIR" -name "*.dic" -delete
find "$BOOKS_DIR" -name "*.cfg" -delete
find "$BOOKS_DIR" -name "*.dat" -delete
find "$BOOKS_DIR" -name "*.asc" -delete
find "$BOOKS_DIR" -name "*.lnk" -delete
find "$BOOKS_DIR" -name "*.back" -delete

# Count after
total_after=$(find "$BOOKS_DIR" -type f | wc -l)
deleted=$((total_before - total_after))

echo "✅ Deleted $deleted metadata files"
echo "📚 Remaining: $total_after book files"
```

### Extract Book Archives

```bash
#!/bin/bash
# extract-book-archives.sh

BOOKS_DIR="$HOME/Dokumentumok/1_Munkaterület/Források/Típus_szerint/Könyvek"

find "$BOOKS_DIR" -name "*.zip" | while read -r zip; do
    dir=$(dirname "$zip")
    echo "📦 Extracting: $zip"
    unzip -q "$zip" -d "$dir"
    # Don't delete yet - verify first!
done
```

## Next Steps

1. [ ] Run book library analysis script
2. [ ] Review cleanup recommendations
3. [ ] Execute metadata cleanup (saves ~50-100MB)
4. [ ] Extract ZIP archives
5. [ ] Categorize books by topic
6. [ ] Implement PARA structure for books
7. [ ] GTD reading tracker integration
8. [ ] Consider Calibre import for better management

SCRIPTSEOF

echo -e "${GREEN}✅ Analysis complete!${NC}"
echo -e "${GREEN}Report saved to: $ANALYSIS_FILE${NC}\n"

# Print summary
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}📊 Book Library Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "Total files:         $total_files"
echo -e "Actual books:        $actual_books"
echo -e "Metadata files:      $metadata_total (can be deleted)"
echo -e "Total size:          $total_size"
echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

echo -e "${YELLOW}💡 Next step: Review the analysis report and run cleanup scripts${NC}"
echo -e "${YELLOW}   File location: $ANALYSIS_FILE${NC}"
