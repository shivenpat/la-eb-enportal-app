#######################################################################################################################
#Automated deploy script for webapp, jobapp, ETL, Rules. Can also deploy multiple applications in a single environment
#Takes app.properties from each environment folder as input for applications
#Developer: Krishna Vallala
#Last modified date: 8/09/2018
#Version: 05 (MaxE-ATS)
#######################################################################################################################

#!/bin/bash


ENV1=$1;  ## Eg:ENV1=MAXE2-DEV


. ~/env/${ENV1}.env;
dt=$(date +%Y%m%d_%H%M)

if [ $# -ne 1 ];then
  echo -e "\n >> USAGE: $0 ENVFILE-NAME \n"
  echo -e " >> Eg: $0 MAXE2-DEV \n"
  exit 1;
fi


#Custom Variables
jenkinsPath=${ENV_HOME}/deploy;
configPath=${ENV_HOME}/custom_conf/app_config;
appPath=${ENV_HOME}/webapps;
cacheDir=${ORACLE_HOME}/work/Catalina/localhost;

#ATS application specific variables (will make it generic eventually)
etlRootDir=ETL_Repository;rulesRootDir=RulesRepository;
etlDir=aps-etl-product;rulesDir=apptracking;
etlJar=aps-etl.jar;rulesJar=aps-rules.jar;



#Reads app.properties file for app names
prop=${jenkinsPath}/app.properties;
if [ -f $prop ];then
  echo -e " >> Found app.properties in $PWD, proceeding with applications deployment \n";
  dos2unix ${prop} ${prop};

  #Count lines in the file
  num=1;
  end=$(sed -n '$=' $prop);

  #Count lines that start with ^APP
  appNumBegin=0;
  appNumend=$(sed -n 's/^APP\([^ ]*\)/\1/p' ${jenkinsPath}/app.properties | wc -l);
  #echo -e "appNumend --> $appNumend"


  #Iterate until num==end
  while [ $num -le $end ]
  do
        #print the line item
        line=$(awk 'NR=='$num'' $prop) 
        (( num++ ))


        

        if [[ $line = "APP"* ]];then

             #Count lines that start with ^APP
             (( appNumBegin++ ))
              #echo -e "appNumBegin --> $appNumBegin"


              #prints string after equals sign and before semi colon 
              apps=$(echo $line | cut -d'=' -f2 | sed -n 's/\([^ ]*\);/\1/p');
              #echo $apps;

               
              ## BEGIN OF FUNCTIONS 
              ## STOPPING OR STARTING APACHE AND TOMCAT SERVICES
              stopstartService() {
              if [ -d ${ORACLE_HOME} ] && [ "$1" == "stop" ];then
                    echo -e "\n >> Now stopping Apache and Tomcat Services... \n"
                    cd ${ORACLE_HOME}/bin;
                    ./stopservices ${ENV1};
                    sleep 30;
              elif [ -d ${ORACLE_HOME} ] && [ "$1" == "start" ];then
                    echo -e "\n#########   APPLICATION DEPLOYMENTS ARE COMPLETE NOW   #########";
                    echo -e "\n >> Now starting Apache and  Tomcat Services... \n";
                    cd ${ORACLE_HOME}/bin;
                    ./startservices;
                    sleep 30;
              else
                    echo -e "\n >> ${ORACLE_HOME} does not exist, please check your ${ENV1}.env file \n"
                    exit 1;
              fi
              }


              ## BACKUP DEPLOY ETL AND RULES REPOSITORY
              backupETLRules() {
              echo -e "\n >> Backing up ${etlRootDir}/${etlDir} and ${rulesRootDir}/${rulesDir} ...\n"
              cd ${configPath};
              if [ -d ${etlRootDir} ] && [ -d ${rulesRootDir} ];then
                    cd ${configPath}/${etlRootDir};rm -rf *tgz*;mkdir -p ${etlDir};tar -czf ${etlDir}.$dt.tgz ${etlDir};
                    cd ${configPath}/${rulesRootDir};rm -rf *tgz*;mkdir -p ${rulesDir};tar -czf ${rulesDir}.$dt.tgz ${rulesDir};
                    if [ -f ${configPath}/${etlRootDir}/${etlDir}.$dt.tgz ] && [ -f ${configPath}/${rulesRootDir}/${rulesDir}.$dt.tgz ];then
                       echo -e "\n >> ${etlDir}.$dt.tgz and  ${rulesDir}.$dt.tgz were created under ${configPath}, proceeding with ETL and Rules deployment \n";
                    else
                       echo -e "\n >> ${etlDir}.$dt.tgz and  ${rulesDir}.$dt.tgz were not created under ${configPath}, please check \n"
                       exit 1;
                    fi
              else
                    echo -e "\n >> ${etlRootDir} and ${rulesRootDir} not available under ${configPath}, please check \n";
                    exit 1;
              fi
              }



              ## DEPLOY ETL AND RULES REPOSITORY
              deployETLRules() {
              echo -e "\n >> Deploying ${etlRootDir} and ${rulesRootDir} ...\n"
              cd ${configPath};
              if [ -f ${jenkinsPath}/${etlJar} ] && [ -f ${jenkinsPath}/${rulesJar} ];then
                   rm -rf ${etlRootDir}/${etlDir} ${rulesRootDir}/${rulesDir};
                   cd ${configPath}/${etlRootDir};${JAVA_HOME}/bin/jar -xf ${jenkinsPath}/${etlJar};
                   cd ${configPath}/${rulesRootDir};${JAVA_HOME}/bin/jar -xf ${jenkinsPath}/${rulesJar};
                   echo -e "\n >> ${etlRootDir}/${etlDir} and  ${rulesRootDir}/${rulesDir} were deployed successfully under ${configPath} \n";
                   ls -lrt ${configPath}/${etlRootDir};ls -lrt ${configPath}/${rulesRootDir};
              else
                   echo -e "\n >> ${etlJar}(ETL) and ${rulesJar}(Rules) not available under ${jenkinsPath}, please check \n";
                   exit 1;
              fi
              }


              ## UNDEPLOY CURRENT WEB WAR FILE
              undeployApp() {
              cd ${appPath};
              if [ -f ${warModule} ];then
                 if [ -f ${webWar} ];then
                     echo -e "\n >> Backing up current ${ENV3} as ${ENV3}.OLD \n";
                     mv ${ENV3} ${ENV3}.OLD;
                     chmod 775 ${ENV3}.OLD;
                     sleep 10;
                  else
                     echo -e "\n >> ${webWar} is not available, proceeding with deletion of webapp...\n"
                  fi
              else
                  echo -e "\n >> ${warModule} not available, skipping 'undeployment' of ${ENV3} \n"
              fi
              }



              ## DELETE WEBAPP, IF IT STILL EXISTS
              deleteApp() {
              cd ${appPath};
              if [ -f ${warModule} ];then
                 if [ -d "${ENV4}" ];then
                     echo -e "\n >> Deleting ${ENV4} app from ${appPath} now ...\n"
                     rm -rf ${webApp};
                     echo -e "\n >> Deleted ${webApp} successfully \n";
                 else
                     echo -e "\n >> ${webApp} was already deleted or not available, proceeding with cache deletion...\n"
                 fi
              else
                  echo -e "\n >> ${warModule} not available, skipping 'application deletion' of ${ENV4} \n"
              fi
              }



              ## DELETE CACHE DIRECTORY FOR WEBAPP
              deleteCache() {
              cd ${cacheDir};
              if [ -f ${warModule} ];then
                 if [ -d ${ENV4} ];then
                    echo -e "\n >> Deleting ${ENV4} cache from server"
                    cd ${cacheDir};rm -rf ${ENV4};
                    echo -e "\n >> Deleted ${ENV4} under ${cacheDir} successfully \n";
                 else
                    echo -e "\n >> ${ENV4} under ${cacheDir} was already deleted or not available, proceeding with application deployment..."
                 fi
              else
                  echo -e "\n >> ${warModule} not available, skipping 'cache deletion' of ${ENV4} \n"
              fi
              }



              ## DEPLOY NEW WEB WAR FILES FROM DEPLOY LOCATION
              deployWar() {
              if [ -f ${warModule} ];then
                   echo -e "\n >> Deploying ${warModule} as ${webWar} in ${appPath}"
                   cp ${warModule} ${webWar};
                   if [ -f ${webWar} ];then
                      echo -e "\n >> Deployment of ${webWar} was successful \n"
                   else
                      echo -e "\n >> Deployment of ${webWar} failed, please check if ${warModule} exists \n"
                      exit 1;
                   fi
              else
                   echo -e "\n >> ${warModule} is  not available, please check \n"
                   exit 1;
              fi
              }


              ## CHECK IF WEB WAR FILE WAS DEPLOYED
              verifyWarDply() {
              cd ${appPath};
              sleep 180;
              extApp=$(ls *.war | cut -d"." -f1);extAppCount=$(ls *.war | cut -d"." -f1 | wc -l);
              echo -e "\n########  VALIDATING APPLICATION DEPLOYMENTS  #########";
              echo -e "\n >> Checking if \n [[ $extApp ]] \n\t were deployed and extracted ...\n";
              ls -lrt ${appPath};
              appList=$(cat $prop | sed -n 's/^APP\([^ ]*\)/\1/p' | sed "s/,/ /g" | cut -d" " -f3);
              for aps in ${extApp}
              do
                if [ "$extAppCount" -ge "$appNumend" ];then
                  if [[ $appList =~ (^|[[:space:]])$aps($|[[:space:]]) ]];then
                      if [ -d "${aps}" ];then
                           echo -e "\n >> ${aps} was deployed and extracted, try accessing the application now. \n";
                      else
                           echo -e "\n >> ${aps} was not extracted, please check. \n";
                           exit 1;
                      fi
                  fi
                else
                      echo -e "\n >> ${prop} file does not have all apps defined, please verify. \n"
                      exit 1;
                fi
              done
              }




              ###### END OF FUNCTIONS #####



              #Word count on the line
              wordCount=$(echo $apps |sed "s/,/ /g" | wc -w);
              #echo $wordCount;

              ## Call functions based on line entries
              if [ $wordCount -gt 3 ];then
                     
                      #Assign variable values
                      ENV2=$(echo $apps | sed "s/,/ /g" | cut -d" " -f1);
                      ENV3=$(echo $apps | sed "s/,/ /g" | cut -d" " -f2);
                      ENV4=$(echo $apps | sed "s/,/ /g" | cut -d" " -f3);
                      #ENV5=$(echo $apps | sed "s/,/ /g" | cut -d" " -f4);
                      #ENV6=$(echo $apps | sed "s/,/ /g" | cut -d" " -f5);
                  
                      #Custm Variables
                      warModule=${jenkinsPath}/${ENV2};
                      webWar=${appPath}/${ENV3};
                      webApp=${appPath}/${ENV4};
                      echo -e "\n###########       PROCEEDING WITH APPLICATION, ETL, RULES DEPLOYMENTS -- ${webWar}      ##########";
                                            
                      #Invoke functions
                      if [ $appNumBegin == 1 ];then
                          stopstartService stop
                      fi
                          backupETLRules
                          deployETLRules
                          undeployApp
                          deleteApp
                          deleteCache
                          deployWar
                          if [ $appNumBegin == $appNumend ];then
                              stopstartService start
                              verifyWarDply ${appNumend}
                          fi
              else

                      #Assign variable values
                      ENV2=$(echo $apps | sed "s/,/ /g" | cut -d" " -f1);
                      ENV3=$(echo $apps | sed "s/,/ /g" | cut -d" " -f2);
                      ENV4=$(echo $apps | sed "s/,/ /g" | cut -d" " -f3);


                      #Custm Variables
                      warModule=${jenkinsPath}/${ENV2};
                      webWar=${appPath}/${ENV3};
                      webApp=${appPath}/${ENV4};
                      echo -e "\n###########     PROCEEDING WITH APPLICATION DEPLOYMENT -- ${webWar}      ##########";
                                            
                      #Invoke functions
                      if [ $appNumBegin == 1 ];then
                          stopstartService stop
                      fi

                          undeployApp
                          deleteApp
                          deleteCache
                          deployWar
                          if [ $appNumBegin == $appNumend ];then
                              stopstartService start
                              verifyWarDply ${appNumend}
                          fi
                     
                        
              fi


        else 
              echo -e " >> Ignoring this $line as it does not have war files defined \n"
        fi
   done
else
  echo -e " >> ${jenkinsPath}/app.properties does not exist in $PWD \n"
  exit 1;
fi

# END DEPLOYMENT


