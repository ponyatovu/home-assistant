ARG BUILD_FROM
FROM $BUILD_FROM


WORKDIR data

# Copy data for add-on
# COPY run.sh /
# RUN chmod a+x /run.sh

# Copy data
COPY data/*.sh /

RUN chmod a+x /run.sh

CMD [ "/run.sh" ]


