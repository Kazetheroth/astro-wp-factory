PROJECT_NAME=project-factory
ASTRO_DIR=src/frontend
WP_DIR=src/backend
DB_NAME=wordpress
DB_USER=wpuser
DB_PASSWORD=wppassword
DB_ROOT_PASSWORD=rootpassword
DB_IMAGE=mariadb:10.11
WP_IMAGE=wordpress:php8.2-apache
ASTRO_DOCKERFILE=docker/frontend/astro.Dockerfile

.PHONY: all init astro wp compose up down clean

all: init astro wp compose up

init:
	@echo "🔧 Initialisation..."
	@mkdir -p $(ASTRO_DIR)
	@mkdir -p $(WP_DIR)

astro:
	@if [ ! -f $(ASTRO_DIR)/package.json ]; then \
		echo "🚀 Création du projet Astro..."; \
		cd $(ASTRO_DIR) && npm create astro@latest . -- --yes; \
	else \
		echo "✅ Projet Astro déjà initialisé."; \
	fi

wp:
	@if [ ! -f $(WP_DIR)/wp-config-sample.php ]; then \
		echo "📦 Téléchargement de WordPress..."; \
		curl -L https://wordpress.org/latest.zip -o latest.zip; \
		unzip latest.zip; \
		mv wordpress/* $(WP_DIR)/; \
		rm -rf wordpress latest.zip; \
		echo "✅ WordPress installé dans $(WP_DIR)/."; \
	else \
		echo "✅ WordPress déjà installé."; \
	fi

compose:
	@if [ ! -f docker-compose.yml ]; then \
		echo "📝 Génération de docker-compose.yml..."; \
		cat > docker-compose.yml <<EOF \
version: '3.9'

services:
  mariadb:
    image: $(DB_IMAGE)
    container_name: mariadb
    environment:
      MYSQL_DATABASE: $(DB_NAME)
      MYSQL_USER: $(DB_USER)
      MYSQL_PASSWORD: $(DB_PASSWORD)
      MYSQL_ROOT_PASSWORD: $(DB_ROOT_PASSWORD)
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - wpnet

  wordpress:
    image: $(WP_IMAGE)
    container_name: wordpress
    depends_on:
      - mariadb
    ports:
      - "8000:80"
    environment:
      WORDPRESS_DB_HOST: mariadb
      WORDPRESS_DB_NAME: $(DB_NAME)
      WORDPRESS_DB_USER: $(DB_USER)
      WORDPRESS_DB_PASSWORD: $(DB_PASSWORD)
    volumes:
      - ./$(WP_DIR):/var/www/html
    networks:
      - wpnet

  astro:
    container_name: astro
    build:
      context: ./$(ASTRO_DIR)
      dockerfile: ../$(ASTRO_DOCKERFILE)
    ports:
      - "3000:3000"
    volumes:
      - ./$(ASTRO_DIR):/app
    command: ["npm", "run", "dev", "--", "--host"]
    networks:
      - wpnet

volumes:
  db_data:

networks:
  wpnet:
    driver: bridge
EOF \
	; else \
		echo "✅ docker-compose.yml déjà existant."; \
	fi

up:
	docker-compose up -d --build

down:
	docker-compose down

clean: down
	@echo "🧹 Nettoyage..."
	@rm -rf $(ASTRO_DIR) $(WP_DIR) docker-compose.yml latest.zip wordpress
