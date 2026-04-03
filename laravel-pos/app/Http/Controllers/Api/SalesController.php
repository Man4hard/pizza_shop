<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SaleRecord;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class SalesController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = SaleRecord::with('order');

        if ($request->has('startDate')) {
            $query->whereDate('sold_at', '>=', Carbon::parse($request->startDate));
        }

        if ($request->has('endDate')) {
            $query->whereDate('sold_at', '<=', Carbon::parse($request->endDate));
        }

        $sales = $query->orderByDesc('sold_at')->get();

        return response()->json($sales->map(fn($s) => [
            'id'            => $s->id,
            'orderId'       => $s->order_id,
            'orderNumber'   => $s->order?->order_number ?? 'N/A',
            'total'         => (float) $s->total,
            'paymentMethod' => $s->payment_method,
            'customerName'  => $s->customer_name,
            'tableNumber'   => $s->table_number,
            'itemCount'     => $s->item_count,
            'soldAt'        => $s->sold_at->toIso8601String(),
        ]));
    }
}
