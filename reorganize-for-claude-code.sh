#!/bin/bash
set -e

# This script reorganizes skills from:
#   skills/category/skill-name/SKILL.md
# To:
#   claude-commands/category/skill-name.md
# Preserving the meaningful category structure for discovery

SKILLS_DIR="skills"
OUTPUT_DIR="claude-commands"

echo "Creating reorganized structure in $OUTPUT_DIR..."

# Clean output directory if it exists
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Find all SKILL.md files and reorganize
find "$SKILLS_DIR" -name "SKILL.md" -type f | while read skill_file; do
    # Extract parts: skills/category/skill-name/SKILL.md
    relative_path="${skill_file#$SKILLS_DIR/}"  # Remove skills/ prefix
    category=$(dirname "$(dirname "$relative_path")")  # Get category (may be nested)
    skill_name=$(basename "$(dirname "$relative_path")")  # Get skill-name
    
    # Skip the top-level using-skills (it's standalone)
    if [ "$category" = "." ]; then
        category=""
        target_file="$OUTPUT_DIR/${skill_name}.md"
    else
        target_file="$OUTPUT_DIR/$category/${skill_name}.md"
    fi
    
    # Create category directory
    mkdir -p "$(dirname "$target_file")"
    
    # Copy the SKILL.md file to the new location
    cp "$skill_file" "$target_file"
    
    echo "  $category/${skill_name}"
done

echo ""
echo "Reorganization complete!"
echo "Structure created in: $OUTPUT_DIR/"
echo ""
echo "To use these as Claude Code commands, symlink the directories:"
echo "  cd ~/.claude/commands"
echo "  ln -s superpowers-skills/claude-commands/* ."
