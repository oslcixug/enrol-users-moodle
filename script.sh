#!/bin/bash
#
# Xenera as mensaxes de benvida aos cursos en liña
#
# Uso: script.sh alumnos modelo datos arg1 ... argn
# Os argumentos son a ruta relativa aos ficheiros adxuntos da mensaxe.
#
# alumnos - username,password,firstname,lastname,email,course1,group1,enrolperiod1
# modelo - Texto para o corpo da mensaxe. Hai campos que substituir cos datos do alumno
# datos - nomeprofesor,nomecurso,urlcurso
#
# IMPORTANTE:	Debemos ter o Thunderbird pechado para que as mensaxes vaian aparecendo consecutivamente. 
#		En caso contrario, creanse todas no mesmo momento puidendo causar problemas para manexalos.
#
# Creanse tres ficheiros temporais:
# replace.tmp- cada liña contén unha substitución para o modelo base
# datos.tmp- ficheiro datos.txt coa URL modificada para poder utilizarse co comando sed
# body.tmp- ficheiro co texto final que vai no corpo da mensaxe
#

if [ $# -lt 3 ] ; then
	echo "Uso: script.sh participantes.csv modelo.txt datos.txt [arg1 ...]"
	exit 1
fi

# Pechamos calquera instancia de Thunberbird para evitar a creación das novas mensaxes de xeito simultáneo.
killall thunderbird

alumnos=$1
modelo=$2
datos=$3

shift 3

	# Creamos a cadea cos nomes dos ficheiros adxuntos
	for arg in "$@"
	do
		adxuntos=$adxuntos$(pwd)/$arg,
	done
	
	# Eliminamos a última coma da cadea
	adxuntos="${adxuntos%?}"

	# Percorremos a lista de alumnos do ficheiro pasado como argumento evitando a primeira liña
	sed 1d $alumnos | while read linea
	do
		# Debemos protexer os slash da URL do curso para poder executar o comando sed
		# evitamos a primeira liña co nome dos campos 
		sed 's#\/#\\\/#g' $datos | sed 1d - > datos.tmp

		# Xeneramos un ficheiro replace.txt con todas aquelas substitucions a facer no modelo base

		echo "s/Nomeusuario/$(echo $linea | cut -d',' -f1)/g" > replace.tmp
		echo "s/Contrasinalusuario/$(echo $linea | cut -d',' -f2)/g" >> replace.tmp
		echo "s/Nomealumno/$(echo $linea | cut -d',' -f3)/g" >> replace.tmp

		echo "s/Nomeprofesor/$(cat datos.tmp | cut -d',' -f1)/g" >> replace.tmp
		echo "s/Nomecurso/$(cat datos.tmp | cut -d',' -f2)/g" >> replace.tmp
		echo "s/URLcurso/$(cat datos.tmp | cut -d',' -f3)/g" >> replace.tmp

		# Creamos o texto personalizado para o corpo da mensaxe de benvida
		sed -f replace.tmp< $modelo > body.tmp

		# Preparamos os datos para compoñer a mensaxe en Thunderbird
		emailalumno=$(echo $linea | cut -d',' -f5)
		nomecurso=$(cat datos.tmp | cut -d',' -f2)
	
		# Creamos a nova mensaxe en Thunderbird
		thunderbird -compose "to='$emailalumno',subject='Benvida ao curso $nomecurso',body='$(cat $(pwd)/body.tmp)',attachment='$adxuntos'"

	done

rm datos.tmp replace.tmp body.tmp
