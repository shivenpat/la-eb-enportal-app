FROM scm.artifactory.mars.pcf-maximus.com/scm/maxe-enportal-app.maxe:7.9.0-SNAPSHOT.7

COPY reference /data/properties

RUN yum update -y \
  && yum clean all \
  && rm -rf /var/cache