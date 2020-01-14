#!/usr/bin/env bash
# Installs and profiles the installation of Magento 2 without Riptide, against locally running services. See README.md.

if [ "$#" -ne 7 ]; then
    echo "Usage: run_no_riptide.sh hostname-of-shop database-host database-name database-port database-user database-password redis-host"
    echo "See README.md"
    exit 1
fi

# Parameters:
HOSTNAME_OF_SHOP=$1
DATABASE_HOST=$2
DATABASE_NAME=$3
DATABASE_PORT=$4
DATABASE_USER=$5
DATABASE_PASSWORD=$6
REDIS_HOST=$7

. common.sh

rm -rf src || true
mkdir src

prf CREATE composer "create-project" "--repository=https://repo.magento.com/" "--ignore-platform-reqs" "magento/project-community-edition" "."

chmod +x bin/magento
prf INSTALL bin/magento "setup:install" \
    "--base-url=https://$HOSTNAME_OF_SHOP/" \
    "--db-host=$DATABASE_HOST" \
    "--db-port=$DATABASE_PORT" \
    "--db-name=$DATABASE_NAME" \
    "--db-user=$DATABASE_USER"  \
    "--db-password=$DATABASE_PASSWORD" \
    "--session-save=redis --session-save-redis-host=$REDIS_HOST" \
    "--admin-firstname=Admin" \
    "--admin-lastname=Admin" \
    "--admin-email=email@yourcompany.com" \
    "--admin-user=admin" \
    "--admin-password=admin123" \
    "--language=en_US" \
    "--currency=USD" \
    "--timezone=America/Chicago" \
    "--use-rewrites=1"

prf STATUS_NO_CACHE bin/magento module:status

prf SETUP_UPGRADE_FIRST bin/magento setup:upgrade

echo "------- INPUT REQUIRED -------"
echo "Will run the first curl command. Make sure the shop is accesible at https://$HOSTNAME_OF_SHOP/."
echo "Press any key to continue."
read
prf ACCESS_NO_CACHE curl "--silent" "-k" "https://$HOSTNAME_OF_SHOP/"

prf ACCESS_CACHE curl "--silent" "-k" "https://$HOSTNAME_OF_SHOP/"

prf STATUS_CACHE bin/magento module:status

prf SETUP_UPGRADE_SECOND bin/magento setup:upgrade

prf DI_COMPILE bin/magento setup:di:compile

prf STATIC_CONTENT_DEPLOY bin/magento "setup:static-content:deploy" "-f"

prf ACCESS_DI_STATIC curl "--silent" "-k" "https://$HOSTNAME_OF_SHOP/"

echo "                     "
echo "---------------------"
echo "     RESULTS         "
echo "---------------------"
echo "                     "

printf "%-25s ${CREATE}\n" CREATE
printf "%-25s n/a\n" REDIS_DB
printf "%-25s ${INSTALL}\n" INSTALL
printf "%-25s n/a\n" START_FIRST
printf "%-25s ${STATUS_NO_CACHE}\n" STATUS_NO_CACHE
printf "%-25s ${SETUP_UPGRADE_FIRST}\n" SETUP_UPGRADE_FIRST
printf "%-25s ${ACCESS_NO_CACHE}\n" ACCESS_NO_CACHE
printf "%-25s ${ACCESS_CACHE}\n" ACCESS_CACHE
printf "%-25s ${STATUS_CACHE}\n" STATUS_CACHE
printf "%-25s ${SETUP_UPGRADE_SECOND}\n" SETUP_UPGRADE_SECOND
printf "%-25s ${DI_COMPILE}\n" DI_COMPILE
printf "%-25s ${STATIC_CONTENT_DEPLOY}\n" STATIC_CONTENT_DEPLOY
printf "%-25s ${ACCESS_DI_STATIC}\n" ACCESS_DI_STATIC
printf "%-25s n/a\n" START_END
