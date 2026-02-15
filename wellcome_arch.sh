#!/bin/bash

# Configuración inicial
DATE=$(date +"%a %e %b %Y %R %Z")
# En Arch, los nombres de paquetes suelen ser iguales, pero 'fortune-mod' es la base común
REQUIRED_PKGS=("espeak-ng" "zenity" "pipewire-utils" "cowsay" "fortune-mod")
MISSING_PKGS=()
DESTINO="$HOME/.local/bin"
ARCHIVO="saludo.sh"
RUTA_COMPLETA="$DESTINO/$ARCHIVO"
URL="https://www.dropbox.com"
DISTRO_NAME=$(grep -P '^NAME=' /etc/os-release | cut -d'"' -f2)
DISTRO_ID=$(grep -P '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')

USER_CAP="${USER^}"
mkdir -p "$DESTINO"

# 1. Comprobar paquetes instalados (Arch Linux / pacman)
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! pacman -Qi "$pkg" &> /dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

# 2. Gestión de paquetes (pacman)
if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
    echo "Instalando paquetes faltantes con pacman..."
    sudo pacman -S --noconfirm "${MISSING_PKGS[@]}"
fi

# --- A partir de aquí solo se ejecuta si todo está instalado ---

# 3. Control de volumen (PipeWire)
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.40

# 4. Obtener saludo (Corregido con RUTA_COMPLETA para evitar re-descargas)
if [ -f "$RUTA_COMPLETA" ]; then
    SALUDO=$(bash "$RUTA_COMPLETA")
else
    wget -q -O "$RUTA_COMPLETA" "$URL"
    chmod +x "$RUTA_COMPLETA" 2>/dev/null
    SALUDO=$(bash "$RUTA_COMPLETA" 2>/dev/null || echo "Hola")
fi

# 5. Voz de bienvenida
espeak-ng "$SALUDO $USER_CAP. Bienvenido a Garuda Linux." -v es -p 50 -s 150 2> /dev/null &

# 6. Ajustar volumen final
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.50

# 7. Ventana informativa (Zenity con altura limitada)
# En Arch, fortune-mod instala los archivos en /usr/share/fortune/
FORTUNE_MSG=$(fortune -s linux 2>/dev/null || fortune -s)
COW_MSG=$(echo "$FORTUNE_MSG" | fmt -w 40)

zenity --info --title="$DISTRO_NAME" \
       --text="$(cowsay -f tux "$DATE"$'\n'"Hola $USER_CAP"$'\n'"Bienvenido a $DISTRO_NAME"$'\n\n'"$COW_MSG")"\
       --width=360 --timeout=5 \
       --icon-name="$ICON"
