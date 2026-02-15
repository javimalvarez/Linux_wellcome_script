#!/bin/bash

# Configuración inicial
DATE=$(date +"%a %e %b %Y %R %Z")
REQUIRED_PKGS=("espeak-ng" "zenity" "pipewire-utils" "cowsay" "fortune-mod")
MISSING_PKGS=()
DESTINO="$HOME/.local/bin"
ARCHIVO="saludo.sh"
URL="https://www.dropbox.com/scl/fi/6kv8hzyhsh6cyteje229l/saludo.sh?rlkey=8e4xhwqi92yb6p9nf7nuh9h8c&st=2w4pq275&dl=0"
DISTRO_NAME=$(grep -P '^NAME=' /etc/os-release | cut -d'"' -f2)
DISTRO_ID=$(grep -P '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')

# Capitalizar la primera letra del usuario
USER_CAP="${USER^}"

# 1. Comprobar paquetes instalados (usando rpm para sistemas basados en debian)
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -l | grep -q "^ii  $pkg " &> /dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

# 2. Gestión de paquetes (Capa de sistema inmutable)
if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
    echo "Instalando paquetes faltantes..."
    sudo apt update && sudo apt install -y "${MISSING_PKGS[@]}"
fi

# --- A partir de aquí solo se ejecuta si todo está instalado ---

# 3. Control de volumen (PipeWire)
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.40

# 4. Obtener saludo personalizado
if [ -f "$DESTINO/$ARCHIVO" ]; then
    SALUDO=$(bash "$DESTINO/$ARCHIVO")
else
    # El script saludo.sh no existe se descarga en la carpeta de destino
    echo "El archivo $ARCHIVO no existe. Descargando..."
    wget -q -O "$DESTINO/$ARCHIVO" "$URL"
    # Verificamos si la descarga fue exitosa antes de dar permisos
    if [ -f "$DESTINO/$ARCHIVO" ]; then
        chmod +x "$DESTINO/$ARCHIVO"
        SALUDO=$(bash "$DESTINO/$ARCHIVO")
    else
        SALUDO="Hola" # Valor por defecto si falla la descarga
    fi
fi

# 5. Voz de bienvenida (espeak-ng)
espeak-ng "$SALUDO $USER_CAP. Bienvenido a Linux Mint." -v es -p 50 -s 150 2> /dev/null

# 6. Ajustar volumen final (50%)
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.50

# 7. Ventana informativa (Zenity + Fortune + Cowsay)
FORTUNE_MSG=$(fortune -s linux 2>/dev/null | fmt -w 40 | cowsay -f tux)
ICON="distributor-logo-$DISTRO_ID"

zenity --info --title="$DISTRO_NAME" \
       --text="$DATE\nHola $USER_CAP\nBienvenido a $DISTRO_NAME\n$FORTUNE_MSG" \
       --width=360 --timeout=5\
       --icon-name="$ICON"
