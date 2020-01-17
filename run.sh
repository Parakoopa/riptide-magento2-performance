#!/usr/bin/env bash
set -e
# Installs and profiles the installation of Magento 2 with Riptide. See README.md.
if [ "$#" -ne 2 ]; then
    echo "Usage: run.sh riptide-base-url docker-host-ip"
    echo "See README.md"
    exit 1
fi

# Parameters:
RIPTIDE_BASE_URL=$1
DOCKER_HOST_IP=$2

. common.sh


echo "We need root rights to delete the src/_riptide directory:"
sudo rm -rf _riptide || true
# Remove the named volume if this Riptide performance setting is enabled (see https://github.com/Parakoopa/riptide-db-mysql/commit/790232a6acd3749b4d32ddec17c116a48a8cef26):
docker volume rm -f riptide__profiling-m2__db_mysql__default &> /dev/null || true
riptide setup --skip &> /dev/null || true
sudo rm -rf src || true

mkdir src
riptide stop

prf CREATE riptide cmd composer "create-project" "--repository=https://repo.magento.com/" "--ignore-platform-reqs" "magento/project-community-edition" "."

prf REDIS_DB riptide start -s redis,db

sleep 30  # Wait for DB - TODO: This should propably also be profiled somehow

prf INSTALL riptide cmd magento "setup:install" \
    "--base-url=https://profiling-m2.$RIPTIDE_BASE_URL/" \
    "--db-host=db" \
    "--db-name=magento2" \
    "--db-user=root"  \
    "--db-password=magento2" \
    "--admin-firstname=Admin" \
    "--admin-lastname=Admin" \
    "--admin-email=email@yourcompany.com" \
    "--admin-user=admin" \
    "--admin-password=admin123" \
    "--language=en_US" \
    "--currency=USD" \
    "--timezone=America/Chicago" \
    "--use-rewrites=1"

prf START_FIRST riptide restart

prf STATUS_NO_CACHE riptide cmd magento module:status

prf SETUP_UPGRADE_FIRST riptide cmd magento setup:upgrade

prf ACCESS_NO_CACHE $(access_page "https://profiling-m2.$RIPTIDE_BASE_URL/" $DOCKER_HOST_IP "profiling-m2.$RIPTIDE_BASE_URL")

prf ACCESS_CACHE $(access_page "https://profiling-m2.$RIPTIDE_BASE_URL/" $DOCKER_HOST_IP "profiling-m2.$RIPTIDE_BASE_URL")

prf STATUS_CACHE riptide cmd magento module:status

prf SETUP_UPGRADE_SECOND riptide cmd magento setup:upgrade

prf DI_COMPILE riptide cmd magento setup:di:compile

prf STATIC_CONTENT_DEPLOY riptide cmd magento "setup:static-content:deploy" "-f"

prf ACCESS_DI_STATIC $(access_page "https://profiling-m2.{$RIPTIDE_BASE_URL}/" $DOCKER_HOST_IP "profiling-m2.$RIPTIDE_BASE_URL")

prf CACHE_FLUSH riptide cmd magento cache:flush

prf ACCESS_NO_CACHE_BACKEND $(access_page "https://profiling-m2.{$RIPTIDE_BASE_URL}/admin" $DOCKER_HOST_IP "profiling-m2.$RIPTIDE_BASE_URL")

prf START_END riptide restart

riptide stop

echo "                     "
echo "---------------------"
echo "     RESULTS         "
echo "---------------------"
echo "                     "

printf "%-25s ${CREATE}\n" CREATE
printf "%-25s ${REDIS_DB}\n" REDIS_DB
printf "%-25s ${INSTALL}\n" INSTALL
printf "%-25s ${START_FIRST}\n" START_FIRST
printf "%-25s ${STATUS_NO_CACHE}\n" STATUS_NO_CACHE
printf "%-25s ${SETUP_UPGRADE_FIRST}\n" SETUP_UPGRADE_FIRST
printf "%-25s ${ACCESS_NO_CACHE}\n" ACCESS_NO_CACHE
printf "%-25s ${ACCESS_CACHE}\n" ACCESS_CACHE
printf "%-25s ${STATUS_CACHE}\n" STATUS_CACHE
printf "%-25s ${SETUP_UPGRADE_SECOND}\n" SETUP_UPGRADE_SECOND
printf "%-25s ${DI_COMPILE}\n" DI_COMPILE
printf "%-25s ${STATIC_CONTENT_DEPLOY}\n" STATIC_CONTENT_DEPLOY
printf "%-25s ${ACCESS_DI_STATIC}\n" ACCESS_DI_STATIC
printf "%-25s ${CACHE_FLUSH}\n" CACHE_FLUSH
printf "%-25s ${ACCESS_NO_CACHE_BACKEND}\n" ACCESS_NO_CACHE_BACKEND
printf "%-25s ${START_END}\n" START_END
