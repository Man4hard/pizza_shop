# Ahmed Fast Food POS - Laravel API Setup Guide

## Requirements
- PHP 8.2+
- Composer
- MySQL 8.0+ or MariaDB
- Apache or Nginx web server (or PHP built-in server for testing)

## 1. Create a New Laravel Project

This folder contains only the custom files. Create a fresh Laravel project and copy these files into it:

```bash
# Create new Laravel project
composer create-project laravel/laravel pizza-pos-api
cd pizza-pos-api

# Copy the files from this folder into the project:
# - app/Models/* → app/Models/
# - app/Http/Controllers/Api/* → app/Http/Controllers/Api/
# - database/migrations/* → database/migrations/
# - database/seeders/* → database/seeders/
# - routes/api.php → routes/api.php
```

## 2. Configure the Database

Copy `.env.example` to `.env` and configure your database:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=pizza_pos
DB_USERNAME=root
DB_PASSWORD=your_password
```

## 3. Run Migrations & Seed Data

```bash
php artisan key:generate
php artisan migrate
php artisan db:seed
```

This creates all tables and seeds sample pizza menu items.

## 4. Configure CORS

Open `config/cors.php` and allow your Flutter app's origin:

```php
'allowed_origins' => ['*'],  // Or specific IP for production
```

## 5. Start the Development Server

```bash
php artisan serve
# Runs at http://localhost:8000
```

For production, point Apache/Nginx to the `public/` directory.

## 6. API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/categories | List all categories |
| POST | /api/categories | Create category |
| DELETE | /api/categories/{id} | Delete category |
| GET | /api/products | List all products |
| GET | /api/products?categoryId=1 | Filter by category |
| POST | /api/products | Create product |
| PUT | /api/products/{id} | Update product |
| DELETE | /api/products/{id} | Delete product |
| GET | /api/orders | List orders |
| GET | /api/orders?status=pending | Filter by status |
| POST | /api/orders | Create new order |
| GET | /api/orders/{id} | Get order details |
| POST | /api/orders/{id}/complete | Complete & bill order |
| POST | /api/orders/{id}/cancel | Cancel order |
| GET | /api/sales | List sale records |
| GET | /api/sales?startDate=2024-01-01&endDate=2024-01-31 | Filter by date |
| GET | /api/dashboard/summary | Today's summary stats |
| GET | /api/dashboard/top-products | Top selling products |
| GET | /api/dashboard/recent-orders | Recent orders |
| GET | /api/dashboard/hourly-sales | Hourly sales breakdown |

## Database Schema

```
categories          products
──────────          ────────
id                  id
name                category_id (FK)
icon                name
created_at          description
updated_at          price
                    image_url
                    available
                    created_at
                    updated_at

orders              order_items
──────              ───────────
id                  id
order_number        order_id (FK)
status              product_id (FK)
subtotal            quantity
tax                 unit_price
discount            subtotal
total               created_at
payment_method      updated_at
customer_name
table_number        sale_records
notes               ────────────
completed_at        id
created_at          order_id (FK)
updated_at          total
                    payment_method
                    customer_name
                    table_number
                    item_count
                    sold_at
```

## Production Deployment (Apache)

```apache
<VirtualHost *:80>
    ServerName yourserver.com
    DocumentRoot /var/www/pizza-pos-api/public

    <Directory /var/www/pizza-pos-api/public>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

Then in the Flutter app set:
```dart
static const String baseUrl = 'http://yourserver.com/api';
```
