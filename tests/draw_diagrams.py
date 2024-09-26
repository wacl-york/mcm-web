"""
    draw_diagrams.py
    ~~~~~~~~~~~~~~~~

    Draws structural diagrams for all species in the MCM using both Inchi and
    Smiles.
"""

import sqlite3
from rdkit import Chem
from rdkit.Chem import Draw

def draw_molecule(mol, filename, width=150, height=150):
    d2d = Draw.MolDraw2DSVG(width, height)
    dopts = d2d.drawOptions()
    dopts.useBWAtomPalette()
    dopts.bondLineWidth = 1
    dopts.additionalAtomLabelPadding = 0.1
    dopts.fixedFontSize = 12
    d2d.DrawMolecule(mol)
    d2d.FinishDrawing()
    img = d2d.GetDrawingText()
    with open(filename, "w") as outfile:
        outfile.write(img)

con = sqlite3.connect("mcm.db")
cur = con.cursor()
cur.execute("SELECT Name, Smiles, Inchi, Mechanism From Species INNER JOIN SpeciesMechanisms USING(Name)")
res = cur.fetchall()

for i, row in enumerate(res):
    if i % 50 == 0:
        print(f"Drawing molecule {i}/{len(res)} ({i/len(res)*100:.2f}%)")
    name, smiles, inchi, mechanism = row

    fp = f"test-images/{mechanism}/{name}"

    if smiles is not None:
        mol_smiles = Chem.MolFromSmiles(smiles)
        fn_smiles = f"{fp}_smiles.svg"
        draw_molecule(mol_smiles, fn_smiles)

    if inchi is not None:
        mol_inchi = Chem.inchi.MolFromInchi(inchi)
        fn_inchi = f"{fp}_inchi.svg"
        draw_molecule(mol_inchi, fn_inchi)

con.close()
