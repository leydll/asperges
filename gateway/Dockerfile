FROM nginx:alpine

# Argument pour choisir la configuration (docker-compose ou k8s)
ARG CONFIG_TYPE=docker-compose

# Copier la configuration nginx appropriée
COPY nginx.conf /tmp/nginx-docker.conf
COPY nginx-k8s.conf /tmp/nginx-k8s.conf

# Utiliser la bonne configuration selon l'environnement
RUN if [ "$CONFIG_TYPE" = "k8s" ]; then \
        cp /tmp/nginx-k8s.conf /etc/nginx/conf.d/default.conf; \
    else \
        cp /tmp/nginx-docker.conf /etc/nginx/conf.d/default.conf; \
    fi

# Exposer le port 80
EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

# Commande pour démarrer nginx
CMD ["nginx", "-g", "daemon off;"]

