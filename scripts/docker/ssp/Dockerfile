FROM scm.artifactory.mars.pcf-maximus.com/scm/maxe-enportal-app.maxe:8.0.+

COPY reference /data/properties

RUN yum update -y \
  && yum clean all \
  && rm -rf /var/cache