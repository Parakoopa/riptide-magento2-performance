#!/usr/bin/env bash
set -e
# Installs and profiles the installation of Magento 2 without Riptide, against locally running services. See README.md.

if [ "$#" -ne 7 ]; then
    echo "Usage: run_no_riptide.sh hostname-of-shop database-host database-name database-user database-password redis-host docker-host-ip"
    echo "See README.md"
    exit 1
fi

# Parameters:
HOSTNAME_OF_SHOP=$1
DATABASE_HOST=$2
DATABASE_NAME=$3
DATABASE_USER=$4
DATABASE_PASSWORD=$5
REDIS_HOST=$6
DOCKER_HOST_IP=$7

. common.sh

# Remove the Riptide shell integration
. riptide.hook.bash &> /dev/null
if type riptide_cwdir_hook__remove &> /dev/null; then
   riptide_cwdir_hook
   riptide_cwdir_hook__remove
fi

#sudo systemctl stop mysqld php72-fpm nginx redis

echo "We may need root rights to delete the src directory. We also need it later to set permissions:"
sudo rm -rf _riptide || true
sudo rm -rf src || true
mkdir src
cd src
prf CREATE composer "create-project" "--repository=https://repo.magento.com/" "magento/project-community-edition" "."

#sudo systemctl start mysqld redis

chmod +x bin/magento
prf INSTALL bin/magento "setup:install" \
    "--base-url=https://$HOSTNAME_OF_SHOP/" \
    "--db-host=$DATABASE_HOST" \
    "--db-name=$DATABASE_NAME" \
    "--db-user=$DATABASE_USER"  \
    "--db-password=$DATABASE_PASSWORD" \
    "--session-save=redis --session-save-redis-host=$REDIS_HOST --session-save-redis-db=2" \
    "--cache-backend=redis --cache-backend-redis-server=$REDIS_HOST --cache-backend-redis-db=0" \
    "--page-cache=redis --page-cache-redis-server=$REDIS_HOST --page-cache-redis-db=1" \
    "--backend-frontname admin" \
    "--admin-firstname=Admin" \
    "--admin-lastname=Admin" \
    "--admin-email=email@yourcompany.com" \
    "--admin-user=admin" \
    "--admin-password=admin123" \
    "--language=en_US" \
    "--currency=USD" \
    "--timezone=America/Chicago" \
    "--use-rewrites=1"

#sudo systemctl restart mysqld redis php72-fpm nginx

prf STATUS_NO_CACHE bin/magento module:status

prf SETUP_UPGRADE_FIRST bin/magento setup:upgrade

# We are not bothering with properly supporting every possible nginx/apache permission setup...
sudo chmod -R a+rwX .
echo "------- INPUT REQUIRED -------"
echo "Will run the first curl command. Make sure the shop is accesible at https://$HOSTNAME_OF_SHOP/."
echo "Press any key to continue."
read
prf ACCESS_NO_CACHE $(access_page "https://$HOSTNAME_OF_SHOP/" $DOCKER_HOST_IP $HOSTNAME_OF_SHOP)

prf ACCESS_CACHE $(access_page "https://$HOSTNAME_OF_SHOP/" $DOCKER_HOST_IP $HOSTNAME_OF_SHOP)

sudo chmod -R a+rwX .
prf STATUS_CACHE bin/magento module:status

prf SETUP_UPGRADE_SECOND bin/magento setup:upgrade

prf DI_COMPILE bin/magento setup:di:compile

prf STATIC_CONTENT_DEPLOY bin/magento "setup:static-content:deploy" "-f"

sudo chmod -R a+rwX .
prf ACCESS_DI_STATIC $(access_page "https://$HOSTNAME_OF_SHOP/" $DOCKER_HOST_IP $HOSTNAME_OF_SHOP)

sudo chmod -R a+rwX .
prf CACHE_FLUSH bin/magento cache:flush

sudo chmod -R a+rwX .
prf ACCESS_NO_CACHE_BACKEND $(access_page "https://$HOSTNAME_OF_SHOP/admin/" $DOCKER_HOST_IP $HOSTNAME_OF_SHOP)

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
printf "%-25s ${CACHE_FLUSH}\n" CACHE_FLUSH
printf "%-25s ${ACCESS_NO_CACHE_BACKEND}\n" ACCESS_NO_CACHE_BACKEND
printf "%-25s n/a\n" START_END
