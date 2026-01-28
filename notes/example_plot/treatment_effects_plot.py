import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

np.random.seed(42)

# Define the structure
treatments = ['Treatment A', 'Treatment B', 'Treatment C']
outcomes = ['Outcome 1', 'Outcome 2']
splitting_vars = ['Age (Young/Old)', 'Gender (M/F)', 'Region (Urban/Rural)', 'Income (Low/High)']
subgroups = ['Low', 'High']  # Generic labels for the two halves of each split

# Simulate treatment effects with confidence intervals
# In reality, these would come from your regression models
data = []

for split_var in splitting_vars:
    for outcome in outcomes:
        for treatment in treatments:
            for subgroup in subgroups:
                # Simulate a treatment effect (could be positive or negative)
                # Add some heterogeneity across subgroups
                base_effect = np.random.uniform(-0.5, 0.8)
                subgroup_modifier = 0.3 if subgroup == 'High' else -0.1
                effect = base_effect + subgroup_modifier + np.random.normal(0, 0.1)
                
                # Simulate standard error (for CI)
                se = np.random.uniform(0.1, 0.25)
                
                data.append({
                    'splitting_var': split_var,
                    'outcome': outcome,
                    'treatment': treatment,
                    'subgroup': subgroup,
                    'effect': effect,
                    'se': se,
                    'ci_lower': effect - 1.96 * se,
                    'ci_upper': effect + 1.96 * se
                })

df = pd.DataFrame(data)

# Create the faceted plot - WIDE LAYOUT: 2 rows (outcomes) x 4 cols (splitting vars)
fig, axes = plt.subplots(2, 4, figsize=(16, 7), sharey=True)
fig.suptitle('Treatment Effects by Subgroup', fontsize=14, fontweight='bold', y=0.98)

# Color palette for treatments
colors = {'Treatment A': '#1f77b4', 'Treatment B': '#ff7f0e', 'Treatment C': '#2ca02c'}

# Marker styles for subgroups
markers = {'Low': 'o', 'High': 's'}

# Vertical offset to separate subgroups within each treatment
offsets = {'Low': -0.15, 'High': 0.15}

for i, outcome in enumerate(outcomes):
    for j, split_var in enumerate(splitting_vars):
        ax = axes[i, j]
        
        # Filter data for this facet
        facet_data = df[(df['splitting_var'] == split_var) & (df['outcome'] == outcome)]
        
        # Plot each treatment × subgroup combination
        for k, treatment in enumerate(treatments):
            for subgroup in subgroups:
                row = facet_data[(facet_data['treatment'] == treatment) & 
                                 (facet_data['subgroup'] == subgroup)].iloc[0]
                
                y_pos = k + offsets[subgroup]
                
                # Plot point and CI
                ax.errorbar(
                    row['effect'], y_pos,
                    xerr=[[row['effect'] - row['ci_lower']], [row['ci_upper'] - row['effect']]],
                    fmt=markers[subgroup],
                    color=colors[treatment],
                    markersize=8,
                    capsize=3,
                    capthick=1.5,
                    elinewidth=1.5,
                    label=f"{subgroup}" if k == 0 else ""
                )
        
        # Add vertical line at 0
        ax.axvline(x=0, color='gray', linestyle='--', linewidth=1, alpha=0.7)
        
        # Set y-axis
        ax.set_yticks(range(len(treatments)))
        ax.set_yticklabels(treatments)
        ax.set_ylim(-0.5, len(treatments) - 0.5)
        
        # Labels
        if i == 1:  # Bottom row
            ax.set_xlabel('Treatment Effect (95% CI)')
        if i == 0:  # Top row - column titles
            ax.set_title(split_var, fontsize=10, fontweight='bold')
        if j == 0:  # Left column - row labels
            ax.set_ylabel(outcome, fontsize=11, fontweight='bold')
        
        # Grid
        ax.grid(axis='x', alpha=0.3)
        ax.set_axisbelow(True)

# Create legend for subgroups
from matplotlib.lines import Line2D
legend_elements = [
    Line2D([0], [0], marker='o', color='gray', label='Low/First subgroup',
           markerfacecolor='gray', markersize=8, linestyle='None'),
    Line2D([0], [0], marker='s', color='gray', label='High/Second subgroup',
           markerfacecolor='gray', markersize=8, linestyle='None'),
]

# Add color legend for treatments
for treatment, color in colors.items():
    legend_elements.append(
        Line2D([0], [0], marker='o', color=color, label=treatment,
               markerfacecolor=color, markersize=8, linestyle='None')
    )

fig.legend(handles=legend_elements, loc='lower center', ncol=5, 
           bbox_to_anchor=(0.5, 0.01), frameon=True, fontsize=10)

plt.tight_layout(rect=[0, 0.05, 1, 0.96])
plt.savefig('/home/claude/treatment_effects_plot.png', dpi=150, bbox_inches='tight', 
            facecolor='white', edgecolor='none')
plt.close()

print("Plot saved to treatment_effects_plot.png")
print(f"\nDataFrame shape: {df.shape}")
print(f"Total effects plotted: {len(df)}")
print("\nSample of the data:")
print(df.head(12).to_string(index=False))
