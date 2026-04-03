<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Order extends Model
{
    protected $fillable = [
        'order_number',
        'status',
        'subtotal',
        'tax',
        'discount',
        'total',
        'payment_method',
        'customer_name',
        'table_number',
        'notes',
        'completed_at',
    ];

    protected $casts = [
        'subtotal'     => 'float',
        'tax'          => 'float',
        'discount'     => 'float',
        'total'        => 'float',
        'completed_at' => 'datetime',
    ];

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function saleRecord(): HasOne
    {
        return $this->hasOne(SaleRecord::class);
    }

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($order) {
            $order->order_number = 'ORD-' . strtoupper(substr(uniqid(), -6));
        });
    }
}
