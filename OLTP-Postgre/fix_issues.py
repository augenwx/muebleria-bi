import os

base_dir = r"c:\Users\Usuario\Documents\muebleria-bi\OLTP-Postgre"

replacements = {
    'CÃ³moda': 'Cómoda',
    'ComodÃ­n': 'Comodín',
    'MarÃ­a': 'María',
    'GarcÃ­a': 'García',
    'DÃ­az': 'Díaz',
    'PÃ©rez': 'Pérez',
    'TelÃ©fono': 'Teléfono',
    'LogÃ­stica': 'Logística',
    'ProducciÃ³n': 'Producción',
    'MUEBLERÃ\x8fA': 'MUEBLERÍA',
    'CARPINTERÃ\x8fA': 'CARPINTERÍA',
    'GutiÃ©rrez': 'Gutiérrez',
    'AlmacÃ©n': 'Almacén',
    'OperaciÃ³n': 'Operación',
    'crÃ©dito': 'crédito',
    'CrÃ©dito': 'Crédito',
    'AÃ±o': 'Año',
    'aÃ±o': 'año',
    'diseÃ±o': 'diseño',
    'DiseÃ±o': 'Diseño',
    'Ã¡': 'á',
    'Ã©': 'é',
    'Ã­': 'í',
    'Ã³': 'ó',
    'Ãº': 'ú',
    'Ã±': 'ñ',
    'Ã\x81': 'Á',
    'Ã\x89': 'É',
    'Ã\x8d': 'Í',
    'Ã\x93': 'Ó',
    'Ã\x9a': 'Ú',
    'Ã\x91': 'Ñ'
}

files = [
    'base_datos_transaccional.sql',
    'datos_enero_2026.sql',
    'datos_febrero_2026.sql',
    'datos_marzo_2026.sql'
]

for filename in files:
    path = os.path.join(base_dir, filename)
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    for bad, good in replacements.items():
        content = content.replace(bad, good)
        
    # Fix the stock to 100
    if filename == 'base_datos_transaccional.sql':
        content = content.replace('(1, 0, 5)', '(1, 100, 5)')
        content = content.replace('(2, 0, 10)', '(2, 100, 10)')
        content = content.replace('(3, 0, 5)', '(3, 100, 5)')
        content = content.replace('(4, 0, 5)', '(4, 100, 5)')
        content = content.replace('(5, 0, 3)', '(5, 100, 3)')
        content = content.replace('(6, 0, 5)', '(6, 100, 5)')
        # And materials stock too, just in case!
        content = content.replace('(1, 0, 10)', '(1, 100, 10)')
        content = content.replace('(2, 0, 5)', '(2, 100, 5)')
        content = content.replace('(3, 0, 10)', '(3, 100, 10)')
        content = content.replace('(4, 0, 2)', '(4, 100, 2)')
        content = content.replace('(5, 0, 2)', '(5, 100, 2)')
        content = content.replace('(6, 0, 20)', '(6, 100, 20)')
        content = content.replace('(7, 0, 20)', '(7, 100, 20)')
        content = content.replace('(8, 0, 5)', '(8, 100, 5)')
        content = content.replace('(9, 0, 50)', '(9, 100, 50)')
        content = content.replace('(10, 0, 50)', '(10, 100, 50)')
        content = content.replace('(11, 0, 5)', '(11, 100, 5)')

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Fixes applied!")
