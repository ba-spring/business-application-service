#!/bin/bash
cd ..
MVN_ARG_LINE=()

for arg in "$@"
do
    case "$arg" in
        *)
            MVN_ARG_LINE+=("$arg")
        ;;
    esac
done

startDateTime=`date +%s`

# check that Maven args are non empty
if [ "$MVN_ARG_LINE" != "" ] ; then
    mvnBin="mvn"
    if [ -a $M3_HOME/bin/mvn ] ; then
       mvnBin="$M3_HOME/bin/mvn"
    fi
    echo
    echo "Running maven build on available projects (using Maven binary '$mvnBin')"

    "$mvnBin" -v
    echo
    projects=( "*-model" "*-kjar" "business-application-service")

    for suffix in "${projects[@]}"; do

        for repository in $suffix;  do
        echo
            if [ -d "$repository" ]; then
                echo "==============================================================================="
                echo "$repository"
                echo "==============================================================================="

                cd $repository

                "$mvnBin" "${MVN_ARG_LINE[@]}"
                returnCode=$?

                if [ $returnCode != 0 ] ; then
                    exit $returnCode
                fi

                cd ..
                fi

        done;
    done;
    endDateTime=`date +%s`
    spentSeconds=`expr $endDateTime - $startDateTime`
    echo
    echo "Total build time: ${spentSeconds}s"

else
    echo "No Maven arguments skipping maven build"
        
fi


if [[ "$@" =~ "docker" ]]; then
    echo "Launching the application as docker container..."
    
    docker run -d -p 8090:8090 --name business-application-service apps/business-application-service:1.0-SNAPSHOT
elif [[ "$@" =~ "openshift" ]]; then
    echo "Launching the application on OpenShift..."
    
    oc new-app business-application-service:1.0-SNAPSHOT
    oc expose svc/business-application-service
else
	echo "Launching the application locally..."
	pattern="business-application-service"
	files=( $pattern )
	cd ${files[0]}

    cp ../business-application-kjar/target/classes/business-application-service.xml .

	executable="$(ls  *target/*.jar | tail -n1)"
	export KIESERVER_CONTROLLERS=ws://localhost:8080/business-central/websocket/controller
	#java -Dorg.kie.server.controller=${KIESERVER_CONTROLLERS} -Dorg.kie.server.startup.strategy=LocalContainersStartupStrategy -Dorg.kie.server.controller.user=donato -Dorg.kie.server.controller.pwd=donato -jar "$executable"
    java -Dorg.kie.server.startup.strategy=LocalContainersStartupStrategy -Dorg.kie.server.controller.user=donato -Dorg.kie.server.controller.pwd=donato -jar "$executable"
	#java -Dorg.kie.server.controller.user=donato org.kie.server.controller.pwd=donato -jar "$executable" 
	#java -jar "$executable"
fi
