#!/bin/bash
# Cleanup book metadata files (Kindle metadata, etc.)

set -e

BOOKS_DIR="$HOME/Dokumentumok/1_Munkaterület/Források/Típus_szerint/Könyvek"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧹 Cleaning up book metadata files...${NC}"
echo -e "${BLUE}Directory: $BOOKS_DIR${NC}\n"

# Count before
total_before=$(find "$BOOKS_DIR" -type f | wc -l)
size_before=$(du -sh "$BOOKS_DIR" | awk '{print $1}')

echo -e "${YELLOW}Before cleanup:${NC}"
echo "  Files: $total_before"
echo "  Size: $size_before"
echo ""

# Dry run option
if [ "${1:-}" = "--dry-run" ]; then
    echo -e "${BLUE}DRY-RUN MODE - No files will be deleted${NC}\n"

    echo "Would delete the following file types:"
    echo "  - .apnx (Amazon reading position): $(find "$BOOKS_DIR" -name "*.apnx" | wc -l) files"
    echo "  - .mbp1 (Mobipocket metadata): $(find "$BOOKS_DIR" -name "*.mbp1" | wc -l) files"
    echo "  - .mbs (Mobipocket metadata): $(find "$BOOKS_DIR" -name "*.mbs" | wc -l) files"
    echo "  - .azw3f (Font files): $(find "$BOOKS_DIR" -name "*.azw3f" | wc -l) files"
    echo "  - .azw3r (Resource files): $(find "$BOOKS_DIR" -name "*.azw3r" | wc -l) files"
    echo "  - .dic (Dictionary): $(find "$BOOKS_DIR" -name "*.dic" | wc -l) files"
    echo "  - .cfg (Config): $(find "$BOOKS_DIR" -name "*.cfg" | wc -l) files"
    echo "  - .dat (Data): $(find "$BOOKS_DIR" -name "*.dat" | wc -l) files"
    echo "  - .asc (ASCII metadata): $(find "$BOOKS_DIR" -name "*.asc" | wc -l) files"
    echo "  - .lnk (Windows shortcuts): $(find "$BOOKS_DIR" -name "*.lnk" | wc -l) files"
    echo "  - .back (Backups): $(find "$BOOKS_DIR" -name "*.back" | wc -l) files"
    echo ""
    echo -e "${YELLOW}To execute cleanup, run without --dry-run flag${NC}"
    exit 0
fi

# Confirmation
echo -e "${RED}⚠️  WARNING: This will delete ~1000+ metadata files${NC}"
echo -e "${RED}   Make sure you have a backup!${NC}\n"

read -p "Are you sure you want to continue? (type 'yes' to confirm): " response
if [ "$response" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}Deleting metadata files...${NC}"

# Delete metadata files
deleted=0

echo "  Deleting .apnx files..."
count=$(find "$BOOKS_DIR" -name "*.apnx" -type f | wc -l)
find "$BOOKS_DIR" -name "*.apnx" -type f -delete
deleted=$((deleted + count))

echo "  Deleting .mbp1 files..."
count=$(find "$BOOKS_DIR" -name "*.mbp1" -type f | wc -l)
find "$BOOKS_DIR" -name "*.mbp1" -type f -delete
deleted=$((deleted + count))

echo "  Deleting .mbs files..."
count=$(find "$BOOKS_DIR" -name "*.mbs" -type f | wc -l)
find "$BOOKS_DIR" -name "*.mbs" -type f -delete
deleted=$((deleted + count))

echo "  Deleting .azw3f files..."
count=$(find "$BOOKS_DIR" -name "*.azw3f" -type f | wc -l)
find "$BOOKS_DIR" -name "*.azw3f" -type f -delete
deleted=$((deleted + count))

echo "  Deleting .azw3r files..."
count=$(find "$BOOKS_DIR" -name "*.azw3r" -type f | wc -l)
find "$BOOKS_DIR" -name "*.azw3r" -type f -delete
deleted=$((deleted + count))

echo "  Deleting .dic files..."
count=$(find "$BOOKS_DIR" -name "*.dic" -type f | wc -l)
find "$BOOKS_DIR" -name "*.dic" -type f -delete
deleted=$((deleted + count))

echo "  Deleting .cfg files..."
count=$(find "$BOOKS_DIR" -name "*.cfg" -type f | wc -l)
find "$BOOKS_DIR" -name "*.cfg" -type f -delete
deleted=$((deleted + count))

echo "  Deleting .dat files..."
count=$(find "$BOOKS_DIR" -name "*.dat" -type f | wc -l)
find "$BOOKS_DIR" -name "*.dat" -type f -delete
deleted=$((deleted + count))

echo "  Deleting .asc files..."
count=$(find "$BOOKS_DIR" -name "*.asc" -type f | wc -l)
find "$BOOKS_DIR" -name "*.asc" -type f -delete
deleted=$((deleted + count))

echo "  Deleting .lnk files..."
count=$(find "$BOOKS_DIR" -name "*.lnk" -type f | wc -l)
find "$BOOKS_DIR" -name "*.lnk" -type f -delete
deleted=$((deleted + count))

echo "  Deleting .back files..."
count=$(find "$BOOKS_DIR" -name "*.back" -type f | wc -l)
find "$BOOKS_DIR" -name "*.back" -type f -delete
deleted=$((deleted + count))

# Count after
total_after=$(find "$BOOKS_DIR" -type f | wc -l)
size_after=$(du -sh "$BOOKS_DIR" | awk '{print $1}')

echo ""
echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo ""
echo -e "${YELLOW}After cleanup:${NC}"
echo "  Files: $total_after (deleted $deleted files)"
echo "  Size: $size_after (was $size_before)"
echo ""
echo -e "${BLUE}📚 Only actual book files remain${NC}"
