FROM node:18

# Create app directory
WORKDIR /usr/src/app
 
COPY package*.json ./

RUN npm install
COPY . .

EXPOSE 8888
CMD [ "node", "app.js" ]