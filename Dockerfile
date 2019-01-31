FROM node as proddependencies

WORKDIR /opt/devcon
COPY package.json .
RUN npm set progress=false && npm config set depth 0
RUN npm install

FROM proddependencies as distribution

COPY . .
RUN npm run-script build

FROM nginx:stable-alpine

COPY --from=distribution /opt/devcon/dist/ /usr/share/nginx/html/
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
WORKDIR /usr/share/nginx/html

ENTRYPOINT [ "/docker-entrypoint.sh" ]
