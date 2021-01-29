octocatalog-diff CI
Compile catálogos de Puppet de 2 ramas, versiones, etc., y compárelos
octocatalog-diffes una herramienta que permite a los desarrolladores ser más eficientes al probar cambios en los manifiestos de Puppet. Se usa más comúnmente para mostrar diferencias en los catálogos de Puppet entre las ramas estables y de desarrollo. No requiere un Puppet master (o puppetserver) en funcionamiento, por lo que a menudo los desarrolladores lo ejecutan en sus estaciones de trabajo y en entornos de integración continua.

En GitHub, administramos miles de nodos con una base de código Puppet que contiene más de 500,000 líneas de código de más de 200 colaboradores. Ejecutamos octocatalog-diffmiles de veces al día como parte de las pruebas de integración continua, y los desarrolladores lo ejecutan en sus estaciones de trabajo mientras trabajan con el código.

octocatalog-diffestá escrito en Ruby y se distribuye como una joya. Se ejecuta en plataformas Mac OS y Unix / Linux.

Consideramos que la versión 1.x de octocatalog-diffes estable y con calidad de producción. Continuamos manteniendo y mejorando octocatalog-diffpara satisfacer las necesidades internas de GitHub e incorporar sugerencias de la comunidad. Consulte el registro de cambios para obtener más detalles.

Si ha estado usando la versión 0.6.1 o anterior, lea acerca de las novedades de octocatalog-diff 1.0 para obtener un resumen de las nuevas capacidades y los cambios importantes.

¿Cómo?
El desarrollo tradicional de la marioneta generalmente toma una de dos formas. Con frecuencia, los desarrolladores probarán los cambios ejecutando un agente Puppet (quizás en --noopmodo) para ver si el cambio deseado ha resultado en un sistema real. Otros usarán metodologías de prueba formales, como rspec-puppeto el marco de vaso para validar el código de Puppet.

octocatalog-diffusa un patrón diferente. En su invocación más común, compila catálogos Puppet tanto para la rama estable (por ejemplo, master) como para la rama de desarrollo, y luego los compara. Filtra los atributos o recursos que no tienen ningún efecto sobre el estado final del sistema de destino (por ejemplo, etiquetas) y muestra las diferencias restantes. Con esta estrategia, se pueden obtener comentarios sobre los cambios sin implementar el código Puppet en un servidor y realizar una ejecución completa de Puppet, y esta herramienta funciona incluso si la cobertura de la prueba es incompleta.

Existen algunas limitaciones para un enfoque basado en catálogo, lo que significa que nunca reemplazará por completo las pruebas de unidad, integración o implementación. Sin embargo, proporciona ahorros de tiempo sustanciales tanto en el ciclo de desarrollo como en el de prueba. En este repositorio, proporcionamos scripts de ejemplo para usar octocatalog-diffen entornos de desarrollo y CI.

octocatalog-diff actualmente puede obtener catálogos mediante los siguientes métodos:

Compile el catálogo a través de la línea de comandos con un agente Puppet en su máquina (ya que GitHub usa la herramienta internamente)
Obtenga el catálogo a través de la red de PuppetDB
Obtenga un catálogo a través de la red utilizando la API para consultar un Puppet Master / PuppetServer (se admiten Puppet 3.x a 6.x)
Leer el catálogo de un archivo JSON
Ejemplo
Aquí se muestra la salida simulada de la ejecución octocatalog-diffpara comparar los cambios del catálogo Puppet entre la rama maestra y el código Puppet en el directorio de trabajo actual:

[captura de pantalla de octocatalog-diff]

El ejemplo anterior refleja los cambios en el catálogo Puppet al cambiar un dispositivo subyacente por un sistema de archivos montado.

Documentación
Instalación y uso en un entorno de desarrollo
Instalación
Configuración
Uso básico de la línea de comandos
Uso avanzado de la línea de comandos
Solución de problemas
Instalación y uso de CI
Configuración de octocatalog-diff en CI
Detalles técnicos
Requisitos
Limitaciones
Lista de todas las opciones de la línea de comandos
Variables de entorno
Proyecto
Mapa vial
Herramientas similares
Contribuyendo
Documentación para desarrolladores
Documentación API
¿Lo que hay en un nombre?
Durante su desarrollo original en GitHub, esta herramienta simplemente se llamó catalog-diff. Sin embargo, ya existe un módulo Puppet con ese nombre y no queríamos crear ninguna confusión (de hecho, se podría argumentar el uso de ambos enfoques). Entonces, nombramos la herramienta octocatalog-diffporque ¿a quién no le gusta el octocat ? Entonces, un día en el chat, alguien se refirió a la herramienta como " : octocat:alog-diff", y ese apodo se hizo popular para la comunicación electrónica.

Contribuyendo
¡Consulte nuestro documento de contribución si desea participar!

Obteniendo ayuda
Si tiene un problema o sugerencia, abra un problema en este repositorio y haremos todo lo posible para ayudarlo. Tenga en cuenta que este proyecto se adhiere al Código Abierto de Conducta .

Licencia
octocatalog-difftiene licencia de MIT .

Requiere gemas de rubí de terceros que se encuentran aquí . También incluye partes de otros proyectos de código abierto aquí , aquí , aquí y aquí . Todo el código de terceros y las gemas requeridas tienen licencia como MIT o Apache 2.0.

Autores / Propietarios
octocatalog-difffue diseñado y escrito originalmente por Kevin Paulisse . Ahora lo mantiene el equipo de Ingeniería de confiabilidad del sitio en GitHub.
