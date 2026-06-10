import re

with open('error.log', 'w') as f:
    f.write('''[-0.03351141139864921570] expected to equal [0.0000364162297] +/- [0.0001]
[0.03301868215203285217] expected to equal [-0.00012786347361] +/- [0.0001]
[-0.03351141139864921570] expected to equal [0.0] +/- [0.015]
[0.03301868215203285217] expected to equal [0.0] +/- [0.015]''')
