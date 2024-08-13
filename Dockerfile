# base image
FROM node:18.16.1-alpine3.18

# create & set working directory
RUN mkdir -p /usr/src
WORKDIR /usr/src

# copy source files
COPY ./code/front-end /usr/src

# install dependencies
RUN npm ci

# start app
RUN npm run build

# open port
EXPOSE 3000

# start the app
CMD npm run start
