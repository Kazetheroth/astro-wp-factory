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
		echo "version: '3.9'" > docker-compose.yml; \
		echo "" >> docker-compose.yml; \
		echo "services:" >> docker-compose.yml; \
		echo "  mariadb:" >> docker-compose.yml; \
		echo "    image: $(DB_IMAGE)" >> docker-compose.yml; \
		echo "    container_name: mariadb" >> docker-compose.yml; \
		echo "    environment:" >> docker-compose.yml; \
		echo "      MYSQL_DATABASE: $(DB_NAME)" >> docker-compose.yml; \
		echo "      MYSQL_USER: $(DB_USER)" >> docker-compose.yml; \
		echo "      MYSQL_PASSWORD: $(DB_PASSWORD)" >> docker-compose.yml; \
		echo "      MYSQL_ROOT_PASSWORD: $(DB_ROOT_PASSWORD)" >> docker-compose.yml; \
		echo "    volumes:" >> docker-compose.yml; \
		echo "      - db_data:/var/lib/mysql" >> docker-compose.yml; \
		echo "    networks:" >> docker-compose.yml; \
		echo "      - wpnet" >> docker-compose.yml; \
		echo "" >> docker-compose.yml; \
		echo "  wordpress:" >> docker-compose.yml; \
		echo "    image: $(WP_IMAGE)" >> docker-compose.yml; \
		echo "    container_name: wordpress" >> docker-compose.yml; \
		echo "    depends_on:" >> docker-compose.yml; \
		echo "      - mariadb" >> docker-compose.yml; \
		echo "    ports:" >> docker-compose.yml; \
		echo "      - \"8000:80\"" >> docker-compose.yml; \
		echo "    environment:" >> docker-compose.yml; \
		echo "      WORDPRESS_DB_HOST: mariadb" >> docker-compose.yml; \
		echo "      WORDPRESS_DB_NAME: $(DB_NAME)" >> docker-compose.yml; \
		echo "      WORDPRESS_DB_USER: $(DB_USER)" >> docker-compose.yml; \
		echo "      WORDPRESS_DB_PASSWORD: $(DB_PASSWORD)" >> docker-compose.yml; \
		echo "    volumes:" >> docker-compose.yml; \
		echo "      - ./$(WP_DIR):/var/www/html" >> docker-compose.yml; \
		echo "    networks:" >> docker-compose.yml; \
		echo "      - wpnet" >> docker-compose.yml; \
		echo "" >> docker-compose.yml; \
		echo "  astro:" >> docker-compose.yml; \
		echo "    container_name: astro" >> docker-compose.yml; \
		echo "    build:" >> docker-compose.yml; \
		echo "      context: ./$(ASTRO_DIR)" >> docker-compose.yml; \
		echo "      dockerfile: ../../$(ASTRO_DOCKERFILE)" >> docker-compose.yml; \
		echo "    ports:" >> docker-compose.yml; \
		echo "      - \"3000:4321\"" >> docker-compose.yml; \
		echo "    volumes:" >> docker-compose.yml; \
		echo "      - ./$(ASTRO_DIR):/app" >> docker-compose.yml; \
		echo "    command: [\"npm\", \"run\", \"dev\", \"--\", \"--host\"]" >> docker-compose.yml; \
		echo "    networks:" >> docker-compose.yml; \
		echo "      - wpnet" >> docker-compose.yml; \
		echo "" >> docker-compose.yml; \
		echo "volumes:" >> docker-compose.yml; \
		echo "  db_data:" >> docker-compose.yml; \
		echo "" >> docker-compose.yml; \
		echo "networks:" >> docker-compose.yml; \
		echo "  wpnet:" >> docker-compose.yml; \
		echo "    driver: bridge" >> docker-compose.yml; \
	else \
		echo "✅ docker-compose.yml déjà existant."; \
	fi


up:
	docker-compose up -d --build

down:
	docker-compose down

clean: down
	@echo "🧹 Nettoyage..."
	@rm -rf $(ASTRO_DIR) $(WP_DIR) docker-compose.yml latest.zip wordpress
