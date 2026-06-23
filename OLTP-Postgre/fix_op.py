import os

base_dir = r"c:\Users\Usuario\Documents\muebleria-bi\OLTP-Postgre"

def fix_file(filename, replacements):
    path = os.path.join(base_dir, filename)
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    for old, new in replacements:
        content = content.replace(old, new)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# Enero: OP-2026-00 -> OP-2026-10
fix_file('datos_enero_2026.sql', [('OP-2026-00', 'OP-2026-10')])

# Febrero: OP-2026-00 -> OP-2026-20
fix_file('datos_febrero_2026.sql', [('OP-2026-00', 'OP-2026-20')])

# Mayo: April copied -> OP-2026-00 -> 50, OP-2026-01 -> 51
fix_file('datos_mayo_2026.sql', [('OP-2026-00', 'OP-2026-50'), ('OP-2026-01', 'OP-2026-51')])

print("Fixed OP numbers!")
