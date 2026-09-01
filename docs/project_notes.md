# Project Notes: Data Dictionary & Design Decisions

## Data Dictionary

Source: [Predicting Manufacturing Defects Dataset](https://www.kaggle.com/datasets/rabieelkharoua/predicting-manufacturing-defects-dataset) (Kaggle, synthetic).

| Column | Data Type | Range | Unit / Meaning |
|---|---|---|---|
| ProductionVolume | Integer | 100–1000 | Units produced per day |
| ProductionCost | Float | $5,000–$20,000 | Cost incurred per day |
| SupplierQuality | Float (%) | 80–100% | Quality rating of suppliers |
| DeliveryDelay | Integer (days) | 0–5 | Average delivery delay |
| DefectRate | Float | 0.5–5.0 | Defects per thousand units produced |
| QualityScore | Float (%) | 60–100% | Overall quality assessment |
| MaintenanceHours | Integer | 0–24 | Hours spent on maintenance **per week** |
| DowntimePercentage | Float (%) | 0–5% | Percentage of production downtime |
| InventoryTurnover | Float | 2–10 | Inventory turnover ratio |
| StockoutRate | Float (%) | 0–10% | Rate of inventory stockouts |
| WorkerProductivity | Float (%) | 80–100% | Workforce productivity level |
| SafetyIncidents | Integer | 0–10 | Safety incidents **per month** |
| EnergyConsumption | Float (kWh) | 1,000–5,000 | Energy consumed |
| EnergyEfficiency | Float | 0.1–0.5 | Energy usage efficiency factor |
| AdditiveProcessTime | Float (hours) | 1–10 | Time for additive manufacturing step |
| AdditiveMaterialCost | Float ($) | $100–$500 | Cost of additive materials per unit |
| **DefectStatus** | Binary | 0 or 1 | **Target.** 0 = Low Defects, 1 = High Defects |

**Note on units:** the documented granularities are inconsistent across columns — ProductionVolume/ProductionCost are daily, MaintenanceHours is weekly, SafetyIncidents is monthly. This means each row cannot represent a single consistent time window across all fields. See Data Quality Findings below for how this shaped the analysis approach.

---

## Design Decisions & Reasoning

### Why MaintenanceHours as the primary variable
A correlation scan against `DefectStatus` across all 16 predictor columns showed MaintenanceHours as the strongest signal (r = 0.297). `DefectRate` (r = 0.246) was excluded as a predictor since it is very likely the continuous metric `DefectStatus` was derived/binned from — using it would constitute data leakage. `QualityScore` (r = −0.199) was a secondary candidate but is somewhat circular as a finding, since a "quality score" being linked to defects is close to true by definition.

### Why split at the median, not the mean
The median guarantees a balanced ~50/50 group split by definition, which gives a two-proportion z-test more reliable statistical power. The mean has no such guarantee and can sit off-center if a distribution is skewed. In this dataset, mean (11.48) and median (12.00) happened to be close, so this mattered less in practice — but median remains the more defensible default regardless of a given variable's shape.

### Why a two-proportion z-test
`DefectStatus` is a binary outcome, and the comparison is between proportions (% defective in each group) — the exact scenario a two-proportion z-test is built for. A chi-square test of independence would be mathematically equivalent for this 2×2 comparison; the z-test was chosen because it directly yields a confidence interval on the size of the difference, which is more actionable for a business recommendation than a chi-square p-value alone.

### Why 2-hour maintenance bins (and validation)
2-hour bins balanced resolution (fine enough to reveal pattern shape) against per-bin sample size (~250+ records per bin, keeping rate estimates stable). To confirm this wasn't an artifact of bin width, the analysis was re-run at 1-hour resolution — the same threshold effect appeared at the same location (~10–11 hours), confirming the finding is robust to bin choice.

### Why the Production Volume × Supplier Quality matrix
Both variables showed weaker individual correlation with defects than MaintenanceHours. Rather than treating them as two independent effects, a matrix was used to test for an **interaction effect** — whether supplier quality's influence on defect rate changes depending on production volume. It does: supplier quality shows a real effect at Low/Medium volume (77–87% defect rate range) but stops mattering at Very High volume (96–98% regardless of supplier quality).

---

## Data Quality Findings

An internal consistency check was run before trusting the dataset's structure:

- **Near-zero correlations between logically-related fields.** MaintenanceHours vs DowntimePercentage, SafetyIncidents vs DowntimePercentage, and WorkerProductivity vs DefectRate all showed correlations close to 0, despite plausibly being related in a real factory. This suggests most columns were generated largely independently, rather than through a fully realistic causal simulation.
- **Inconsistent time granularities**, as noted in the data dictionary above (daily/weekly/monthly fields mixed within single rows), reinforcing that this is not a coherent time-series log.
- **Implication for methodology:** the analysis was deliberately kept cross-sectional (comparing groups within the dataset), with no time-series claims made, since the data does not support that interpretation.
- **The overall 84% defect rate is unusually high** for a real production line and should not be read as representative of real-world defect rates. The focus of this analysis is on *relative* risk factors between groups, not absolute rates.

These findings are disclosed transparently rather than treated as a flaw to hide — auditing data quality before analyzing is treated here as part of the analysis itself, not a separate afterthought.
