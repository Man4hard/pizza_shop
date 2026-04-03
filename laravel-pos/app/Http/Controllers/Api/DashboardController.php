<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\SaleRecord;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function summary(): JsonResponse
    {
        $today = Carbon::today();

        $orders = Order::whereDate('created_at', $today)->get();
        $completed = $orders->where('status', 'completed');
        $totalSales = $completed->sum('total');
        $avgOrder = $completed->count() > 0 ? $totalSales / $completed->count() : 0;

        return response()->json([
            'totalSalesToday'   => round($totalSales, 2),
            'totalOrdersToday'  => $orders->count(),
            'averageOrderValue' => round($avgOrder, 2),
            'pendingOrders'     => $orders->where('status', 'pending')->count(),
            'completedOrders'   => $completed->count(),
            'cancelledOrders'   => $orders->where('status', 'cancelled')->count(),
        ]);
    }

    public function topProducts(): JsonResponse
    {
        $today = Carbon::today();

        $top = OrderItem::select(
            'product_id',
            DB::raw('SUM(quantity) as quantity_sold'),
            DB::raw('SUM(subtotal) as revenue')
        )
            ->whereHas('order', fn($q) => $q->whereDate('created_at', $today)->where('status', 'completed'))
            ->with('product')
            ->groupBy('product_id')
            ->orderByDesc('quantity_sold')
            ->limit(10)
            ->get();

        return response()->json($top->map(fn($item) => [
            'productId'    => $item->product_id,
            'productName'  => $item->product?->name ?? 'Unknown',
            'quantitySold' => (int) $item->quantity_sold,
            'revenue'      => round((float) $item->revenue, 2),
        ]));
    }

    public function recentOrders(): JsonResponse
    {
        $orders = Order::orderByDesc('created_at')->limit(10)->get();

        return response()->json($orders->map(fn($o) => [
            'id'            => $o->id,
            'orderNumber'   => $o->order_number,
            'status'        => $o->status,
            'subtotal'      => (float) $o->subtotal,
            'tax'           => (float) $o->tax,
            'discount'      => (float) $o->discount,
            'total'         => (float) $o->total,
            'paymentMethod' => $o->payment_method,
            'customerName'  => $o->customer_name,
            'tableNumber'   => $o->table_number,
            'notes'         => $o->notes,
            'createdAt'     => $o->created_at->toIso8601String(),
            'completedAt'   => $o->completed_at?->toIso8601String(),
        ]));
    }

    public function hourlySales(): JsonResponse
    {
        $today = Carbon::today();

        $rawSales = SaleRecord::whereDate('sold_at', $today)
            ->select(
                DB::raw('HOUR(sold_at) as hour'),
                DB::raw('SUM(total) as sales'),
                DB::raw('COUNT(*) as orders')
            )
            ->groupBy('hour')
            ->orderBy('hour')
            ->get()
            ->keyBy('hour');

        // Fill all 24 hours
        $result = collect(range(0, 23))->map(fn($h) => [
            'hour'   => $h,
            'sales'  => isset($rawSales[$h]) ? round((float) $rawSales[$h]->sales, 2) : 0.0,
            'orders' => isset($rawSales[$h]) ? (int) $rawSales[$h]->orders : 0,
        ]);

        return response()->json($result);
    }
}
