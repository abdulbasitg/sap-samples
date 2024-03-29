#!/bin/sh

#set configuration values
NAMESPACE=default
#IMAGENAME=sapse/approuter:11.4.0
IMAGENAME=abdulbasitg/approuter-standalone:latest
SAP_CLOUD_SERVICE=approuter.standalone
PREFIX=approuter-standalone
KYMA_SYSTEM=b872255.kyma.ondemand.com

dockerbuild() {
    docker build app --tag ${IMAGENAME}
}

dockerpush() {
    docker push ${IMAGENAME}
}

dockerbp() {
    docker build app --tag ${IMAGENAME}
    docker push ${IMAGENAME}
}

shell() {
    if [ -z "$1" ]
    then
        echo "usage: run shell <pod name>"
    else    
        kubectl exec -n ${NAMESPACE} -it $1 -- /bin/sh
    fi
}

deploy() {
    IMAGENAME_ESCAPED=`echo $IMAGENAME|sed 's/\//\\\\\//g'`
    sed "s/{{IMAGE_NAME}}/${IMAGENAME_ESCAPED}/g;s/{{SAP_CLOUD_SERVICE}}/${SAP_CLOUD_SERVICE}/g;s/{{PREFIX}}/${PREFIX}/g;s/{{NAMESPACE}}/${NAMESPACE}/g;s/{{KYMA_SYSTEM}}/${KYMA_SYSTEM}/g" deployment.yaml | kubectl -n ${NAMESPACE} apply -f -    
}
deployfile() {
    IMAGENAME_ESCAPED=`echo $IMAGENAME|sed 's/\//\\\\\//g'`
    sed "s/{{IMAGE_NAME}}/${IMAGENAME_ESCAPED}/g;s/{{SAP_CLOUD_SERVICE}}/${SAP_CLOUD_SERVICE}/g;s/{{PREFIX}}/${PREFIX}/g;s/{{NAMESPACE}}/${NAMESPACE}/g;s/{{KYMA_SYSTEM}}/${KYMA_SYSTEM}/g" deployment.yaml >$1
}

delete() {
    kubectl -n ${NAMESPACE} delete deployments.v1.apps ${PREFIX}
    kubectl -n ${NAMESPACE} delete ServiceBinding ${PREFIX}-destination-binding
    kubectl -n ${NAMESPACE} delete ServiceBinding ${PREFIX}-host-binding
    kubectl -n ${NAMESPACE} delete ServiceBinding ${PREFIX}-xsuaa-binding
    kubectl -n ${NAMESPACE} delete ServiceInstance ${PREFIX}-destination-instance
    kubectl -n ${NAMESPACE} delete ServiceInstance ${PREFIX}-host-instance
    kubectl -n ${NAMESPACE} delete ServiceInstance ${PREFIX}-xsuaa-instance    
    kubectl -n ${NAMESPACE} delete Service ${PREFIX}-${NAMESPACE}
    kubectl -n ${NAMESPACE} delete ApiRule ${PREFIX}-${NAMESPACE}
    kubectl -n ${NAMESPACE} delete ApiRule fn-${PREFIX}-${NAMESPACE}
    kubectl -n ${NAMESPACE} delete Function fn-${PREFIX}-${NAMESPACE}
    kubectl -n ${NAMESPACE} delete ConfigMap destinations-${PREFIX}-${NAMESPACE}
    kubectl -n ${NAMESPACE} delete ConfigMap xs-app-${PREFIX}-${NAMESPACE}
}

reset() {
    delete
    deploy
}
if [ -z "$1" ]
then
    echo "usage: run <deploy|delete|reset|dockerbuild|dockerpush>"
else
    case $1 in
        deploy)
            deploy
            ;;
        deployfile)
            deployfile $2
            ;;
        shell)
            shell $2
            ;;
        delete)
            delete
            ;;
        reset)
            reset
            ;;
        dockerbuild)
            dockerbuild
            ;;
        dockerpush)
            dockerpush
            ;;
        dockerbp)
            dockerbp
            ;;
        *)
            echo "invalid argument. "

    esac
fi
