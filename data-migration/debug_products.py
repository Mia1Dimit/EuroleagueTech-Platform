import re
from pathlib import Path

content = Path(r'c:\Dev\Personal\Euroleague Tech\vendor-profiles\catapult-sports.md').read_text(encoding='utf-8')

section_pattern = r'##\s+Product Portfolio'
section_match = re.search(section_pattern, content, re.IGNORECASE)

start_pos = section_match.end()
next_section = re.search(r'\n##\s+[^#]', content[start_pos:])
if next_section:
    section_content = content[start_pos:start_pos + next_section.start()]
else:
    section_content = content[start_pos:]

# Get main products first
h3_pattern = r'###\s+(.+?)(?:\n|$)'
main_products = re.findall(h3_pattern, section_content)
products = []

for product in main_products:
    product_clean = product.strip()
    if '(' in product_clean:
        product_clean = product_clean.split('(')[0].strip()
    if product_clean:
        products.append(product_clean)

print("Main products from ### headings:")
for p in products:
    print(f"  {p}")

# Now parse bold lines
bold_pattern = r'^\*\*([^*]+?)\*\*(?:\s*:|\s*\()?'
exclude_fields = {
    'description', 'type', 'form factor', 'data collected', 'sampling rate',
    'battery life', 'use case', 'launch', 'key feature', 'accuracy',
    'capabilities', 'integration', 'sports', 'acquisition', 'features',
    'automation', 'modules', 'key features', 'product', 'vendor'
}

print("\nProcessing bold lines:")
print("=" * 60)

for line in section_content.split('\n'):
    match = re.match(bold_pattern, line.strip())
    if match:
        product_name = match.group(1).strip()
        product_lower = product_name.lower()
        has_colon = re.match(r'^\*\*[^*]+?\*\*\s*:', line.strip())
        
        print(f"\n  Line: {line.strip()[:50]}")
        print(f"    Product name: {product_name}")
        print(f"    has_colon check: {has_colon is not None}")
        print(f"    not has_colon: {not has_colon}")
        print(f"    in exclude_fields: {product_lower in exclude_fields}")
        print(f"    Already in main: {any(product_name in main_prod for main_prod in products)}")
        
        should_add = (not has_colon and product_lower not in exclude_fields and product_name
                      and not any(product_name in main_prod for main_prod in products))
        print(f"    WILL ADD: {should_add}")
        
        if should_add:
            products.append(product_name)

print("\n\nFinal products list:")
for p in products:
    print(f"  {p}")

