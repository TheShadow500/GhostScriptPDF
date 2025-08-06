# Funcion ProcesarCarpeta
function ProcesarCarpeta {
    param (
        [System.IO.DirectoryInfo]$carpeta,
		[string]$basepath,
		[ref]$ahorroTotal
    )
	
	Write-Host "`n>>> Procesando carpeta: " -NoNewline -ForegroundColor Cyan
	Write-Host "$($carpeta.Name)"
	
	# Accede a la carpeta
	Set-Location -LiteralPath $carpeta.FullName
	$nombreCarpetaPadre = $carpeta.Name

	# Carpeta actual
	$carpetaOrigen = (Get-Location).Path
	$carpetaPadre = Split-Path $carpetaOrigen -Leaf
	$carpetaDestino = Join-Path $carpetaOrigen $carpetaPadre

	# Crear subcarpeta si no existe
	if (-Not (Test-Path -LiteralPath $carpetaDestino)) {
		New-Item -ItemType Directory -Path $carpetaDestino | Out-Null
	}

	# Buscar PDFs
	$pdfs = Get-ChildItem -LiteralPath $carpetaOrigen -Filter *.pdf -File

	if ($pdfs.Count -eq 0) {
		Write-Host ">>> ERROR: " -NoNewline -ForegroundColor Red
		Write-host "No se encontraron archivos PDF en esta carpeta."
		return
	}

	# Comprimir
	$gsPath = Join-Path $basePath "gswin64c.exe"
	
	if (-Not (Test-Path -LiteralPath $gsPath)) {
		Write-Host ">>> ERROR: " -NoNewline -ForegroundColor Red
		Write-host "No se ha encontrado la dependencia GhostScript."
		return
	}
		
	$contador = 1
	
	foreach ($pdf in $pdfs) {
		$inFile = $pdf.FullName
		$outFile = Join-Path $carpetaDestino $pdf.Name

		$args = @(
			"-sDEVICE=pdfwrite"
			"-dCompatibilityLevel=1.4"
			"-dPDFSETTINGS=/ebook"
			"-dNOPAUSE"
			"-dQUIET"
			"-dBATCH"
			"-sOutputFile=$outFile"
			$inFile
		)

		& $gsPath @args
		
		Write-Host ">>> $($contador)/$($pdfs.Count) " -NoNewline -ForegroundColor Cyan
		Write-Host "Comprimido: " -NoNewline
		Write-Host "$pdf" -ForegroundColor Green
		
		$contador++
	}

	Write-Host ">>> PDFs comprimidos en: " -NoNewline
	Write-Host "$carpetaDestino" -ForegroundColor Green

	# Comparar y Reemplazar, 'CopiarSmaller'
	Write-Host "`nCOMPARANDO Y REEMPLAZANDO"

	$ahorro = 0
	$modificados = 0
	$totalArchivos = 0

	# Ruta completa de la carpeta hijo que tiene el mismo nombre que la carpeta padre
	$rutaCarpetaHijo = Join-Path $carpeta.FullName $nombreCarpetaPadre

	if (-Not (Test-Path -LiteralPath $rutaCarpetaHijo)) {
		Write-Host ">>> ERROR: " -NoNewline -ForegroundColor Red
		Write-Host "No existe la carpeta hijo '$nombreCarpetaPadre'"
		return
	}

	# Obtener todos los archivos PDF en la carpeta padre
	$pdfsPadre = Get-ChildItem -LiteralPath $carpeta.FullName -File -Filter *.pdf

	if ($pdfsPadre.Count -eq 0) {
		Write-Host ">>> ERROR: " -NoNewline -ForegroundColor Red
		Write-Host "No se encontraron archivos PDF en la carpeta padre."
		return
	}

	foreach ($archivoPadre in $pdfsPadre) {
		$nombreArchivo = $archivoPadre.Name

		# Buscar el archivo con el mismo nombre en la carpeta hijo
		$archivoHijo = Get-ChildItem -LiteralPath $rutaCarpetaHijo -File | Where-Object {
			$_.Name -ieq $nombreArchivo
		}

		Write-Host "`n[ Comparando archivo: $nombreArchivo ]" -ForegroundColor Cyan

		if ($archivoHijo){
			if ($archivoHijo.Length -lt $archivoPadre.Length) {
				Write-Host "Archivo Original: " -NoNewline
				Write-Host ("{0:N2} Mb" -f ($archivoPadre.Length / 1MB)) -ForegroundColor Cyan
				
				Write-Host "Archivo Editado: " -NoNewline
				Write-Host ("{0:N2} Mb <<<" -f ($archivoHijo.Length / 1MB)) -ForegroundColor Yellow
				
				Move-Item -LiteralPath $archivoHijo.FullName -Destination $archivoPadre.FullName -Force
				
				$modificados++
				$ahorro += ($archivoPadre.Length - $archivoHijo.Length)
				
				$porcentaje = [math]::Round((($archivoPadre.Length - $archivoHijo.Length) / $archivoPadre.Length) * 100, 2)
				Write-Host "Reduccion: " -NoNewline
				Write-Host "$porcentaje %" -ForegroundColor Magenta
				
				Write-Host "SOBREESCRITO" -ForegroundColor Green
			} else {
				Write-Host "Archivo Original: " -NoNewline
				Write-Host ("{0:N2} Mb <<<" -f ($archivoPadre.Length / 1MB)) -ForegroundColor Yellow
				
				Write-Host "Archivo Editado: " -NoNewline
				Write-Host ("{0:N2} Mb" -f ($archivoHijo.Length / 1MB)) -ForegroundColor Cyan
				
				Write-Host "OMITIDO" -ForegroundColor Red
			}
		} else {
			Write-Host ">>> ERROR: " -NoNewline -ForegroundColor Red
			Write-Host "No existe el archivo en la carpeta hijo."
		}
		
		$totalArchivos++
	}

	Write-Host "`nArchivos reemplazados: " -NoNewline
	Write-Host "$modificados " -ForegroundColor Green -NoNewline
	Write-Host "de $($totalArchivos) archivos"
	Write-Host "Ahorrado: " -NoNewline
	Write-Host ("{0:N2} Mb" -f ($ahorro / 1MB)) -ForegroundColor Cyan
	
	$ahorroTotal.Value += $ahorro

	# Eliminar la carpeta creada
	Write-Host "`nEliminacion de la subcarpeta auxiliar '$($carpetaPadre)'"
	$respuesta = Read-Host "Eliminar la subcarpeta '$($carpetaPadre)'? (s/n)"
	if ($respuesta -eq "s") {
		if (Test-Path -LiteralPath $carpetaDestino){
			Remove-Item -LiteralPath $carpetaDestino -Recurse -Force
			Write-Host "Carpeta '$($carpetaPadre)' eliminada." -ForegroundColor Green
		}
		else{
			Write-Host ">>> ERROR: " -NoNewline -ForegroundColor Red
			Write-Host "La carpeta ya no existe o fue eliminada previamente."
		}
	} else {
		Write-Host "Eliminacion cancelada." -ForegroundColor Green
	}
}

# MAIN
# Solicitar al usuario la ruta de destino
$ruta = Read-Host "Introduzca la ruta absoluta"

if (-Not (Test-Path -LiteralPath $ruta)) {
	Write-Host ">>> ERROR: " -NoNewline -ForegroundColor Red
	Write-Host "La carpeta '$ruta' no existe"
	return
}

$carpetaRaiz = Get-Item -LiteralPath $ruta

# Carpeta base donde se ejecuta el Script
$basePath = Get-Location

# Obtener todas las subcarpetas directas
$subcarpetas = Get-ChildItem -LiteralPath $ruta -Directory

# Almacena el ahorro total en bytes
$ahorroTotal = 0

# En caso de no encontrar subcarpetas
if ($subcarpetas.Count -eq 0){
	Write-Host ">>> ERROR: " -NoNewline -ForegroundColor Red
	Write-Host "No se encontraron subcarpetas directas en $ruta"
}

# Procesa las carpetas
foreach ($carpeta in $subcarpetas){
	ProcesarCarpeta -carpeta $carpeta -basepath $basepath -ahorroTotal ([ref]$ahorroTotal)
}

# Procesa la carpeta inicial
ProcesarCarpeta -carpeta $carpetaRaiz -basepath $basepath -ahorroTotal ([ref]$ahorroTotal)

# Muestra el resumen final
Write-Host "`nAhorro Total: " -NoNewLine
Write-Host ("{0:N2} Mb" -f ($ahorroTotal / 1MB)) -ForegroundColor Cyan
Write-Host ">>> Proceso completado`n" -ForegroundColor Green

set-Location $basePath