"""
    compare_structural_drawings.py
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    Creates a comparison of drawings generated using RDKit and the old images we
    had.
    The comparison is in a big HTML file.
"""
import sqlite3

con = sqlite3.connect("mcm.db")
cur = con.cursor()

def make_comparison_table(mechanism, output_fn):
    cur.execute("SELECT Name, Smiles, Inchi, Mechanism From Species INNER JOIN SpeciesMechanisms USING(Name) WHERE Mechanism = ?",
                (mechanism,))
    res = cur.fetchall()

    table_contents = []
    for i, row in enumerate(res):
        name, smiles, inchi, mechanism = row
        fp = f"test-images/{mechanism}/{name}"
        fn_smiles = f"{fp}_smiles.svg"
        fn_inchi = f"{fp}_inchi.svg"
        fn_old = f"public/species_images/{name}.png"
        row = f"""
            <tr>
                <td>
                  {i+1}
                </td>
                <td>
                  {name}
                </td>
                <td>
                  <img src='{fn_old}'/>
                </td>
                <td>
                  <img src='{fn_smiles}'/>
                </td>
                <td>
                  <img src='{fn_inchi}'/>
                </td>
            </tr>
        """
        table_contents.append(row)
    table_contents = '\n'.join(table_contents)

    output_html = f"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>{mechanism} Structural Drawings</title>
         <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
      </head>
    <body>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>
      <h1>{mechanism} Structural Drawings</h1>
      <table class='table table-hover table-sm w-auto'>
        <thead>
            <tr>
              <td>Species Number</td>
              <td>Species</td>
              <td>Old</td>
              <td>New - from Smiles</td>
              <td>New - from Inchi</td>
            </tr>
        </thead>
        <tbody class="table-group-divider">
            {table_contents}
        </tbody>
      </table>
    </body>
    </html>
    """

    with open(output_fn, "w") as outfile:
        outfile.write(output_html)

make_comparison_table("MCM", "structural_drawings_MCM.html")
make_comparison_table("CRI", "structural_drawings_CRI.html")

con.close()
