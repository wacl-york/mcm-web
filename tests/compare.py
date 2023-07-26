"""
    compare_exports.py
    ~~~~~~~~~~~~~~~~~~

    Compares FACSIMILE exports from two versions of the MCM.

    Expects as inputs paths to 2 folders containing exported FACSIMILES from two
    different versions of the MCM. 
    Every file with the exact same filename in both directories is compared
    for equality across a number of categories:
        - variables: The species included in the exported sub-mechanism
        - peroxies: The peroxy-radicals in the exported sub-mechanism
        - reactions: The reactions in the exported sub-mechanism
        - generics: The generic rate coefficients in the exported sub-mechanism
        - complex: The complex rate coefficients in the exported sub-mechanism
"""

import argparse
import os
import re


def parse_args():
    parser = argparse.ArgumentParser(prog="compare_exports.py",
                                     description="Compares MCM exports from two versions")
    # Yes this could probably be achieved slightly more cleanly with a single
    # list argument but this makes it more explicit that it needs just two dirs
    parser.add_argument("dir_1", help="The first directory containing MCM FACSIMILE exports")
    parser.add_argument("dir_2", help="The second directory containing MCM FACSIMILE exports")
    return parser.parse_args()

def extract_variables(text):
    # Find all compounds following VARIABLE description
    res = re.search("VARIABLE([^;]+);", text)
    # Replace new lines with space so can extract variables
    res = re.sub("\\n", " ", res[1]).strip()
    return sorted(res.split(" "))


def extract_peroxies(text):
    # Find all compounds following VARIABLE description
    res = re.search("RO2 = ([^;]+);", text)
    # Replace new lines with space so can extract variables
    res = re.sub("\\n", " ", res[1]).strip()
    peroxies = res.split("+")
    peroxies = [x.strip() for x in peroxies]
    return sorted(peroxies)


def extract_reactions(text):
    # Find all compounds following VARIABLE description
    res = re.search("\\* Reaction definitions\\. ;\\n\\*;\\n(.+)\\*;", text,
                    re.DOTALL)
    rxns = re.sub("% ", "", res[1])
    rxns = re.sub("\\n", " ", rxns)
    reactions_parsed = []
    for rxn in rxns.split(";"):
        try:
            rate, reaction = rxn.split(":")
        except ValueError:
            # Occasionally will have an error if have empty line caused by line
            # overflow, only flag as an error if this isn't the case
            if len(rxn.strip()) > 0:
                print(f"ERROR WITH SPLITTING {rxn}")
            continue
        
        # Split reaction into reactants and products
        reactants, products = reaction.split("=")
        reactants = sorted([x.strip() for x in reactants.split("+")])
        products = sorted([x.strip() for x in products.split("+")])
        reactions_parsed.append(f"{rate.strip()} : {'+'.join(reactants)} = {'+'.join(products)}")

    return reactions_parsed


def extract_generics(text):
    # Find all compounds following VARIABLE description
    res = re.search("\\* Generic Rate Coefficients ;\\n\\*;\\n(.+)\\*;\\n\\* Complex reactions ;", text,
                    re.DOTALL)
    if res is None:
        return []
    # Replace new lines with space so can extract variables
    generics = res[1].split(" ;\n")
    generics = [x.strip() for x in generics if len(x) > 0 and '=' in x]
    return sorted(generics)

def extract_complex(text):
    # Find all compounds following VARIABLE description
    res = re.search("\\* Complex reactions ;\\n\\*;\\n(.+)\\*{3,}", text,
                    re.DOTALL)
    if res is None:
        return []
    # Replace new lines with space so can extract variables
    complex = res[1].split(" ;\n")
    complex = [x.strip() for x in complex if len(x) > 0 and '=' in x]
    return sorted(complex)

def parse_file(fn):
    with open(fn, "r") as infile:
        content = infile.read()
    
    variables = extract_variables(content)
    peroxies = extract_peroxies(content)
    reactions = extract_reactions(content)
    generics = extract_generics(content)
    complex = extract_complex(content)

    return {
        'variables': variables,
        'peroxies': peroxies,
        'reactions': reactions,
        'generics': generics,
        'complex': complex
    }

def compare(results, key):
    folders = list(results.keys())
    res_1 = results[folders[0]][key]
    res_2 = results[folders[1]][key]

    miss_21 = set(res_2) - set(res_1)
    miss_12 = set(res_1) - set(res_2)
    if len(miss_21) == 0 and len(miss_12) == 0:
        print(f"{key}: success!")
    else:
        print(f"{key}: failure")
        print(f"Entries missing in {folders[0]} but present in {folders[1]}: ")
        for miss in miss_21:
            print(miss)
        print(f"Entries missing in {folders[1]} but present in {folders[0]}: ")
        for miss in miss_12:
            print(miss)

def main():
    results = {}
    args = parse_args()

    # Find test files that are in both directories
    fns_1 = set(os.listdir(args.dir_1))
    fns_2 = set(os.listdir(args.dir_2))
    test_fns = sorted(fns_1.intersection(fns_2))

    for testcase in test_fns:
        results[testcase] = {}
        for dir in [args.dir_1, args.dir_2]:
            results[testcase][os.path.basename(dir)] = parse_file(os.path.join(dir, testcase))

    for testcase in test_fns:
        print(f"\nTesting file {testcase}...")
        compare(results[testcase], 'variables')
        compare(results[testcase], 'peroxies')
        compare(results[testcase], 'reactions')
        compare(results[testcase], 'generics')
        compare(results[testcase], 'complex')

        
if __name__ == "__main__":
    main()

