<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SaleRecord extends Model
{
    protected $fillable = [
        'order_id',
        'total',
        'payment_method',
        'customer_name',
        'table_number',
        'item_count',
        'sold_at',
    ];

    protected $casts = [
        'total'   => 'float',
        'sold_at' => 'datetime',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }
}
