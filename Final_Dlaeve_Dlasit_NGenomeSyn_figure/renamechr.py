import os
import sys
import pandas as pd

def rename_identifiers(a_file: str, b_file: str, my_link_file: str, out_prefix: str, out_path: str):
    """
    Renames identifiers in .len and .link files, replacing them with standardized chromosome names.

    Parameters:
        a_file (str): Path to the first .len file.
        b_file (str): Path to the second .len file.
        my_link_file (str): Path to the .link file.
        out_prefix (str): Prefix for the output files.
        out_path (str): Directory where the output files will be saved.

    Returns:
        None
    """

    # Ensure output directory exists
    if not os.path.exists(out_path):
        os.makedirs(out_path)

    # Read the .len files
    a_df = pd.read_csv(a_file, sep="\t", header=None)
    b_df = pd.read_csv(b_file, sep="\t", header=None)

    # Assign new identifiers (using only numbers)
    a_mapping = {old: str(i+1) for i, old in enumerate(a_df[0])}
    b_mapping = {old: str(i+1) for i, old in enumerate(b_df[0])}

    # Rename identifiers in .len files
    a_df[0] = a_df[0].map(a_mapping)
    b_df[0] = b_df[0].map(b_mapping)

    # Read and update the .link file
    link_df = pd.read_csv(my_link_file, sep="\t", header=None)
    link_df[0] = link_df[0].map(a_mapping)  # Update A identifiers, col 1
    link_df[3] = link_df[3].map(b_mapping)  # Update B identifiers, col 3

    # Check for unmapped identifiers
    if link_df[0].isna().any() or link_df[3].isna().any():
        print("Warning: Some identifiers in the .link file were not found in the .len files!")

    # Output file names
    out_file_prefix = f"{out_path}{out_prefix}_"
    out_file_a = f"{out_file_prefix}{os.path.basename(a_file)}"
    out_file_b = f"{out_file_prefix}{os.path.basename(b_file)}"
    out_file_link = f"{out_file_prefix}{os.path.basename(my_link_file)}"

    # Write output files
    a_df.to_csv(out_file_a, sep="\t", index=False, header=False)
    b_df.to_csv(out_file_b, sep="\t", index=False, header=False)
    link_df.to_csv(out_file_link, sep="\t", index=False, header=False)

    print(f"Renaming completed. Output files saved: {out_file_prefix}...")


if __name__ == "__main__":
    if len(sys.argv) != 6:
        print("Usage: python rename_identifiers.py <A.len> <B.len> <links.link> <output_prefix> <output_path>")
        sys.exit(1)

    len_a_file = sys.argv[1]
    len_b_file = sys.argv[2]
    link_file = sys.argv[3]
    output_prefix = sys.argv[4]
    output_path = sys.argv[5]

    output_path = output_path if output_path.endswith("/") else f"{output_path}/"
    rename_identifiers(len_a_file, len_b_file, link_file, output_prefix, output_path)
