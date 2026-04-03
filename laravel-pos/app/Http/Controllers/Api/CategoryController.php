<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    public function index(): JsonResponse
    {
        $categories = Category::orderBy('id')->get()->map(fn($c) => [
            'id'        => $c->id,
            'name'      => $c->name,
            'icon'      => $c->icon,
            'createdAt' => $c->created_at->toIso8601String(),
        ]);

        return response()->json($categories);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:100',
            'icon' => 'nullable|string|max:20',
        ]);

        $category = Category::create([
            'name' => $request->name,
            'icon' => $request->icon,
        ]);

        return response()->json([
            'id'        => $category->id,
            'name'      => $category->name,
            'icon'      => $category->icon,
            'createdAt' => $category->created_at->toIso8601String(),
        ], 201);
    }

    public function destroy(int $id): JsonResponse
    {
        $category = Category::findOrFail($id);
        $category->delete();

        return response()->json(['success' => true, 'message' => 'Category deleted']);
    }
}
