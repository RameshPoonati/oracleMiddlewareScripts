#!/bin/bash
export HOME_DIR=/home/aenv
source $HOME_DIR/scripts/env.env
export SCRIPT_HOME=$HOME_DIR/scripts/ReferenceInstances
export CLASSPATH=$CLASSPATH:/app_base/env/product/fmw/OH_AIA1/Infrastructure/LifeCycle/AIAHarvester/Harvester/lib/jrf-api-11.1.1.7.jar
source $WL_HOME/server/bin/setWLSEnv.sh
source /app_base/env/product/fmw/OH_AIA1/aia_instances/env_AIA/bin/aiaenv.sh
timestamp=$(date +%Y-%m-%d-%H-%M)
java weblogic.WLST $SCRIPT_HOME/referenceInstances.py
