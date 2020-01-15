Magento 2 Riptide Performance Profiling
=======================================

This repository meassures the time that common tasks during the Magento 2 workflow take:

Script
------
Run the script ``run.sh riptide-proxy-url`` on MacOS/Linux to get the performance results. The script will output timings for the tasks at the very end.
``riptide-proxy-url`` is the base URL of the Riptide proxy.

Run ``run_no_riptide.sh hostname-of-shop database-host database-name database-port database-user database-password redis-host varnish-host`` to install and run the tests against a local PHP & Nginx/Apache
setup without Riptide. The database that will be tested against must exist and be empty.
Configure your local web-server to serve Magento from the ``src`` directory in this project. This "no Riptide" script will pause and wait for input, before trying to access the shop via HTTP for the first time, so you can make sure your setup is correct. This does not use Varnish.

The scripts have to be run from this directory.

Dependencies
------------
Riptide must be installed for ``run.sh``. 

Additionally GNU ``time`` needs to be installed. 
Under MacOS install it via ``brew install gnu-time``. 
Under Arch run ``pacman -Sy time``.
The builtin Bash/Zsh ``time`` commands will NOT work. 

Docker is required for both scripts. Also the URL of the Riptide Proxy and/or the local web-server must be resolvable
with DNS (Hosts entries are not enough).

Tasks
-----
The script runs and profiles tasks in this order:

- (Remove the src directory)
- CREATE - Create Magento Composer Project in src
- REDIS_DB - Start Redis and Database for the first time
- INSTALL - Install Magento (magento setup:install)
- START_FIRST - Restart the whole application
- STATUS_NO_CACHE - Run magento module:status with no caches
- SETUP_UPGRADE_FIRST - Run setup:upgrade
- ACCESS_NO_CACHE - Access the shop for the first time, with all caches invalidated
- ACCESS_CACHE - Access the shop with caches
- STATUS_CACHE - Run magento module:status with caches
- SETUP_UPGRADE_SECOND - Run setup:upgrade again
- DI_COMPILE - Run setup:di:compile
- STATIC_CONTENT_DEPLOY - Run setup:static-content:deploy
- ACCESS_DI_STATIC - Access the shop again with di and static-content deployed
- CACHE_FLUSH - Run cache:flush
- ACCESS_NO_CACHE_BACKEND - Access the shop backend with no cache
- START_END - Restart the whole application again
- (Stop the application)

Tasks that are not applicable to non-Riptide setups are skipped in, when using the ``run_no_riptide.sh`` (REDIS-DB, START-FIRST, START-END).
