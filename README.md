GhostScriptPDF es un script en PowerShell creado por Daniel Amores. Está diseñado para comprimir archivos PDF en carpetas, reemplazar los originales solo si el comprimido es más pequeño, y mostrar el ahorro total en espacio, con una lógica muy cuidada y visual. A continuación, te explico en detalle qué hace paso a paso:

________________________________________

🧾 RESUMEN GENERAL

El script:
	1.	Solicita una ruta de carpeta raíz al usuario.
	2.	Busca subcarpetas directas dentro de esa ruta.
	3.	Procesa cada subcarpeta y la carpeta raíz:
		o	Busca los archivos .pdf.
		o	Los comprime usando GhostScript (gswin64c) dentro de una subcarpeta auxiliar con el mismo nombre.
		o	Compara el archivo original con el comprimido.
		o	Reemplaza el original si el comprimido es más pequeño.
		o	Muestra ahorro individual y acumulado.
		o	Pregunta si quieres eliminar la subcarpeta auxiliar creada.
	4.	Muestra un resumen final del ahorro total en MB.

________________________________________

🔁 FUNCIÓN ProcesarCarpeta

Parámetros:
	•	$carpeta: objeto DirectoryInfo de la carpeta a procesar.
	•	$basepath: ruta base del script utilizado para saber la ruta de GhostScript.
	•	[ref]$ahorroTotal: acumulador por referencia del ahorro total en espacio.

Flujo interno de la función:
	🟦 1. Preparativos:
		•	Cambia el directorio a la carpeta a procesar.
		•	Define rutas para trabajar: carpeta origen, nombre, destino (subcarpeta auxiliar).
	🟦 2. Comprimir PDFs:
		•	Busca PDFs en esa carpeta.
		•	Si no hay, muestra error y sale.
		•	Comprime cada PDF usando GhostScript y lo guarda en la subcarpeta auxiliar.

	🟦 3. Comparar y reemplazar:
		•	Compara cada archivo original con su equivalente comprimido.
		•	Si el comprimido es menor:
			o	Muestra ahorro en MB y porcentaje.
			o	Reemplaza el original con el comprimido.
			o	Suma al total de ahorro.
		•	Si no, omite el reemplazo.
	🟦 4. Eliminar subcarpeta auxiliar:
		•	Pregunta al usuario si desea borrar la subcarpeta auxiliar (la de los comprimidos).
		•	Si responde "s", la borra con Remove-Item -Recurse -Force.

________________________________________

🟨 BLOQUE PRINCIPAL (Main)

	1.	Pide al usuario una ruta absoluta.
	2.	Obtiene:
		o	Carpeta raíz ($carpetaRaiz)
		o	Subcarpetas directas ($subcarpetas)
	3.	Procesa cada subcarpeta.
	4.	Luego procesa la raíz también.
	5.	Al final, muestra el ahorro total acumulado.

________________________________________

🛠️ TECNOLOGÍAS USADAS

	•	PowerShell
	•	GhostScript (gswin64c) para comprimir PDFs
	•	Get-ChildItem, Set-Location, Join-Path, Split-Path, etc.
	•	Uso de [ref] para pasar variables por referencia
	•	Validaciones con Test-Path, -lt, etc.
	•	Interacción con el usuario (Read-Host)

________________________________________

📌 EJEMPLO VISUAL

Imagina que tienes esta estructura:
C:\Documentos\Proyecto\
├── PDF1.pdf (3 MB)
├── PDF2.pdf (5 MB)
├── ClienteA\
│   ├── ReporteA.pdf (10 MB)
│   └── ReporteB.pdf (8 MB)
├── ClienteB\
│   └── Informe.pdf (4 MB)

Si usas el script con:
Introduzca la ruta absoluta: C:\Documentos\Proyecto

Procedimiento:
	•	Procesará primero ClienteA, ClienteB.
	•	Luego la carpeta raíz Proyecto.
	•	Comprimirá cada PDF, y si la versión comprimida pesa menos, reemplazará el original.
	•	Al final te dirá:
	"Ahorro total: 12.53 Mb"

________________________________________

✅ CONCLUSIÓN
Este script es una herramienta potente para optimizar almacenamiento de PDFs sin perder control ni romper archivos originales. Incluye validaciones, backups temporales, compresión segura y limpieza asistida.
