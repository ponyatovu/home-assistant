ARG BUILD_FROM
FROM $BUILD_FROM


WORKDIR data

# Copy data for add-on
# COPY run.sh /
# RUN chmod a+x /run.sh

# Copy data
COPY data/*.sh /

RUN chmod a+x /run.sh
RUN chmod a+x /trycatch.sh

CMD [ "/run.sh" ]


