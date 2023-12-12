FROM node:18-alpine AS base

WORKDIR /app

RUN rm -rf /root/.npm

EXPOSE 8100

COPY ./voluming-start.sh /voluming-start.sh
CMD [ "sh", "/voluming-start.sh" ]
