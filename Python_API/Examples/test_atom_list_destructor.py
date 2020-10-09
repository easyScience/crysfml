import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir)))

import CFML_api

filename = sys.argv[1]
cif_file = CFML_api.CIFFile(filename)
atom_list = cif_file.atom_list

while True:
    atom_list.natoms
    atom1 = atom_list[0]
    atom2 = atom_list[1]
    atom1.xyz
    atom_list[0]=atom2
    atom_list[1]=atom1
    atom = CFML_api.Atom('ATOM C C 0.0 0.0 0.0 0.2 0.5')
    atom_new = CFML_api.Atom('ATOM C C 0.0 0.0 0.0 0.2 0.5')
    atom_list[0] = atom_new