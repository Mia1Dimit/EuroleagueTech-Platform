"""
Markdown Parser for Euroleague Tech Data
Extracts teams, vendors, and partnerships from markdown files

Usage:
    python parse_markdown.py

Output:
    ./output/teams.json
    ./output/vendors.json
    ./output/partnerships.json
"""

import os
import json
import re
from pathlib import Path
from typing import Dict, List, Any
from datetime import datetime


# ============================================================================
# Configuration
# ============================================================================

# Path to Euroleague Tech workspace
EUROLEAGUE_PATH = Path(r"c:\Dev\Personal\Euroleague Tech")

# Input directories
TEAMS_DIR = EUROLEAGUE_PATH / "euroleague-teams"
VENDORS_DIR = EUROLEAGUE_PATH / "vendor-profiles"

# Output directory
OUTPUT_DIR = Path(__file__).parent / "output"
OUTPUT_DIR.mkdir(exist_ok=True)

# Canonical category list (9 categories - expanded March 2026)
CANONICAL_CATEGORIES = {
    "Performance Tracking",
    "Video Analysis",
    "Data Analytics",
    "Recovery & Medical",
    "Fan Engagement",
    "Facilities & Infrastructure",
    "Business Operations",
    "Scouting & Recruitment",
    "Content & Broadcasting"
}

# Category aliases/variations (map to canonical names)
CATEGORY_ALIASES = {
    "performance tracking & load management": "Performance Tracking",
    "performance": "Performance Tracking",
    "gps tracking": "Performance Tracking",
    "athlete management": "Performance Tracking",
    
    "video": "Video Analysis",
    "video scouting": "Video Analysis",
    
    "analytics": "Data Analytics",
    "data": "Data Analytics",
    "statistics": "Data Analytics",
    
    "recovery": "Recovery & Medical",
    "medical": "Recovery & Medical",
    "injury prevention": "Recovery & Medical",
    
    "engagement": "Fan Engagement",
    "fan": "Fan Engagement",
    "merchandise": "Fan Engagement",
    
    "facilities": "Facilities & Infrastructure",
    "infrastructure": "Facilities & Infrastructure",
    
    "business": "Business Operations",
    "ticketing": "Business Operations",
    "crm": "Business Operations",
    "enterprise": "Business Operations",
    
    "scouting": "Scouting & Recruitment",
    "recruitment": "Scouting & Recruitment",
    "draft": "Scouting & Recruitment",
    
    "content": "Content & Broadcasting",
    "broadcasting": "Content & Broadcasting",
    "media": "Content & Broadcasting",
    "highlights": "Content & Broadcasting",
    
    # Specific technology categories (map to broader categories)
    "interactive led playing surface technology": "Facilities & Infrastructure",
    "sports medicine & orthopedic supports": "Recovery & Medical",
    "physical therapy devices & training equipment": "Recovery & Medical",
    "physical therapy devices (tecar therapy)": "Recovery & Medical",
    "sports medicine & rehabilitation": "Recovery & Medical",
    "pharmaceuticals & pain relief products": "Recovery & Medical",
    "sports nutrition & supplements": "Recovery & Medical",
    "isokinetic strength assessment & training": "Performance Tracking",
    "premium sports flooring & court installation": "Facilities & Infrastructure",
    "exercise equipment & gym solutions": "Facilities & Infrastructure",
    "cloud infrastructure": "Data Analytics",
    "productivity & collaboration": "Business Operations",
    "enterprise integration": "Data Analytics",
    "digital transformation": "Data Analytics",
    "merchandise authentication": "Fan Engagement",
    "blockchain/nft": "Fan Engagement",
    "nft": "Fan Engagement",
    "mobile applications": "Fan Engagement",
    "revenue optimization": "Business Operations"
}


# ============================================================================
# Helper Functions
# ============================================================================

def extract_metadata_field(content: str, field_name: str, alternatives: list = None) -> str:
    """
    Extract metadata field from markdown content.
    Handles multiple field name variations and markdown formatting.
    
    Example: 
        **Club**: Real Madrid CF → Returns "Real Madrid CF"
        **Club:** Real Madrid CF → Returns "Real Madrid CF" (colon inside bold)
        **Category Focus**: Video Analysis → Returns "Video Analysis"
    
    Args:
        content: Markdown file content
        field_name: Field to extract (e.g., "Club", "Country", "Category Focus")
        alternatives: List of alternative field names to try
    
    Returns:
        Extracted value or empty string if not found
    """
    # Try exact field name with both colon positions
    # Pattern 1: **Field**: value (colon after asterisks)
    pattern = rf"\*\*{field_name}\*\*:\s*(.+?)(?:\n|$)"
    match = re.search(pattern, content)
    if match:
        return match.group(1).strip()
    
    # Pattern 2: **Field:** value (colon inside asterisks)
    pattern = rf"\*\*{field_name}:\*\*\s*(.+?)(?:\n|$)"
    match = re.search(pattern, content)
    if match:
        return match.group(1).strip()
    
    # Try alternative field names
    if alternatives:
        for alt_field in alternatives:
            # Pattern 1: **Alt Field**: value
            pattern = rf"\*\*{alt_field}\*\*:\s*(.+?)(?:\n|$)"
            match = re.search(pattern, content)
            if match:
                return match.group(1).strip()
            
            # Pattern 2: **Alt Field:** value            
            pattern = rf"\*\*{alt_field}:\*\*\s*(.+?)(?:\n|$)"
            match = re.search(pattern, content)
            if match:
                return match.group(1).strip()
    
    return ""


def normalize_category(category: str) -> str:
    """
    Normalize category name to canonical form.
    
    Handles variations like:
        "performance tracking" → "Performance Tracking"
        "Video" → "Video Analysis"
        "CRM" → "Business Operations"
    
    Args:
        category: Raw category string from markdown
    
    Returns:
        Canonical category name, or original if no match
    """
    # Clean the input
    category_clean = category.strip()
    category_lower = category_clean.lower()
    
    # Check if already canonical
    if category_clean in CANONICAL_CATEGORIES:
        return category_clean
    
    # Check aliases
    if category_lower in CATEGORY_ALIASES:
        return CATEGORY_ALIASES[category_lower]
    
    # Check partial matches (contains)
    for alias, canonical in CATEGORY_ALIASES.items():
        if alias in category_lower or category_lower in alias:
            return canonical
    
    # If no match, return original (will be flagged in output for manual review)
    return category_clean


def generate_id(name: str) -> str:
    """
    Generate URL-friendly ID from name.
    
    Example:
        "Real Madrid" → "real-madrid"
        "Catapult Sports" → "catapult-sports"
    
    Args:
        name: Human-readable name
    
    Returns:
        Lowercase hyphenated ID
    """
    return name.lower().replace(" ", "-").replace(".", "")


# ============================================================================
# Team Parser
# ============================================================================

def parse_team_file(file_path: Path) -> Dict[str, Any]:
    """
    Parse a single team markdown file.
    
    Args:
        file_path: Path to team .md file
    
    Returns:
        Dictionary with team data
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract metadata from markdown (with multiple field name variations)
    club_name = extract_metadata_field(content, "Club", ["Official Name", "Team Name", "Full Name", "Common Name"])
    country = extract_metadata_field(content, "Country", ["Location"])
    arena = extract_metadata_field(content, "Arena", ["Home Arena", "Home Arenas"])
    euroleague_status = extract_metadata_field(content, "Euroleague Status", ["League Status"])
    last_updated = extract_metadata_field(content, "Last Updated", ["Data Quality"])
    
    # Extract country from Location field if needed (format: "City, Country")
    if country:
        # Handle various formats:
        # "Istanbul, Turkey" → "Turkey"
        # "Vitoria-Gasteiz, Spain" → "Spain"
        # "Tel Aviv, Israel (Israel's economic/cultural capital, 4M metro population)" → "Israel"
        # "Munich, Bavaria, Germany" → "Bavaria" (take second element)
        if ", " in country:
            parts = country.split(", ")
            # Take second element for standard "City, Country" format
            if len(parts) >= 2:
                country = parts[1]
            else:
                country = parts[-1]
        # Remove any extra info in parentheses
        if "(" in country:
            country = country.split("(")[0].strip()
    
    # Extract arena capacity (parse "WiZink Center - 15,000 capacity")
    arena_capacity = None
    if arena:
        capacity_match = re.search(r'(\d+(?:,\d+)*)\s*capacity', arena, re.IGNORECASE)
        if capacity_match:
            arena_capacity = int(capacity_match.group(1).replace(',', ''))
            # Clean arena name (remove capacity suffix)
            arena = arena.split(' - ')[0].strip()
    
    # Generate team ID from filename
    team_id = file_path.stem  # e.g., "real-madrid.md" → "real-madrid"
    
    team_data = {
        "team_id": team_id,
        "name": club_name,
        "country": country,
        "arena": arena,
        "arena_capacity": arena_capacity,
        "euroleague_status": euroleague_status,
        "last_updated": last_updated,
        "partnerships": parse_partnerships(content)
    }
    
    return team_data


def parse_partnerships(content: str) -> List[str]:
    """
    Parse partnership vendor names from CONFIRMED Technology Partnerships section.
    
    Extracts vendor names from lines like:
        **Catapult Sports** - GPS/IMU Player Tracking System
        **Microsoft Azure and Office 365** - Enterprise Cloud Platform
    
    Args:
        content: Markdown file content
    
    Returns:
        List of vendor names
    """
    partnerships = []
    
    # Find the CONFIRMED partnerships section
    # Look for "## ✅ CONFIRMED Technology Partnerships" or similar
    section_pattern = r'##\s+.*?CONFIRMED.*?Technology.*?Partnerships'
    section_match = re.search(section_pattern, content, re.IGNORECASE)
    
    if not section_match:
        return partnerships
    
    # Get content from this section until next ## heading or end of file
    start_pos = section_match.end()
    next_section = re.search(r'\n##\s+[^#]', content[start_pos:])
    if next_section:
        section_content = content[start_pos:start_pos + next_section.start()]
    else:
        section_content = content[start_pos:]
    
    # Extract vendor names from bold text at start of line or after ###
    # Pattern: **Vendor Name** - description
    vendor_pattern = r'\*\*([^*]+?)\*\*\s*[-–—]'
    vendors = re.findall(vendor_pattern, section_content)
    
    # Clean vendor names and deduplicate
    seen = set()
    for vendor in vendors:
        vendor_clean = vendor.strip()
        if vendor_clean and vendor_clean not in seen:
            partnerships.append(vendor_clean)
            seen.add(vendor_clean)
    
    return partnerships


def parse_all_teams() -> List[Dict[str, Any]]:
    """
    Parse all team markdown files.
    
    Returns:
        List of team dictionaries
    """
    teams = []
    
    print(f"📂 Parsing teams from: {TEAMS_DIR}")
    
    for md_file in TEAMS_DIR.glob("*.md"):
        print(f"  - Parsing {md_file.name}...")
        team_data = parse_team_file(md_file)
        teams.append(team_data)
    
    print(f"✅ Parsed {len(teams)} teams\n")
    return teams


# ============================================================================
# Vendor Parser
# ============================================================================

def parse_vendor_file(file_path: Path) -> Dict[str, Any]:
    """
    Parse a single vendor markdown file.
    
    Args:
        file_path: Path to vendor .md file
    
    Returns:
        Dictionary with vendor data
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract metadata (with multiple field name variations)
    headquarters = extract_metadata_field(content, "Headquarters", ["HQ", "Location"])
    founded = extract_metadata_field(content, "Founded", ["Established", "Year Founded"])
    market_position = extract_metadata_field(content, "Market Position", ["Position"])
    category_focus = extract_metadata_field(content, "Category Focus", ["Category", "Categories", "Technology"])
    
    # Parse categories (comma-separated string to array)
    categories = []
    categories_raw = []  # Keep original for debugging
    unknown_categories = []
    
    if category_focus:
        # Split by comma and clean whitespace
        categories_raw = [cat.strip() for cat in category_focus.split(',') if cat.strip()]
        
        # Normalize each category
        categories_set = set()  # Use set to avoid duplicates
        for raw_cat in categories_raw:
            normalized = normalize_category(raw_cat)
            categories_set.add(normalized)
            
            # Flag unknown categories for review
            if normalized not in CANONICAL_CATEGORIES and normalized == raw_cat:
                unknown_categories.append(raw_cat)
        
        # Convert set back to sorted list
        categories = sorted(list(categories_set))
    
    # Generate vendor ID from filename
    vendor_id = file_path.stem  # e.g., "catapult-sports.md" → "catapult-sports"
    
    # Extract vendor name from first H1 heading
    vendor_name = ""
    h1_match = re.search(r'^#\s+(.+?)$', content, re.MULTILINE)
    if h1_match:
        vendor_name = h1_match.group(1).strip()
        # Remove "Vendor Profile:" prefix if present
        vendor_name = vendor_name.replace("Vendor Profile:", "").strip()
    
    # Warn about unknown categories
    if unknown_categories:
        print(f"    ⚠️  Unknown categories: {', '.join(unknown_categories)}")
    
    vendor_data = {
        "vendor_id": vendor_id,
        "name": vendor_name,
        "headquarters": headquarters,
        "founded": founded,
        "market_position": market_position,
        "categories": categories,  # Array of normalized category strings
        "categories_raw": categories_raw,  # Original for debugging
        "products": parse_products(content)
    }
    
    return vendor_data


def parse_products(content: str) -> List[str]:
    """
    Parse product names from Product Portfolio section.
    
    Extracts product names from ### headings like:
        ### Catapult Vector (Core Wearable Platform)
        ### Catapult Vision (Video Analysis)
        ### Catapult One (Platform)
    
    Also extracts sub-products from bold lines like:
        **Vector Core**
        **Vector T7** (Basketball-Specific)
    
    Args:
        content: Markdown file content
    
    Returns:
        List of product names
    """
    products = []
    
    # Find the Product Portfolio section
    section_pattern = r'##\s+Product Portfolio'
    section_match = re.search(section_pattern, content, re.IGNORECASE)
    
    if not section_match:
        return products
    
    # Get content from this section until next ## heading or end of file
    start_pos = section_match.end()
    next_section = re.search(r'\n##\s+[^#]', content[start_pos:])
    if next_section:
        section_content = content[start_pos:start_pos + next_section.start()]
    else:
        section_content = content[start_pos:]
    
    # Extract main products from ### headings
    # Pattern: ### Product Name (optional description)
    h3_pattern = r'###\s+(.+?)(?:\n|$)'
    main_products = re.findall(h3_pattern, section_content)
    
    for product in main_products:
        # Clean up (remove markdown, extra spaces)
        product_clean = product.strip()
        # Remove parenthetical descriptions for cleaner names
        # "Catapult Vector (Core Wearable Platform)" → "Catapult Vector"
        if '(' in product_clean:
            product_clean = product_clean.split('(')[0].strip()
        if product_clean:
            products.append(product_clean)
    
    # Extract sub-products from bold text at start of lines
    # Pattern: **Product Name** or **Product Name** (description)
    # Only within the Product Portfolio section
    # Exclude field labels like **Description**: or **Modules**:
    bold_pattern = r'^\*\*([^*]+?)\*\*(?:\s*:|\s*\()?'
    # Field names to exclude (common metadata fields)
    exclude_fields = {
        'description', 'type', 'form factor', 'data collected', 'sampling rate',
        'battery life', 'use case', 'launch', 'key feature', 'accuracy',
        'capabilities', 'integration', 'sports', 'acquisition', 'features',
        'automation', 'modules', 'key features', 'product', 'vendor',
        'category', 'headquarters', 'founded', 'market position', 'technology',
        'investment', 'source', 'status', 'clients', 'coverage'
    }
    
    for line in section_content.split('\n'):
        match = re.match(bold_pattern, line.strip())
        if match:
            product_name = match.group(1).strip()
            product_lower = product_name.lower()
            # Check if line has colon after ** (field label)
            has_colon = re.match(r'^\*\*[^*]+?\*\*\s*:', line.strip())
            # Skip if it's a field label or in exclude list
            if not has_colon and product_lower not in exclude_fields and product_name:
                # Remove common prefixes if already in main product
                # This avoids duplicates like "Catapult Vector" and "Vector Core"
                if not any(product_name in main_prod for main_prod in products):
                    products.append(product_name)
    
    # Deduplicate while preserving order
    seen = set()
    unique_products = []
    for p in products:
        if p not in seen:
            unique_products.append(p)
            seen.add(p)
    
    return unique_products


def parse_all_vendors() -> List[Dict[str, Any]]:
    """
    Parse all vendor markdown files.
    
    Returns:
        List of vendor dictionaries
    """
    vendors = []
    
    print(f"📂 Parsing vendors from: {VENDORS_DIR}")
    
    for md_file in VENDORS_DIR.glob("*.md"):
        print(f"  - Parsing {md_file.name}...")
        vendor_data = parse_vendor_file(md_file)
        vendors.append(vendor_data)
    
    print(f"✅ Parsed {len(vendors)} vendors\n")
    return vendors


# ============================================================================
# Main Execution
# ============================================================================

def main():
    """
    Main execution: Parse markdown files and save to JSON.
    """
    print("=" * 70)
    print("Euroleague Tech Data Parser")
    print("=" * 70)
    print()
    
    print(f"📋 Using {len(CANONICAL_CATEGORIES)} canonical categories:")
    for cat in sorted(CANONICAL_CATEGORIES):
        print(f"   • {cat}")
    print()
    
    # Parse teams
    teams = parse_all_teams()
    
    # Parse vendors
    vendors = parse_all_vendors()
    
    # Category statistics
    all_categories = set()
    for vendor in vendors:
        all_categories.update(vendor.get('categories', []))
    
    unknown_found = all_categories - CANONICAL_CATEGORIES
    
    print()
    print("📊 Category Analysis:")
    print(f"   Total unique categories found: {len(all_categories)}")
    print(f"   Canonical categories used: {len(all_categories & CANONICAL_CATEGORIES)}")
    if unknown_found:
        print(f"   ⚠️  Unknown categories: {len(unknown_found)}")
        for cat in sorted(unknown_found):
            print(f"      - {cat}")
    else:
        print(f"   ✅ All categories normalized successfully")
    print()
    
    # Save to JSON files
    teams_output = OUTPUT_DIR / "teams.json"
    vendors_output = OUTPUT_DIR / "vendors.json"
    
    with open(teams_output, 'w', encoding='utf-8') as f:
        json.dump(teams, f, indent=2, ensure_ascii=False)
    print(f"💾 Saved teams to: {teams_output}")
    
    with open(vendors_output, 'w', encoding='utf-8') as f:
        json.dump(vendors, f, indent=2, ensure_ascii=False)
    print(f"💾 Saved vendors to: {vendors_output}")
    
    print()
    print("=" * 70)
    print("✅ Parsing Complete!")
    print(f"   Teams: {len(teams)}")
    print(f"   Vendors: {len(vendors)}")
    print("=" * 70)


if __name__ == "__main__":
    main()
