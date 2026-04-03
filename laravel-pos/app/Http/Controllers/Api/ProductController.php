<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    private function format(Product $p): array
    {
        return [
            'id'           => $p->id,
            'name'         => $p->name,
            'description'  => $p->description,
            'price'        => (float) $p->price,
            'categoryId'   => $p->category_id,
            'categoryName' => $p->category?->name,
            'imageUrl'     => $p->image_url,
            'available'    => (bool) $p->available,
            'createdAt'    => $p->created_at->toIso8601String(),
        ];
    }

    public function index(Request $request): JsonResponse
    {
        $query = Product::with('category');

        if ($request->has('categoryId')) {
            $query->where('category_id', $request->categoryId);
        }

        return response()->json($query->orderBy('name')->get()->map(fn($p) => $this->format($p)));
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name'        => 'required|string|max:200',
            'price'       => 'required|numeric|min:0',
            'category_id' => 'required|exists:categories,id',
            'description' => 'nullable|string',
            'image_url'   => 'nullable|url',
            'available'   => 'nullable|boolean',
        ]);

        $product = Product::create([
            'name'        => $request->name,
            'description' => $request->description,
            'price'       => $request->price,
            'category_id' => $request->categoryId ?? $request->category_id,
            'image_url'   => $request->imageUrl ?? $request->image_url,
            'available'   => $request->available ?? true,
        ]);

        $product->load('category');
        return response()->json($this->format($product), 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $product = Product::findOrFail($id);

        $request->validate([
            'name'        => 'required|string|max:200',
            'price'       => 'required|numeric|min:0',
            'category_id' => 'required|exists:categories,id',
        ]);

        $product->update([
            'name'        => $request->name,
            'description' => $request->description,
            'price'       => $request->price,
            'category_id' => $request->categoryId ?? $request->category_id,
            'image_url'   => $request->imageUrl ?? $request->image_url,
            'available'   => $request->available ?? $product->available,
        ]);

        $product->load('category');
        return response()->json($this->format($product));
    }

    public function destroy(int $id): JsonResponse
    {
        Product::findOrFail($id)->delete();
        return response()->json(['success' => true, 'message' => 'Product deleted']);
    }
}
