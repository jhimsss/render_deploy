FROM php:8.2-cli

WORKDIR /app

# Install PHP extensions and system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    curl \
    libpq-dev \
    nodejs npm \
    && docker-php-ext-install pdo pdo_pgsql zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy project files
COPY . .

# Install Laravel dependencies
RUN composer install --no-dev --optimize-autoloader

# Generate app key
RUN php artisan key:generate

# Install frontend dependencies and build assets
RUN npm install
RUN npm run build

# Expose port
EXPOSE 10000

# Startup: wait a few seconds, run migrations, then serve
CMD sleep 5 && php artisan migrate --force && php -S 0.0.0.0:10000 -t public