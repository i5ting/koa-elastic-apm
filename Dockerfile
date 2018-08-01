FROM node:8.9.4-alpine

RUN mkdir -p /usr/src

WORKDIR /usr/src

COPY package.json /usr/src

RUN npm i --production

# RUN npm i --production --registry=https://registry.npm.taobao.org

COPY . /usr/src/

# RUN npm run assets

EXPOSE 3000

CMD npm start
