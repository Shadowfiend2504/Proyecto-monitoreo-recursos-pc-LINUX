#!/bin/bash

ARCHIVO_SALIDA="reporte_recursos.txt"

while true; do
    echo "========================" > $ARCHIVO_SALIDA
    echo "Escaneando recursos del sistema..." >> $ARCHIVO_SALIDA
    echo "========================" >> $ARCHIVO_SALIDA

    # 1. Uso del CPU
    echo "" >> $ARCHIVO_SALIDA
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    echo "Uso del CPU: ${CPU}%" >> $ARCHIVO_SALIDA

    # 2. Uso de la memoria RAM
    echo "" >> $ARCHIVO_SALIDA
    MEM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
    MEM_USADA=$(free -m | awk '/^Mem:/ {print $3}')
    MEM_PORC=$(awk "BEGIN {printf \"%.2f\", ($MEM_USADA/$MEM_TOTAL)*100}")
    echo "Uso de la memoria RAM: ${MEM_PORC}%" >> $ARCHIVO_SALIDA

    # 3. Espacio de los discos
    echo "" >> $ARCHIVO_SALIDA
    echo "Uso de los discos:" >> $ARCHIVO_SALIDA
    df -h --output=source,size,used,avail,pcent | grep -vE '^Filesystem' >> $ARCHIVO_SALIDA

    # 4. Uso de la GPU (si existe)
    echo "" >> $ARCHIVO_SALIDA
    echo "Uso de la GPU:" >> $ARCHIVO_SALIDA
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.free --format=csv,noheader >> $ARCHIVO_SALIDA
    else
        echo "No se detectó una GPU NVIDIA." >> $ARCHIVO_SALIDA
    fi

    # 5. Información de procesos
    echo "" >> $ARCHIVO_SALIDA
    echo "== INFORMACIÓN DE PROCESOS Y MEMORIA ==" >> $ARCHIVO_SALIDA
    ps aux --sort=-%mem | head -n 15 >> $ARCHIVO_SALIDA

    echo "" >> $ARCHIVO_SALIDA
    echo "========================" >> $ARCHIVO_SALIDA
    echo "Escaneo completado." >> $ARCHIVO_SALIDA
    echo "========================" >> $ARCHIVO_SALIDA
    echo "La información se ha guardado en $ARCHIVO_SALIDA"

    # Crear un acceso directo en caso de alto uso de recursos
    ESCRITORIO="$HOME/Desktop"

    if (( $(echo "$CPU >= 90" | bc -l) )); then
        ln -sf "$(pwd)/$ARCHIVO_SALIDA" "$ESCRITORIO/Alerta_CPU.txt"
    fi

    if (( $(echo "$MEM_PORC >= 90" | bc -l) )); then
        ln -sf "$(pwd)/$ARCHIVO_SALIDA" "$ESCRITORIO/Alerta_RAM.txt"
    fi

    if command -v nvidia-smi &> /dev/null; then
        GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{print $1}')
        if (( $(echo "$GPU_UTIL >= 80" | bc -l) )); then
            ln -sf "$(pwd)/$ARCHIVO_SALIDA" "$ESCRITORIO/Alerta_GPU.txt"
        fi
    fi

    # Espera 300 segundos antes de repetir
    sleep 300
done
