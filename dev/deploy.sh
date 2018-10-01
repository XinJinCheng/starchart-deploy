#!/bin/bash
set -e

############################ Configuration #################################
WORK_DIR=$(cd "$(dirname "$0")"; pwd)
DEPLOY_ROOT=${WORK_DIR}/../
REPOS_DIR=${DEPLOY_ROOT}/repos

DOCKER_VOLUME=~/docker-volume

VOLUME_INITSQL=init-sql
VOLUME_WEBAPPS=webapps
VOLUME_HTML=html
VOLUME_CONF=conf
VOLUME_LOGS=logs
VOLUME_NGINXCONF=nginx.conf

VOLUME_DIRS="${VOLUME_INITSQL} ${VOLUME_WEBAPPS} ${VOLUME_HTML} ${VOLUME_CONF} ${VOLUME_LOGS}"

PORT_NGINX=180
PORT_TOMCAT=18080
PORT_REDIS=16379
PORT_MYSQL=13306
PORT_ADMINER=23306

ORGNIZATON_NAME=XinJinCheng

PROJECT_NAME=starchart

ADMIN_SERVICE=starchart-admin
ADMIN_UI=starchart-admin-ui

GIT_REPO_TPL=https://github.com/${ORGNIZATON_NAME}/_NAME_.git
GIT_REPOS=(${ADMIN_SERVICE} ${ADMIN_UI})

DOCKER_COMPOSE_FILE_TPL=${WORK_DIR}/docker-compose.tpl.yml
DOCKER_COMPOSE_FILE=${WORK_DIR}/docker-compose.yml


############################ Functions #################################
# function self_update(){
#     cd ${WORK_DIR}
#     echo "Check self-update ... "
#     OUT_OF_DATE=`git remote show origin |grep "out of date" |grep dev` || true
#     if [ ! -z "${OUT_OF_DATE}" ]; then
#         git pull
#         echo "Re-execute ... "
#         cd -
#         exec $0 "$@" &
#         exit 0
#     else
#         echo "No update, continue ... "
#     fi
#     cd -
# }

function git_update(){
    if [ ! -d $1 ]; then
        REPO=`echo "${GIT_REPO_TPL}" | sed "s/_NAME_/"$1"/g"`
        git clone -b dev --depth=1 ${REPO}
    fi
    cd $1
	git pull --rebase -v
	git checkout dev || true
	cd -
}

function npm_build(){
    cd ${REPOS_DIR}/$1
    npm install --registry=https://registry.npm.taobao.org --chromedriver_cdnurl=http://cdn.npm.taobao.org/dist/chromedriver
    npm run build --docker
    cd -
}

function npm_run(){
    cd ${REPOS_DIR}/$1
    npm install --registry=https://registry.npm.taobao.org --chromedriver_cdnurl=http://cdn.npm.taobao.org/dist/chromedriver
    # pm2 start npm --name "starchart-admin-ui" -- start
    npm start
    cd -
}

function mvn_build(){
    cd ${REPOS_DIR}/$1
    mvn clean package
    cd -
}

############################ Update script #################################
# self_update

############################ Check options #################################
#Auto-generated by http://getoptgenerator.dafuer.es/

# Define help function
function help(){
    echo "schoolpal-deploy - For schoolpal deploy script";
    echo "Usage example:";
    echo "schoolpal-deploy [(-h|--help)] [(-v|--docker-volume) string] [(-n|--nginx-port) integer] [(-t|--tomcat-port) integer] [(-r|--redis-port) integer] [(-m|--mysql-port) integer] [(-p|--project-name) string] [--refresh-database]";
    echo "Options:";
    echo "-h or --help: Displays this information.";
    echo "-v or --docker-volume string: Root path of docker volumes, default: ${DOCKER_VOLUME}.";
    echo "-n or --nginx-port integer: Nginx port mapping, default: ${PORT_NGINX}.";
    echo "-t or --tomcat-port integer: Tomcat port mapping, default: ${PORT_TOMCAT}.";
    echo "-r or --redis-port integer: Redis port mapping, default: ${PORT_REDIS}.";
    echo "-m or --mysql-port integer: Mysql port mapping, default: ${MYSQL}.";
    echo "-p or --project-name string: Docker-compose project name, default: ${PROJECT_NAME}.";
    exit 1;
}
 
# Execute getopt
ARGS=$(getopt -o "hv:n:t:r:m:p:" -l "help,docker-volume:,nginx-port:,tomcat-port:,redis-port:,mysql-port:,project-name:,refresh-database" -n "schoolpal-deploy" -- "$@");
 
#Bad arguments
if [ $? -ne 0 ];
then
    help;
fi
 
eval set -- "$ARGS";
 
while true; do
    case "$1" in
        -h|--help)
            shift;
            help;
            ;;
        -v|--docker-volume)
            shift;
                    if [ -n "$1" ]; 
                    then
                        DOCKER_VOLUME="$1";
                        shift;
                    fi
            ;;
        -n|--nginx-port)
            shift;
                    if [ -n "$1" ]; 
                    then
                        PORT_NGINX="$1";
                        shift;
                    fi
            ;;
        -t|--tomcat-port)
            shift;
                    if [ -n "$1" ]; 
                    then
                        PORT_TOMCAT="$1";
                        shift;
                    fi
            ;;
        -r|--redis-port)
            shift;
                    if [ -n "$1" ]; 
                    then
                        PORT_REDIS="$1";
                        shift;
                    fi
            ;;
        -m|--mysql-port)
            shift;
                    if [ -n "$1" ]; 
                    then
                        PORT_MYSQL="$1";
                        shift;
                    fi
            ;;
        -p|--project-name)
            shift;
                    if [ -n "$1" ]; 
                    then
                        PROJECT_NAME="$1";
                        shift;
                    fi
            ;;
 
        --)
            shift;
            break;
            ;;
    esac
done

############################ Main process #################################

echo -n "Create volume dirs ... "
mkdir -p ${DOCKER_VOLUME}
cd ${DOCKER_VOLUME}
for D in ${VOLUME_DIRS[*]}; do
    mkdir -p ${D}
done
echo "done"

echo "Get latest source code ... "
mkdir -p ${REPOS_DIR}
cd ${REPOS_DIR}
for R in ${GIT_REPOS[*]}; do
    echo " => ${R}"
    git_update "${R}"
done

echo "Build ${ADMIN_SERVICE} ... "
rm -rfv ${REPOS_DIR}/${ADMIN_SERVICE}/target/*
mvn_build "${ADMIN_SERVICE}"

echo "Deploy ${ADMIN_SERVICE} files ... "
rm -rfv ${DOCKER_VOLUME}/${VOLUME_WEBAPPS}/*
cp -rfv ${REPOS_DIR}/${ADMIN_SERVICE}/target/*.war ${DOCKER_VOLUME}/${VOLUME_WEBAPPS}/

# echo "Build ${ADMIN_UI} ... "
# rm -rfv ${REPOS_DIR}/${ADMIN_UI}/dist/*
# npm_build "${ADMIN_UI}"

# echo "Deploy static files ... "
# rm -rfv ${DOCKER_VOLUME}/${VOLUME_HTML}/*
# cp -rfv ${REPOS_DIR}/${ADMIN_UI}/dist/* ${DOCKER_VOLUME}/${VOLUME_HTML}/
# cp -rfv ${REPOS_DIR}/${ADMIN_UI}/target/web/static/tests ${DOCKER_VOLUME}/${VOLUME_HTML}/

echo "Deploy config files ... "
rm -rf ${DOCKER_VOLUME}/${VOLUME_INITSQL}/*.sql
cp -fv ${REPOS_DIR}/${ADMIN_SERVICE}/db/*.sql ${DOCKER_VOLUME}/${VOLUME_INITSQL}/
cp -fv ${WORK_DIR}/nginx.conf ${DOCKER_VOLUME}/${VOLUME_CONF}/${VOLUME_NGINXCONF}

echo -n "Generate docker-compose file ... "
cat ${DOCKER_COMPOSE_FILE_TPL} | \
sed 's/_PORT_NGINX_/'${PORT_NGINX}'/g' | \
sed 's/_PORT_TOMCAT_/'${PORT_TOMCAT}'/g' | \
sed 's/_PORT_REDIS_/'${PORT_REDIS}'/g' | \
sed 's/_PORT_MYSQL_/'${PORT_MYSQL}'/g' | \
sed 's/_PORT_ADMINER_/'${PORT_ADMINER}'/g' | \
sed 's/_VOLUME_HTML_/'$(echo "${DOCKER_VOLUME}/${VOLUME_HTML}" | sed 's/\//\\\//g')'/g' | \
sed 's/_VOLUME_NGINXCONF_/'$(echo "${DOCKER_VOLUME}/${VOLUME_CONF}/${VOLUME_NGINXCONF}" | sed 's/\//\\\//g')'/g' | \
sed 's/_VOLUME_WEBAPPS_/'$(echo "${DOCKER_VOLUME}/${VOLUME_WEBAPPS}" | sed 's/\//\\\//g')'/g' | \
sed 's/_VOLUME_LOGS_/'$(echo "${DOCKER_VOLUME}/${VOLUME_LOGS}" | sed 's/\//\\\//g')'/g' | \
sed 's/_VOLUME_INITSQL_/'$(echo "${DOCKER_VOLUME}/${VOLUME_INITSQL}" | sed 's/\//\\\//g')'/g' \
 > ${DOCKER_COMPOSE_FILE}
echo "done"

echo "Start docker-compose ... "
cd ${WORK_DIR}
# docker-compose pull
docker-compose -p ${PROJECT_NAME} down
docker-compose -p ${PROJECT_NAME} up -d

echo "Run ${ADMIN_UI} ... "
npm_run "${ADMIN_UI}"
