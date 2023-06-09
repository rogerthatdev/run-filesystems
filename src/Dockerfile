FROM node:18

# Create app directory
WORKDIR /usr/src/app
 
COPY ./src/package*.json ./

RUN npm install
COPY ./src .

EXPOSE 8888
CMD [ "node", "app.js" ]