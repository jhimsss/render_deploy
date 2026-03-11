FROM php:8.2-cli

# Set working directory
WORKDIR /var/www

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    libpng-dev \
    libpq-dev \
    nodejs \
    npm \
    && docker-php-ext-install pdo pdo_pgsql zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy project
COPY . .

# Install Laravel dependencies
RUN composer install --no-dev --optimize-autoloader

# Install frontend dependencies
RUN npm install && npm run build

# Fix permissions
RUN chmod -R 775 storage bootstrap/cache

# Set environment variables for Laravel
ENV APP_ENV=production
ENV APP_DEBUG=false

# Generate app key and clear caches **at build time**
RUN php artisan key:generate \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

# Expose port for Render
EXPOSE 10000

# Start Laravel at runtime (only serve, no migrations or cache clearing here)
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=10000"]
