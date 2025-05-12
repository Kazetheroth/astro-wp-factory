# Étape de base avec Node
FROM node:20-alpine

# Dossier de travail
WORKDIR /app

# Copie les fichiers de dépendances
COPY package*.json ./

# Installation des dépendances
RUN npm ci

# Copie du reste de l’application
COPY . .

# Astro écoute sur le port 3000
EXPOSE 3000

# Commande de lancement (remplacée dans docker-compose par une commande dev)
CMD ["npm", "run", "dev", "--", "--host"]
