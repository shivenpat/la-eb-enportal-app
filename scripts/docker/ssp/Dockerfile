FROM scm.artifactory.mars.pcf-maximus.com/codeshuttle/maximus-maxe/maxe-enportal-app.maxe:8.0.16

COPY reference /data/properties

RUN yum update -y \
  && yum clean all \
  && rm -rf /var/cache