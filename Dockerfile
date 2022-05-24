FROM node:16

LABEL Author="Cliff Moran"

#simple http server for serving static content

WORKDIR /app

# Install dependencies
COPY package*.json ./

RUN npm install
RUN npm install d3-sankey
RUN npm install --save topojson-client

COPY . .

EXPOSE 8080
CMD [ "npm run serve" ]