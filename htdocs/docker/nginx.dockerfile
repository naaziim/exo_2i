FROM nginx:latest

ARG http_proxy
ARG https_proxy
ARG no_proxy
ENV http_proxy=http://172.30.230.135:8080
ENV https_proxy=http://172.30.230.135:8080
ENV HTTP_PROXYh=ttp://172.30.230.135:8080
ENV HTTPS_PROXY=http://172.30.230.135:8080
ENV no_proxy=172.17.93.32,.epic.prolival.fr,127.0.0.1
ENV NO_PROXY=172.17.93.32,.epic.prolival.fr,127.0.0.1


ADD ./docker/site.conf /etc/nginx/conf.d/default.conf
