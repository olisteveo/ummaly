# Ummaly Halal Training Dataset

## Overview
This folder contains the curated training data for the Ummaly halal ingredient checker model.

## Dataset Statistics
- **Total Unique Ingredients:** 3,055
- **Total Training Examples:** 6,911
- **File Size:** 1.1 MB

### By Halal Status
| Status | Count |
|--------|-------|
| HALAL | 2,023 |
| MASHBOOH | 431 |
| DEPENDS | 507 |
| HARAM | 94 |

### Data Sources
1. **E-Number-Database** (GitHub) - 562 E-codes with halal status
2. **cahyadsn/halal** (GitHub) - 569 ingredients from Indonesian halal database
3. **Curated Ingredients** - 1,875+ manually verified ingredients

## Training Data Format
The training data is in JSON format, ready for nanochat fine-tuning:

```json
{
  "input": "Is Gelatin halal?",
  "output": "DEPENDS. Status depends on source. Halal if from plant/halal animal source, haram if from pork or non-zabiha animal."
}
```

### Question Types Generated
For each ingredient, multiple question formats are generated:
1. "Is [ingredient] halal?"
2. "What is [E-code]?" (for E-numbers)
3. "Can Muslims eat [ingredient]?"

## File Structure
```
ummaly-halal-training/
├── data/
│   ├── raw/                  # Source data files
│   │   ├── E-Number-Database/
│   │   ├── halal/
│   │   └── *.json            # Curated ingredient lists
│   └── processed/
│       └── training_data.json  # Final training dataset
├── scripts/
│   └── build_training_data.py  # Data processing script
└── README.md
```

## How to Use

### Regenerate Training Data
```bash
python3 scripts/build_training_data.py
```

### Train with Nanochat
The `training_data.json` file is ready for use with nanochat fine-tuning.

## Status Definitions
- **HALAL**: Permissible - safe to consume
- **HARAM**: Forbidden - must avoid
- **MASHBOOH**: Doubtful - requires verification
- **DEPENDS**: Status varies based on source/preparation

## Notes
- This dataset focuses on accuracy over quantity
- All ingredients have been cross-referenced with Islamic sources
- E-codes cover EU food additive classifications
- Common food products and ingredients are included
