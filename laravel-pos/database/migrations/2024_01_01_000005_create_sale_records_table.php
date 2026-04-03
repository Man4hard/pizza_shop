<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sale_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->onDelete('cascade');
            $table->decimal('total', 10, 2);
            $table->string('payment_method', 20);
            $table->string('customer_name', 200)->nullable();
            $table->string('table_number', 50)->nullable();
            $table->integer('item_count')->default(0);
            $table->timestamp('sold_at');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sale_records');
    }
};
