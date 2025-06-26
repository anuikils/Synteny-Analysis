### Synteny Analysis  

We employ an annotation-free strategy for synteny block identification and visualization. This approach is particularly useful for closely related species. For more divergent comparisons (e.g., gastropods vs. arthropods), alternative methods may be preferable.  

---

### **Prerequisites**  
1. Install [ntSynt](https://github.com/bcgsc/ntSynt/tree/main?tab=readme-ov-file) following the official documentation  
2. Create and activate a Conda environment with Snakemake:  
   ```bash
   conda create -n synteny python=3.10 snakemake
   conda activate synteny
   ```
3. **Repository Contents**:  
   - The `scripts/` directory contains modified versions of original ntSynt scripts  
   - These include minor adjustments for compatibility and methodology-specific needs  
   - All helper scripts (`format_blocks_gggenomes.sh`, `plot_synteny_blocks_gggenomes.R`, etc.) are available in `scripts/`

---

### **Preprocessing Chromosome-Level Genomes**  
Remove mitochondrial/unassigned sequences to retain only complete chromosomes:  

1. **Deroceras laeve** (first 31 sequences):  
   ```bash
   awk '/^>/ {count++} count<=31' derLae1_fullsoftmask.fasta > Deroceras_laeve_31chr.fasta
   ```

2. **Deroceras lasithionense** (first 31 sequences):  
   ```bash
   awk '/^>/ {count++} count<=31' GCA_964271515.3_xgDerLasi3.2_genomic.fna > Deroceras_lasithoniense_chr31.fasta
   ```

3. **Arion vulgaris** (first 26 sequences):  
   ```bash
   awk '/^>/ {count++} count<=26' Arion_genome_GCA_020796225.fa > Arion_vulgaris_26chr.fasta
   ```

Organize inputs:  
```bash
mkdir input_genomes
mv *.fasta input_genomes
```

---

### **Synteny Block Identification with ntSynt**  
#### *Deroceras laeve* vs. *Deroceras lasithionense*:  
```bash
mkdir ntsynt_results_dlaeve_dlasit
cd ntsynt_results_dlaeve_dlasit
ntSynt -d 15 ../input_genomes/Deroceras_laeve_31chr.fasta ../input_genomes/Deroceras_lasithionense_31chr.fasta
```

> **Note**: The provided `ntsynt_run.py` script (in `scripts/`) contains minor modifications from the original ntSynt version to resolve compatibility issues and adapt to our methodology. If step 6 fails, manually run:  
> ```bash
> python3 ../scripts/ntsynt_run.py Deroceras_laeve_31chr.fasta.k24.w1000.tsv Deroceras_lasithionense_31chr.fasta.k24.w1000.tsv -k 24 -w 1000 --w-rounds 250 100 -p ntSynt.k24.w1000 --bp 50000 --collinear-merge 100000 -z 1000 --common ntSynt.k24.w1000.common.bf --simplify-graph --btllib_t 12 --fastas ../input_genomes/Deroceras_laeve_31chr.fasta ../input_genomes/Deroceras_lasithionense_31chr.fasta
> ```

#### **Format Output for Visualization**  
```bash
../scripts/format_blocks_gggenomes.sh ntSynt.k24.w1000.synteny_blocks.tsv dlaeve_dlasit 0 ../input_genomes/Deroceras_laeve_31chr.fasta Deroceras_laeve_31chr.fasta.fai Deroceras_lasithionense_31chr.fasta.fai
```
Outputs: `dlaeve_dlasit.links.tsv` and `dlaeve_dlasit.sequence_lengths.tsv`.  

#### **Preliminary Visualization**  
```bash
Rscript ../scripts/plot_synteny_blocks_gggenomes.R -s dlaeve_dlasit.sequence_lengths.tsv -l dlaeve_dlasit.links.tsv --scale 1000000000 -p dlaeve_dlasit_1Gbp
```

#### **Chromosome Reordering**  
Based on the visualization (e.g., *D. laeve* Chr5 ≈ *D. lasithionense* Chr2), reorder chromosomes in `Deroceras_laeve_31chr.fasta`. Save as `Deroceras_laeve_31chr_ordered_as_Dlasit.fasta`.  

> **Repeat** for all pairs:  
> - *D. laeve* vs. *D. lasithionense*  
> - *D. laeve* vs. *Achatina fulica*  
> - *D. laeve* vs. *Arion vulgaris*  
>  
> Store results in separate directories (e.g., `ntsynt_results_reorder_dlaeve_dlasit`).  

---

### **Strand Normalization (ntSynt-viz)**  
Follow [ntSynt-viz](https://github.com/bcgsc/ntSynt-viz) setup:  
```bash
wget https://github.com/bcgsc/ntSynt-viz/releases/download/v1.0.0/ntSynt-viz-1.0.0.tar.gz
tar xvzf ntSynt-viz-1.0.0.tar.gz
export PATH=/path/to/ntsynt-viz/github/ntSynt-viz/bin:$PATH
```

#### **Per-Species Pair Workflow**  
1. Create a TSV file (`fais.tsv`) with `.fai` paths:  
   ```plaintext
   Deroceras_laeve_31chr_ordered_as_Dlasit.fasta.fai
   Arion_vulgaris_26chr.fasta.fai
   ```

2. Run ntSynt and post-processing (example: *A. vulgaris* vs. *D. laeve*):  
   ```bash
   ntSynt -d 5 ../input_genomes/Arion_vulgaris_26chr.fasta ../input_genomes/Deroceras_laeve_31chr_ordered_as_Dlasit.fasta
   ```
   ```bash
   python3 ../scripts/ntsynt_run.py Arion_vulgaris_26chr.fasta.k24.w1000.tsv Deroceras_laeve_31chr_ordered_as_Dlasit.fasta.k24.w1000.tsv -k 24 -w 1000 --w-rounds 100 10 -p ntSynt.k24.w1000 --bp 10000 --collinear-merge 10000 -z 500 --common ntSynt.k24.w1000.common.bf --simplify-graph --btllib_t 12 --fastas ../input_genomes/Deroceras_laeve_31chr_ordered_as_Dlasit.fasta ../input_genomes/Arion_vulgaris_26chr.fasta
   ```
   ```bash
   ../scripts/format_blocks_gggenomes.sh ntSynt.k24.w1000.synteny_blocks.tsv avulgaris_dlaeve 0 ../input_genomes/Deroceras_laeve_31chr_ordered_as_Dlasit.fasta Deroceras_laeve_31chr_ordered_as_Dlasit.fasta.fai Arion_vulgaris_26chr.fasta.fai
   ```
   ```bash
   python3 ../ntSynt-viz-1.0.0/bin/ntsynt_viz.py --blocks ntSynt.k24.w1000.synteny_blocks.tsv --fais fais.tsv --normalize --prefix avulgaris_dlaeve --ribbon_adjust 0.15 --scale 1e9
   ```

3. Format links for **NGenomeSyn**:  
   ```bash
   cut -f 2,4,5,6,8,9 avulgaris_dlaeve.links.tsv > avulgaris_dlaeve_dis5_ntSyn_to_Ngenomesyn.link
   ```

---

### **Final Visualization with NGenomeSyn**  
1. Install [NGenomeSyn](https://github.com/hewm2008/NGenomeSyn)  
2. Use provided configuration files:  
   - `dlaeve_dlasit.conf`: *D. laeve* vs. *D. lasit*  
   - `multispecies.conf`: *A. fulica* vs. *D. laeve* vs. *A. vulgaris*  
3. Run visualizations:  
   ```bash
   NGenomeSyn -c dlaeve_dlasit.conf -o pairwise_results
   NGenomeSyn -c multispecies.conf -o multispecies_results
   ```
