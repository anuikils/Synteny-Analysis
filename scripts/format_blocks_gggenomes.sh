#!/bin/bash

# Format the input synteny blocks for visualization with gggenomes

if [ $# -lt 6 ]; then
    echo "Usage: $(basename $0) <synteny blocks TSV> <prefix> <length threshold> <assembly to use for colour> <FAI> <FAI> [FAI..]"
    echo "NOTE: The order of FAI files will dictate the order of the genomes in the ribbon plot"
    exit 1
fi

synteny_tsv=$1; shift
prefix=$1; shift
length_threshold=$1; shift
target_colour=$1; shift
fais=$@

set -eux -o pipefail

# Sort the blocks based on the specified order
/mnt/Part3/LuisHernandez/sinteny_data/ntSynt/prueba1chrdladlas/sort_ntsynt_blocks.py --synteny_blocks ${synteny_tsv} --sort_order ${fais} --fais > ${prefix}.synteny_blocks.sorted.tsv

# Generate the files needed for plotting with gggenome
/mnt/Part3/LuisHernandez/sinteny_data/ntSynt/prueba1chrdladlas/format_blocks_gggenomes.py --fai ${fais} --prefix ${prefix} --blocks ${prefix}.synteny_blocks.sorted.tsv \
    --length ${length_threshold} --colour ${target_colour}
# Determine column numbers for 'block_id' and 'strand' from the header
block_id_col=$(head -n 1 ${prefix}.links.tsv | tr '\t' '\n' | grep -n '^block_id$' | cut -d: -f1)
strand_col=$(head -n 1 ${prefix}.links.tsv | tr '\t' '\n' | grep -n '^strand$' | cut -d: -f1)

# Sort the data by 'strand' (lexicographically) and 'block_id' (numerically), keeping the header
(head -n 1 ${prefix}.links.tsv && tail -n +2 ${prefix}.links.tsv | sort -t$'\t' -k "${strand_col},${strand_col}" -k "${block_id_col},${block_id_col}n") > ${prefix}.links.sorted.tsv && mv ${prefix}.links.sorted.tsv ${prefix}.links.tsv
