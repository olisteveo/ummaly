#!/usr/bin/env python3
"""
Ummaly Halal Training Data Builder
===================================
This script processes halal ingredient databases and creates
a unified training dataset for the Ummaly halal checker model.

Output: training_data.json ready for nanochat fine-tuning
"""

import json
import re
import os
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).parent.parent
RAW_DATA_DIR = BASE_DIR / "data" / "raw"
PROCESSED_DIR = BASE_DIR / "data" / "processed"
OUTPUT_FILE = PROCESSED_DIR / "training_data.json"

# Status mappings
STATUS_MAP = {
    1: "HALAL",
    2: "HARAM",
    3: "MASHBOOH",
    4: "DEPENDS"
}

def parse_e_number_database():
    """Parse the SuhasDissa E-Number-Database JSON file."""
    json_path = RAW_DATA_DIR / "E-Number-Database" / "JSON" / "additives.json"

    if not json_path.exists():
        print(f"Warning: {json_path} not found")
        return []

    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    ingredients = []
    for item in data:
        # Normalize halal status
        status = item.get('halal_status', 'Unknown').upper()
        if status == 'DOUBTFUL':
            status = 'MASHBOOH'

        ingredients.append({
            'name': item.get('title', '').strip(),
            'e_code': item.get('e_code', '').strip(),
            'status': status,
            'category': item.get('e_type', '').strip(),
            'description': item.get('info', '').strip(),
            'source': 'E-Number-Database'
        })

    print(f"Parsed {len(ingredients)} items from E-Number-Database")
    return ingredients


def parse_sql_database():
    """Parse the cahyadsn/halal SQL file."""
    sql_path = RAW_DATA_DIR / "halal" / "db_halal.sql"

    if not sql_path.exists():
        print(f"Warning: {sql_path} not found")
        return []

    with open(sql_path, 'r', encoding='utf-8') as f:
        content = f.read()

    ingredients = []

    # Parse ingredient entries - handle multiline format
    # Format: ("name","ecode",status_id,"description")
    # The description can contain escaped quotes and newlines
    ingredient_pattern = r'\("([^"]+)","([^"]*)",(\d+),"((?:[^"\\]|\\.)*)"\)'

    matches = re.findall(ingredient_pattern, content)
    for match in matches:
        name, ecode, status_id, desc = match
        status = STATUS_MAP.get(int(status_id), 'UNKNOWN')

        # Clean up description
        clean_desc = desc.replace("\\'", "'").replace("\\n", " ").strip()

        ingredients.append({
            'name': name.strip(),
            'e_code': ecode.strip(),
            'status': status,
            'category': '',
            'description': clean_desc,
            'source': 'cahyadsn-halal'
        })

    # Also parse E-code table entries
    # Format: ("ecode","name","category",status_id,"description")
    ecode_pattern = r'\("(E\d+[a-z]?)","([^"]+)","([^"]+)",(\d+),"((?:[^"\\]|\\.)*)"\)'

    ecode_matches = re.findall(ecode_pattern, content)
    for match in ecode_matches:
        ecode, name, category, status_id, desc = match
        status = STATUS_MAP.get(int(status_id), 'UNKNOWN')

        clean_desc = desc.replace("\\'", "'").replace("\\n", " ").strip()

        ingredients.append({
            'name': name.strip(),
            'e_code': ecode.strip(),
            'status': status,
            'category': category.strip(),
            'description': clean_desc,
            'source': 'cahyadsn-halal-ecode'
        })

    print(f"Parsed {len(ingredients)} items from cahyadsn/halal SQL")
    return ingredients


def merge_and_deduplicate(sources):
    """Merge multiple data sources and remove duplicates."""
    all_ingredients = []
    seen = set()

    for source in sources:
        for item in source:
            # Create a key for deduplication
            key = (item['name'].lower(), item['e_code'].lower())

            if key not in seen and item['name']:
                seen.add(key)
                all_ingredients.append(item)

    print(f"Total unique ingredients after deduplication: {len(all_ingredients)}")
    return all_ingredients


def generate_training_examples(ingredients):
    """Generate training examples in nanochat format."""
    training_data = []

    for item in ingredients:
        name = item['name']
        status = item['status']
        e_code = item['e_code']
        desc = item['description']

        # Create concise reason based on status
        if status == 'HALAL':
            if 'plant' in desc.lower() or 'vegetable' in desc.lower():
                reason = "Plant-based ingredient, permissible in Islam."
            elif 'synthetic' in desc.lower() or 'chemical' in desc.lower():
                reason = "Synthetically produced, no animal derivatives."
            else:
                reason = "Permissible ingredient with no haram components."
        elif status == 'HARAM':
            if 'pork' in desc.lower() or 'pig' in desc.lower() or 'swine' in desc.lower():
                reason = "Derived from pork/swine, strictly forbidden in Islam."
            elif 'alcohol' in desc.lower():
                reason = "Contains alcohol, forbidden in Islam."
            elif 'insect' in desc.lower():
                reason = "Derived from insects, not permissible."
            elif 'blood' in desc.lower():
                reason = "Contains blood, forbidden in Islam."
            else:
                reason = "Contains haram components, not permissible."
        elif status == 'MASHBOOH':
            reason = "Doubtful status - source verification required. May be halal or haram depending on manufacturing process."
        elif status == 'DEPENDS':
            reason = "Status depends on source. Halal if from plant/halal animal source, haram if from pork or non-zabiha animal."
        else:
            reason = "Status unknown - requires further investigation."

        # Generate multiple question formats for each ingredient
        e_code_str = f" ({e_code})" if e_code else ""

        # Format 1: Simple question
        training_data.append({
            "input": f"Is {name}{e_code_str} halal?",
            "output": f"{status}. {reason}"
        })

        # Format 2: What is question (for E-codes)
        if e_code:
            training_data.append({
                "input": f"What is {e_code}?",
                "output": f"{e_code} is {name}. Status: {status}. {reason}"
            })

        # Format 3: Can I eat question
        if status == 'HALAL':
            training_data.append({
                "input": f"Can Muslims eat {name}?",
                "output": f"Yes, {name} is {status}. {reason}"
            })
        elif status == 'HARAM':
            training_data.append({
                "input": f"Can Muslims eat {name}?",
                "output": f"No, {name} is {status}. {reason}"
            })
        elif status in ['MASHBOOH', 'DEPENDS']:
            training_data.append({
                "input": f"Can Muslims eat {name}?",
                "output": f"It depends. {name} is {status}. {reason}"
            })

    print(f"Generated {len(training_data)} training examples")
    return training_data


def add_general_knowledge_examples():
    """Add general halal knowledge training examples."""
    return [
        # Basic concepts
        {"input": "What does halal mean?",
         "output": "Halal means 'permissible' in Arabic. It refers to food and actions that are allowed under Islamic law (Sharia)."},
        {"input": "What does haram mean?",
         "output": "Haram means 'forbidden' in Arabic. It refers to food and actions that are prohibited under Islamic law."},
        {"input": "What is mashbooh?",
         "output": "Mashbooh means 'doubtful' or 'questionable'. These are ingredients whose halal status is unclear and require source verification."},

        # General rules
        {"input": "Is pork halal?",
         "output": "HARAM. Pork and all pig-derived products are strictly forbidden in Islam. This includes bacon, ham, lard, and pork gelatin."},
        {"input": "Is alcohol halal?",
         "output": "HARAM. Alcohol consumption is forbidden in Islam. This includes alcoholic beverages and foods containing alcohol as an ingredient."},
        {"input": "Is meat halal?",
         "output": "DEPENDS. Meat is halal only if it comes from a halal animal (not pig) that was slaughtered according to Islamic guidelines (zabiha/dhabiha)."},
        {"input": "Is fish halal?",
         "output": "HALAL. Fish and seafood are generally considered halal in Islam and do not require special slaughter."},
        {"input": "Is chicken halal?",
         "output": "DEPENDS. Chicken is halal only if slaughtered according to Islamic guidelines (zabiha). Look for halal certification."},
        {"input": "Is beef halal?",
         "output": "DEPENDS. Beef is halal only if the cow was slaughtered according to Islamic guidelines (zabiha). Look for halal certification."},

        # Common problematic ingredients
        {"input": "Is gelatin halal?",
         "output": "DEPENDS. Gelatin can be halal (from fish or halal-slaughtered animals) or haram (from pork). Most commercial gelatin is pork-derived. Check the source or use alternatives like agar-agar."},
        {"input": "Is vanilla extract halal?",
         "output": "MASHBOOH. Vanilla extract typically contains 35% alcohol. Some scholars consider small amounts in food permissible if it evaporates during cooking, but many prefer alcohol-free alternatives."},
        {"input": "Is E471 halal?",
         "output": "DEPENDS. E471 (mono and diglycerides) can be plant-based (halal) or animal-derived (potentially haram if from pork). Check manufacturer source."},
        {"input": "Is E120 halal?",
         "output": "HARAM. E120 (Cochineal/Carmine) is a red dye made from crushed insects. Not permissible in Islam."},
        {"input": "Is E441 halal?",
         "output": "DEPENDS. E441 is gelatin. Halal if from fish or zabiha animals, haram if from pork. Most commercial E441 is pork-derived."},

        # Categories
        {"input": "Are E-numbers halal?",
         "output": "It varies. E-numbers are codes for food additives. Some are always halal (plant/synthetic), some are always haram (E120, E904), and many depend on their source (E441, E471, E422)."},
        {"input": "What E-numbers are haram?",
         "output": "Common haram E-numbers include: E120 (cochineal/insects), E441 (gelatin if pork), E542 (bone phosphate if pork), E904 (shellac/insects), E920-921 (L-cysteine if from hair/pigs)."},
        {"input": "Are artificial colors halal?",
         "output": "Most artificial colors are HALAL as they are synthetically produced. Exception: E120 (Cochineal) which is derived from insects and is HARAM."},
        {"input": "Are preservatives halal?",
         "output": "Most preservatives (E200-E299) are HALAL as they are typically synthetic or plant-derived. Always check for any alcohol-based preservatives."},

        # Practical questions
        {"input": "How do I know if food is halal?",
         "output": "Look for: 1) Halal certification logo, 2) 'Suitable for vegetarians' label (often safer), 3) Check ingredient list for haram items (pork, alcohol, E120, E441). When in doubt, avoid."},
        {"input": "What should I avoid?",
         "output": "Avoid: Pork and pig derivatives, alcohol, non-zabiha meat, blood, E120 (cochineal), E441 (gelatin unless halal-certified), E542 (bone phosphate), and any ingredient labeled 'animal fat' without halal certification."},
    ]


def save_training_data(training_data, output_path):
    """Save training data to JSON file."""
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(training_data, f, indent=2, ensure_ascii=False)

    print(f"Saved {len(training_data)} training examples to {output_path}")


def generate_stats(ingredients, training_data):
    """Generate statistics about the dataset."""
    stats = {
        'total_ingredients': len(ingredients),
        'total_training_examples': len(training_data),
        'by_status': {},
        'by_source': {}
    }

    for item in ingredients:
        status = item['status']
        source = item['source']

        stats['by_status'][status] = stats['by_status'].get(status, 0) + 1
        stats['by_source'][source] = stats['by_source'].get(source, 0) + 1

    return stats


def parse_additional_ingredients():
    """Parse additional curated ingredients JSON file."""
    json_path = RAW_DATA_DIR / "additional_ingredients.json"

    if not json_path.exists():
        print(f"Warning: {json_path} not found")
        return []

    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    ingredients = []
    for item in data:
        ingredients.append({
            'name': item.get('name', '').strip(),
            'e_code': item.get('e_code', '').strip() if item.get('e_code') else '',
            'status': item.get('status', 'UNKNOWN').upper(),
            'category': item.get('category', '').strip() if item.get('category') else '',
            'description': item.get('description', '').strip(),
            'source': 'curated-additional'
        })

    print(f"Parsed {len(ingredients)} items from additional_ingredients.json")
    return ingredients


def main():
    print("=" * 60)
    print("UMMALY HALAL TRAINING DATA BUILDER")
    print("=" * 60)
    print()

    # Parse data sources
    print("Phase 1: Parsing data sources...")
    e_number_data = parse_e_number_database()
    sql_data = parse_sql_database()
    additional_data = parse_additional_ingredients()

    # Parse ALL JSON ingredient files in raw directory
    extended_data = []
    json_files = list(RAW_DATA_DIR.glob("*.json"))
    for json_file in json_files:
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                ext_items = json.load(f)
            count = 0
            for item in ext_items:
                extended_data.append({
                    'name': item.get('name', '').strip(),
                    'e_code': item.get('e_code', '').strip() if item.get('e_code') else '',
                    'status': item.get('status', 'UNKNOWN').upper(),
                    'category': item.get('category', '').strip() if item.get('category') else '',
                    'description': item.get('description', '').strip(),
                    'source': f'json:{json_file.name}'
                })
                count += 1
            print(f"Parsed {count} items from {json_file.name}")
        except Exception as e:
            print(f"Error parsing {json_file.name}: {e}")

    # Merge and deduplicate
    print("\nPhase 2: Merging and deduplicating...")
    all_ingredients = merge_and_deduplicate([e_number_data, sql_data, additional_data, extended_data])

    # Generate training examples
    print("\nPhase 3: Generating training examples...")
    training_data = generate_training_examples(all_ingredients)

    # Add general knowledge
    print("\nPhase 4: Adding general halal knowledge...")
    general_knowledge = add_general_knowledge_examples()
    training_data.extend(general_knowledge)
    print(f"Added {len(general_knowledge)} general knowledge examples")

    # Save output
    print("\nPhase 5: Saving training data...")
    save_training_data(training_data, OUTPUT_FILE)

    # Generate and display stats
    print("\n" + "=" * 60)
    print("DATASET STATISTICS")
    print("=" * 60)
    stats = generate_stats(all_ingredients, training_data)

    print(f"\nTotal unique ingredients: {stats['total_ingredients']}")
    print(f"Total training examples: {stats['total_training_examples']}")

    print("\nBy halal status:")
    for status, count in sorted(stats['by_status'].items()):
        print(f"  {status}: {count}")

    print("\nBy data source:")
    for source, count in sorted(stats['by_source'].items()):
        print(f"  {source}: {count}")

    print("\n" + "=" * 60)
    print(f"SUCCESS! Training data saved to:")
    print(f"  {OUTPUT_FILE}")
    print("=" * 60)


if __name__ == "__main__":
    main()
