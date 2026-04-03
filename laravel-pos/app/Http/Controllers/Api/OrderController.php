<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\SaleRecord;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class OrderController extends Controller
{
    private function formatOrder(Order $order, bool $withItems = false): array
    {
        $data = [
            'id'            => $order->id,
            'orderNumber'   => $order->order_number,
            'status'        => $order->status,
            'subtotal'      => (float) $order->subtotal,
            'tax'           => (float) $order->tax,
            'discount'      => (float) $order->discount,
            'total'         => (float) $order->total,
            'paymentMethod' => $order->payment_method,
            'customerName'  => $order->customer_name,
            'tableNumber'   => $order->table_number,
            'notes'         => $order->notes,
            'createdAt'     => $order->created_at->toIso8601String(),
            'completedAt'   => $order->completed_at?->toIso8601String(),
        ];

        if ($withItems) {
            $data['items'] = $order->items->map(fn($item) => [
                'id'          => $item->id,
                'productId'   => $item->product_id,
                'productName' => $item->product?->name ?? 'Unknown',
                'quantity'    => $item->quantity,
                'unitPrice'   => (float) $item->unit_price,
                'subtotal'    => (float) $item->subtotal,
            ])->values()->toArray();
        }

        return $data;
    }

    public function index(Request $request): JsonResponse
    {
        $query = Order::query();

        if ($request->has('date')) {
            $date = Carbon::parse($request->date);
            $query->whereDate('created_at', $date);
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $orders = $query->orderByDesc('created_at')->get();
        return response()->json($orders->map(fn($o) => $this->formatOrder($o)));
    }

    public function show(int $id): JsonResponse
    {
        $order = Order::with(['items.product'])->findOrFail($id);
        return response()->json($this->formatOrder($order, withItems: true));
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'items'                => 'required|array|min:1',
            'items.*.productId'    => 'required|exists:products,id',
            'items.*.quantity'     => 'required|integer|min:1',
            'customerName'         => 'nullable|string|max:200',
            'tableNumber'          => 'nullable|string|max:50',
            'notes'                => 'nullable|string',
        ]);

        // Calculate totals
        $subtotal = 0;
        $cartItems = [];

        foreach ($request->items as $item) {
            $product = Product::findOrFail($item['productId']);
            $itemSubtotal = $product->price * $item['quantity'];
            $subtotal += $itemSubtotal;
            $cartItems[] = [
                'product'   => $product,
                'quantity'  => $item['quantity'],
                'subtotal'  => $itemSubtotal,
            ];
        }

        $tax   = round($subtotal * 0.10, 2);
        $total = $subtotal + $tax;

        $order = Order::create([
            'status'        => 'pending',
            'subtotal'      => round($subtotal, 2),
            'tax'           => $tax,
            'discount'      => 0,
            'total'         => round($total, 2),
            'customer_name' => $request->customerName,
            'table_number'  => $request->tableNumber,
            'notes'         => $request->notes,
        ]);

        foreach ($cartItems as $ci) {
            OrderItem::create([
                'order_id'   => $order->id,
                'product_id' => $ci['product']->id,
                'quantity'   => $ci['quantity'],
                'unit_price' => $ci['product']->price,
                'subtotal'   => $ci['subtotal'],
            ]);
        }

        $order->load('items.product');
        return response()->json($this->formatOrder($order, withItems: true), 201);
    }

    public function complete(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'paymentMethod' => 'required|in:cash,card,digital',
            'discount'      => 'nullable|numeric|min:0',
        ]);

        $order = Order::with('items.product')->findOrFail($id);

        if ($order->status !== 'pending') {
            return response()->json(['error' => 'Order is not pending'], 422);
        }

        $discount = (float) ($request->discount ?? 0);
        $total    = max(0, $order->subtotal + $order->tax - $discount);

        $order->update([
            'status'         => 'completed',
            'payment_method' => $request->paymentMethod,
            'discount'       => $discount,
            'total'          => round($total, 2),
            'completed_at'   => now(),
        ]);

        // Create sale record
        SaleRecord::create([
            'order_id'       => $order->id,
            'total'          => round($total, 2),
            'payment_method' => $request->paymentMethod,
            'customer_name'  => $order->customer_name,
            'table_number'   => $order->table_number,
            'item_count'     => $order->items->sum('quantity'),
            'sold_at'        => now(),
        ]);

        return response()->json($this->formatOrder($order, withItems: true));
    }

    public function cancel(int $id): JsonResponse
    {
        $order = Order::findOrFail($id);

        if ($order->status !== 'pending') {
            return response()->json(['error' => 'Only pending orders can be cancelled'], 422);
        }

        $order->update(['status' => 'cancelled']);
        return response()->json(['success' => true, 'message' => 'Order cancelled']);
    }
}
