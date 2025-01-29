FROM scm/codeshuttle/maximus-maxe/maxe-enportal-app.maxe/8.2.32/


COPY reference /data/properties

RUN yum update -y \
  && yum clean all \
  && rm -rf /var/cache