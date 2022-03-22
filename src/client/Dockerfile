FROM node:9 as build

WORKDIR /app

COPY package*.json ./
RUN npm install


FROM node:9-slim
RUN apt update
RUN apt upgrade -y

WORKDIR /app
COPY --from=build /app .
COPY . .

EXPOSE 3000

CMD [ "node", "index.js"]
