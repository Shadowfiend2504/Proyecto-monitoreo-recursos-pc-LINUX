#!/bin/bash

# Ruta del archivo de salida
ARCHIVO_SALIDA="$HOME/reporte_recursos.txt"

# Loop infinito para monitorear recursos
while true; do
    echo "========================" > "$ARCHIVO_SALIDA"
    echo "Escaneando recursos del sistema..." >> "$ARCHIVO_SALIDA"
    echo "========================" >> "$ARCHIVO_SALIDA"

    # 1. Uso del CPU
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    echo >> "$ARCHIVO_SALIDA"
    echo "Uso del CPU: $CPU%" >> "$ARCHIVO_SALIDA"

    # 2. Uso de la memoria RAM
    MEM_INFO=$(free -m)
    TOTAL_MEM=$(echo "$MEM_INFO" | awk '/Mem:/ {print $2}')
    USED_MEM=$(echo "$MEM_INFO" | awk '/Mem:/ {print $3}')
    USED_MEM_PERCENT=$((100 * USED_MEM / TOTAL_MEM))
    echo >> "$ARCHIVO_SALIDA"
    echo "Uso de la memoria RAM: $USED_MEM_PERCENT%" >> "$ARCHIVO_SALIDA"

    # 3. Espacio de los discos
    echo >> "$ARCHIVO_SALIDA"
    echo "Uso de los discos:" >> "$ARCHIVO_SALIDA"
    df -h --output=source,size,used,avail,pcent | tail -n +2 >> "$ARCHIVO_SALIDA"

    # 4. Uso de la GPU (para sistemas con NVIDIA)
    echo >> "$ARCHIVO_SALIDA"
    echo "Uso de la GPU:" >> "$ARCHIVO_SALIDA"
    if command -v nvidia-smi &>/dev/null; then
        nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.free --format=csv,noheader >> "$ARCHIVO_SALIDA"
    else
        echo "No se detectó una GPU NVIDIA." >> "$ARCHIVO_SALIDA"
    fi

    # Alerta si algún recurso supera los límites
    if (( $(echo "$CPU >= 90" | bc -l) )); then
        notify-send "¡Alerta!" "Uso de CPU elevado: $CPU%"
    fi

    if (( $USED_MEM_PERCENT >= 90 )); then
        notify-send "¡Alerta!" "Uso de memoria RAM elevado: $USED_MEM_PERCENT%"
    fi

    DISCO_ALTO=$(df -h --output=pcent / | tail -1 | tr -dc '0-9')
    if (( $DISCO_ALTO >= 80 )); then
        notify-send "¡Alerta!" "Uso de disco elevado: $DISCO_ALTO%"
    fi

    # Esperar 10 minutos antes de repetir
    sleep 600
done
