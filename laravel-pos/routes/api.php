<?php

use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\SalesController;
use Illuminate\Support\Facades\Route;

// Categories
Route::get('/categories', [CategoryController::class, 'index']);
Route::post('/categories', [CategoryController::class, 'store']);
Route::delete('/categories/{id}', [CategoryController::class, 'destroy']);

// Products
Route::get('/products', [ProductController::class, 'index']);
Route::post('/products', [ProductController::class, 'store']);
Route::put('/products/{id}', [ProductController::class, 'update']);
Route::delete('/products/{id}', [ProductController::class, 'destroy']);

// Orders
Route::get('/orders', [OrderController::class, 'index']);
Route::post('/orders', [OrderController::class, 'store']);
Route::get('/orders/{id}', [OrderController::class, 'show']);
Route::post('/orders/{id}/complete', [OrderController::class, 'complete']);
Route::post('/orders/{id}/cancel', [OrderController::class, 'cancel']);

// Sales
Route::get('/sales', [SalesController::class, 'index']);

// Dashboard
Route::get('/dashboard/summary', [DashboardController::class, 'summary']);
Route::get('/dashboard/top-products', [DashboardController::class, 'topProducts']);
Route::get('/dashboard/recent-orders', [DashboardController::class, 'recentOrders']);
Route::get('/dashboard/hourly-sales', [DashboardController::class, 'hourlySales']);
