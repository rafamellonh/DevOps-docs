FROM node:20.11.0
WORKDIR /app
COPY pacckage*.json ./
RUN npm install
COPY . .
EXPOSE 8080
CMD [ "cmd", "server.js" ]