#!/bin/bash
#Inicializo script bash.

# Modo de uso:
# ./munin-iops-x-vmstores-emc.sh path_to_directory output

# 1º parte:
# Incluir el directorio donde se encuentran las definiciones de las maquinas virtuales.

#Verifica que el usuario haya ingresado correctamente los parametros de entrada.
#Asigna a variable salida el primer parametro introducido que posee el nombre de archivo de salida. En caso de no existir se crea.
#Si el usuario no ingreso correctamente el modo de uso se  notifica error por pantalla.
if [ $1 ]; then
        salida=$1
else
        echo "******************************************************************************"
        echo "[ERROR] Ingrese correctamente el nombre del directorio o del archivo de salida"
        echo "******************************************************************************"
        exit 1
fi

#Crea un directorio temporal directory.
directory=$(mktemp -d)
#Ingresa al mismo 
cd $directory
#Realiza copia del repositorio que posee las definiciones de maquinas virtuales, utilizando comando check-out de subversion.
svn co http://noc-svn.psi.unc.edu.ar/servicios/xen

# Elimina directorios innecesarios
rm -rf $directory/xen/suspendidos $directory/xen/.svn $directory/xen/old $directory/xen/error $directory/xen/templates

#Crea archivos de texto a utilizar.
> result.txt
> result1.txt
> vm.txt
> escrituras_a.txt
> lecturas_a.txt
> escrituras_b.txt
> lecturas_b.txt
> escrituras_c.txt
> lecturas_c.txt
> escrituras_d.txt
> lecturas_d.txt
> escrituras_e.txt
> lecturas_e.txt
> escrituras_f.txt
> lecturas_f.txt
> escrituras_g.txt
> lecturas_g.txt
> escrituras_h.txt
> lecturas_h.txt
> escrituras_i.txt
> lecturas_i.txt
> escrituras_j.txt
> lecturas_j.txt
> escrituras_k.txt
> lecturas_k.txt
> escrituras_l.txt
> lecturas_l.txt
> escrituras_m.txt
> lecturas_m.txt
> total.txt

#Para cada archivo del directorio directory lee linea por linea y hace un echo de cada linea en un archivo vm.txt
for file in $directory/xen/*; do
        while read -r line; do
        echo "$line" >> vm.txt
        done < $file

#Realiza busqueda de las lineas de vm.txt que contengan dev o vmstore. Y de estas, que no contengan rogelio|device....
#Las lineas obtenidas las guarda en el archivo parser.txt
	egrep "dev|vmstore" vm.txt | egrep -v "rogelio|device|args|description|\(name|phy:" > parser.txt
	i=$(cat parser.txt | wc -l)

#Lee linea por linea con el comando sed el archivo parser.txt. Define variables c y d para lectura de una linea y linea siguiente.
#Las dos lineas conscecutivas se guardan en lineaN0 y lineaN1
	for (( c=1; c<=i; c++ ))
        do
           lineaN0=$(sed -n -e ${c}p parser.txt)
           (( d=c+1 ))
           lineaN1=$(sed -n -e ${d}p parser.txt)

#Filtramos solo lineas conscecutivas que posean informacion del disco y nombre de maquinas virtuales
#De esta forma verificamos que no sean dos lineas iguales. Por ejemplo dos lineas seguidas con informacion de discos diferentes.
#Realizamos la comparacion cortando los primeros 5 caracteres y comparandolos. Tambien tenemos en cuenta si la linea siguiente es nula.
           if [[ "$(echo $lineaN0 | cut -c1-5)" = "$(echo $lineaN1 | cut -c1-5)" ||  -z "$lineaN1" ]]; then
                echo "Se repiten o lineaN1 es NULL" > /dev/null
 
#Si las lineas son distintas se procede a obtener los parametros solicitados. Para ello se emplea el comando sed de la siguiente manera:
#borra -(dev -		: s/(dev //g
#borra parentisis	: s/(//g ;s/)//g
#borra -:disk - 	: s/\:disk //g; 
#borra uname file:/srv/xen/ : s/uname//g;s/file\:\/srv\/xen\///g
#reemplaza / por espacio en blanco : s/\// /g
#elimina espacios en blanco dobles : s/  / /g

#Realiza un echo con nombre del archivo linea, disco y nombre de maquina virtual al archivo result.txt
           else
                echo $lineaN0 $lineaN1 | sed 's/(dev //g;s/(//g;s/)//g;s/\:disk//g;s/uname//g;s/file\:\/srv\/xen\///g;s/)//g;s/\// /g;s/  / /g' >> result1.txt
                (( c=c+1 ))
           fi
        done
> vm.txt
done

#Borro las lineas que contengan las vm anc-aromo-2 y srv-ubuntu14-dev
sed '/anc-aromo-2/d;/srv-ubuntu14-dev/d' result1.txt >> result.txt

# 2º Parte
# Definir el formato de los distintos tipos de graficos

#Lee linea por linea el archivo result.txt
while read -r line; do

#Corta la linea por campos
#Asigna primer campo con el disco a la variable disk
#el segundo y cuarto a la variable res, que contiene nombre de vm y disco, colocando un _ entre medio, y el tercer campo a vm 
        vm=$(echo $line | cut -f3 -d' ')
        disk=$(echo $line | cut -f1 -d' ')
	res=$(echo $line | cut -f2-4 -d' ' | sed 's/ /_/g')
	vmm=$(echo $line | cut -f2 -d' ')
#Busca en el archivo de configuracion munin la ruta de ubicacion de la vm
#Toma una linea y corta todo lo anterior al caracter [ y elimina el caracter ] al final
	pline=$(echo $(egrep "\;$vm\.unc\.edu\.ar\]$|\;$vm\.psi\.unc\.edu\.ar\]$|\;$vm\]$" /etc/munin/munin.conf | head -n1 | sed 's/^.*\[//g;s/\]//g'))
        if [[ -z $pline ]]; then
                echo $pline > /dev/null
#Verifica que pline no sea nula, de otra forma conforma los archivos con lecturas, escrituras, total, de forma que munin los entienda para graficar
#Separo vmstores a,b,c,etc y se guardan en sus correspondientes archivos de lecturas y escrituras
        else
		if [ "$vmm" = "vmstore-a" ]
		then
	                echo "$pline:diskstats_iops.$disk.wrio" >> escrituras_a.txt   #Escrituras
                	echo "$pline:diskstats_iops.$disk.rdio" >> lecturas_a.txt 	#Lecturas
	        fi
		if [ "$vmm" = "vmstore-b" ]
		then
	                echo "$pline:diskstats_iops.$disk.wrio" >> escrituras_b.txt
                	echo "$pline:diskstats_iops.$disk.rdio" >> lecturas_b.txt
	        fi
		if [ "$vmm" = "vmstore-c" ]
		then
	                echo "$pline:diskstats_iops.$disk.wrio" >> escrituras_c.txt
                	echo "$pline:diskstats_iops.$disk.rdio" >> lecturas_c.txt
	        fi
		if [ "$vmm" = "vmstore-d" ]
		then
	                echo "$pline:diskstats_iops.$disk.wrio" >> escrituras_d.txt
                	echo "$pline:diskstats_iops.$disk.rdio" >> lecturas_d.txt
	        fi
		if [ "$vmm" = "vmstore-e" ]
		then
	                echo "$pline:diskstats_iops.$disk.wrio" >> escrituras_e.txt
                	echo "$pline:diskstats_iops.$disk.rdio" >> lecturas_e.txt
	        fi
		if [ "$vmm" = "vmstore-f" ]
		then
	                echo "$pline:diskstats_iops.$disk.wrio" >> escrituras_f.txt
                	echo "$pline:diskstats_iops.$disk.rdio" >> lecturas_f.txt
	        fi
		if [ "$vmm" = "vmstore-g" ]
		then
	                echo "$pline:diskstats_iops.$disk.wrio" >> escrituras_g.txt
                	echo "$pline:diskstats_iops.$disk.rdio" >> lecturas_g.txt
	        fi
		if [ "$vmm" = "vmstore-h" ]
		then
	                echo "$pline:diskstats_iops.$disk.wrio" >> escrituras_h.txt
                	echo "$pline:diskstats_iops.$disk.rdio" >> lecturas_h.txt
	        fi
		if [ "$vmm" = "vmstore-i" ]
		then
	                echo "$pline:diskstats_iops.$disk.wrio" >> escrituras_i.txt
                	echo "$pline:diskstats_iops.$disk.rdio" >> lecturas_i.txt
	        fi
		if [ "$vmm" = "vmstore-j" ]
		then
	                echo "$pline:diskstats_iops.$disk.wrio" >> escrituras_j.txt
                	echo "$pline:diskstats_iops.$disk.rdio" >> lecturas_j.txt
	        fi
		if [ "$vmm" = "vmstore-k" ]
		then
	                echo "$pline:diskstats_iops.$disk.wrio" >> escrituras_k.txt
                	echo "$pline:diskstats_iops.$disk.rdio" >> lecturas_k.txt
	        fi
		if [ "$vmm" = "vmstore-l" ]
		then
	                echo "$pline:diskstats_iops.$disk.wrio" >> escrituras_l.txt
                	echo "$pline:diskstats_iops.$disk.rdio" >> lecturas_l.txt
	        fi
		if [ "$vmm" = "vmstore-m" ]
		then
	                echo "$pline:diskstats_iops.$disk.wrio" >> escrituras_m.txt
                	echo "$pline:diskstats_iops.$disk.rdio" >> lecturas_m.txt
	        fi
	fi
done < result.txt

# 3º parte
# Completar la estructura del archivo emc 
# Borra contenido de la variable salida
> $salida

#Inicializa archivo salida con configuraciones de etiqueta y demas, propias de Munin
echo "[UNC;PSI;NOC;Infraestructura;Storage;EMC-x-vmstores]"	        >> $salida
echo "    update no"                                                    >> $salida
echo "    diskstats_iops.update no"                                     >> $salida
echo "    diskstats_iops.graph_title IOPS Lecturas por vmstores"        >> $salida
echo "    diskstats_iops.graph_category IOPS"                           >> $salida
echo "    diskstats_iops.graph_args --base 1000"                        >> $salida
echo "    diskstats_iops.graph_vlabel IOs/sec"                          >> $salida
echo "    diskstats_iops.vm_a.label vmstores_a"		                >> $salida
echo "    diskstats_iops.vm_b.label vmstores_b"		                >> $salida
echo "    diskstats_iops.vm_c.label vmstores_c"		                >> $salida
echo "    diskstats_iops.vm_d.label vmstores_d"		                >> $salida
echo "    diskstats_iops.vm_e.label vmstores_e"		                >> $salida
echo "    diskstats_iops.vm_f.label vmstores_f"		                >> $salida
echo "    diskstats_iops.vm_g.label vmstores_g"		                >> $salida
echo "    diskstats_iops.vm_h.label vmstores_h"		                >> $salida
echo "    diskstats_iops.vm_i.label vmstores_i"		                >> $salida
echo "    diskstats_iops.vm_j.label vmstores_j"		                >> $salida
echo "    diskstats_iops.vm_k.label vmstores_k"		                >> $salida
echo "    diskstats_iops.vm_l.label vmstores_l"		                >> $salida
echo "    diskstats_iops.vm_m.label vmstores_m"		                >> $salida
echo "    diskstats_iops.graph_order vm_a vm_b vm_c vm_d vm_e vm_f vm_g vm_h vm_i vm_j vm_k vm_l vm_m"       >> $salida
echo "    	diskstats_iops.vm_a.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < lecturas_a.txt
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm b..................................................................
echo "    	diskstats_iops.vm_b.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < lecturas_b.txt
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm c..................................................................
echo "    	diskstats_iops.vm_c.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < lecturas_c.txt
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm d..................................................................
echo "    	diskstats_iops.vm_d.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < lecturas_d.txt
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm e..................................................................
echo "    	diskstats_iops.vm_e.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < lecturas_e.txt
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm f..................................................................
echo "    	diskstats_iops.vm_f.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < lecturas_f.txt
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm g..................................................................
echo "    	diskstats_iops.vm_g.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < lecturas_g.txt
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm h..................................................................
echo "    	diskstats_iops.vm_h.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < lecturas_h.txt
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm i..................................................................
echo "    	diskstats_iops.vm_i.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < lecturas_i.txt
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm j..................................................................
echo "    	diskstats_iops.vm_j.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < lecturas_j.txt
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm k..................................................................
echo "    	diskstats_iops.vm_k.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < lecturas_k.txt
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm l..................................................................
echo "    	diskstats_iops.vm_l.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < lecturas_l.txt
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm m..................................................................
echo "    	diskstats_iops.vm_m.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < lecturas_m.txt
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#.........................ESCRITURAS...............................................
echo " "                                                                >> $salida
echo "    diskstats_iops_1.update no"                                   >> $salida
echo "    diskstats_iops_1.graph_title IOPS Escrituras por vmstores"    >> $salida
echo "    diskstats_iops_1.graph_category IOPS"                         >> $salida
echo "    diskstats_iops_1.graph_args --base 1000"                      >> $salida
echo "    diskstats_iops_1.graph_vlabel IOs/sec"                        >> $salida
echo "    diskstats_iops_1.vma.label vmstores_a"  	                >> $salida
echo "    diskstats_iops_1.vmb.label vmstores_b"  	                >> $salida
echo "    diskstats_iops_1.vmc.label vmstores_c"  	                >> $salida
echo "    diskstats_iops_1.vmd.label vmstores_d"  	                >> $salida
echo "    diskstats_iops_1.vme.label vmstores_e"  	                >> $salida
echo "    diskstats_iops_1.vmf.label vmstores_f"  	                >> $salida
echo "    diskstats_iops_1.vmg.label vmstores_g"  	                >> $salida
echo "    diskstats_iops_1.vmh.label vmstores_h"  	                >> $salida
echo "    diskstats_iops_1.vmi.label vmstores_i"  	                >> $salida
echo "    diskstats_iops_1.vmj.label vmstores_j"  	                >> $salida
echo "    diskstats_iops_1.vmk.label vmstores_k"  	                >> $salida
echo "    diskstats_iops_1.vml.label vmstores_l"  	                >> $salida
echo "    diskstats_iops_1.vmm.label vmstores_m"  	                >> $salida
echo "    diskstats_iops_1.graph_order vma vmb vmc vmd vme vmf vmg vmh vmi vmj vmk vml vmm"       >> $salida
echo "    	diskstats_iops_1.vma.sum \\"          	 		>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < escrituras_a.txt 
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm b..................................................................
echo "    	diskstats_iops_1.vmb.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < escrituras_b.txt 
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm c..................................................................
echo "    	diskstats_iops_1.vmc.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < escrituras_c.txt 
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm d..................................................................
echo "    	diskstats_iops_1.vmd.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < escrituras_d.txt 
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm e..................................................................
echo "    	diskstats_iops_1.vme.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < escrituras_e.txt 
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm f..................................................................
echo "    	diskstats_iops_1.vmf.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < escrituras_f.txt 
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm g..................................................................
echo "    	diskstats_iops_1.vmg.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < escrituras_g.txt 
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm h..................................................................
echo "    	diskstats_iops_1.vmh.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < escrituras_h.txt 
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm i..................................................................
echo "    	diskstats_iops_1.vmi.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < escrituras_i.txt 
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm j..................................................................
echo "    	diskstats_iops_1.vmj.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < escrituras_j.txt 
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm k..................................................................
echo "    	diskstats_iops_1.vmk.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < escrituras_k.txt 
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm l.................................................................
echo "    	diskstats_iops_1.vml.sum \\"           			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < escrituras_l.txt 
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida

#............vm m..................................................................
echo "    	diskstats_iops_1.vmm.sum \\"          			>> $salida
while read -r line; do
        echo "          $line \\"                                       >> $salida
done < escrituras_m.txt 
        line=$(tail -n1 $salida | sed 's/\\//g')
        sed '$ d' $salida                                               >  temp.txt
        cat temp.txt                                                    >  $salida
        echo "$line"                                                    >> $salida


#Movemos salida al directorio de munin
mv $salida /etc/munin/munin-conf.d/$salida
#Borramos archivos temporales
rm -rf $directory 
