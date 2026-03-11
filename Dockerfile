# =========================
# Laravel + Node Dockerfile
# =========================

FROM php:8.2-cli

# Set working directory
WORKDIR /var/www

# -------------------------
# Install system dependencies
# -------------------------
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    libpng-dev \
    libpq-dev \
    nodejs \
    npm \
    && docker-php-ext-install pdo pdo_pgsql zip mbstring tokenizer xml ctype \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# -------------------------
# Install Composer
# -------------------------
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# -------------------------
# Copy project files
# -------------------------
COPY . .

# -------------------------
# Copy .env if not already present
# -------------------------
COPY .env.example .env

# -------------------------
# Install Laravel dependencies
# -------------------------
RUN composer install --no-dev --optimize-autoloader

# -------------------------
# Install frontend dependencies
# -------------------------
RUN npm install && npm run build

# -------------------------
# Fix permissions
# -------------------------
RUN chmod -R 775 storage bootstrap/cache

# -------------------------
# Set Laravel environment variables
# -------------------------
ENV APP_ENV=production
ENV APP_DEBUG=false

# -------------------------
# Generate key and cache config/routes at build time
# -------------------------
RUN php artisan key:generate \
    && php artisan config:cache \
    && php artisan route:cache
# Note: view:cache is skipped at build; we run it at container start

# -------------------------
# Expose port
# -------------------------
EXPOSE 10000

# -------------------------
# Entrypoint for migrations and view cache
# -------------------------
ENTRYPOINT ["sh", "-c", "php artisan migrate --force && php artisan view:cache && exec \"$@\""]

# -------------------------
# Start Laravel server
# -------------------------
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=10000"]
