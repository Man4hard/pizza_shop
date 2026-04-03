<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use Illuminate\Database\Seeder;

class PizzaSeeder extends Seeder
{
    public function run(): void
    {
        // ── Categories (order matters — API sorts by ID) ──────────────────────
        $regular  = Category::create(['name' => 'Regular Pizzas',     'icon' => '🍕']);
        $special  = Category::create(['name' => 'Special Pizzas',     'icon' => '⭐']);
        $deals    = Category::create(['name' => 'Special Deals',      'icon' => '🎁']);
        $burgers  = Category::create(['name' => 'Burgers & Shawarma', 'icon' => '🍔']);
        $grilled  = Category::create(['name' => 'Crispy & Grilled',   'icon' => '🍗']);

        // ── Regular Pizza Flavors (S / M / L / XL) ───────────────────────────
        $regularFlavors = [
            'Chicken Tikka Pizza'  => [450, 900, 1250, 1750],
            'Chicken Fajita Pizza' => [450, 900, 1250, 1750],
            'BBQ Pizza'            => [450, 900, 1250, 1750],
            'Tandoori Pizza'       => [450, 900, 1250, 1750],
            'Hot & Spicy Pizza'    => [450, 900, 1250, 1750],
        ];

        $sizes = [
            0 => ['label' => 'Small',  'desc' => 'Small size'],
            1 => ['label' => 'Medium', 'desc' => 'Medium size'],
            2 => ['label' => 'Large',  'desc' => 'Large size'],
            3 => ['label' => 'XL',     'desc' => 'Extra large size'],
        ];

        foreach ($regularFlavors as $name => $prices) {
            foreach ($sizes as $i => $size) {
                Product::create([
                    'category_id' => $regular->id,
                    'name'        => "$name ({$size['label']})",
                    'description' => "$name — {$size['desc']}",
                    'price'       => $prices[$i],
                    'available'   => true,
                ]);
            }
        }

        // ── Special Pizza Flavors (S / M / L / XL) ───────────────────────────
        $specialFlavors = [
            'Ahmed Special Pizza'       => [550, 1000, 1350, 1950],
            'Chicken Malai Boti Pizza'  => [550, 1050, 1350, 1950],
            'Kababish Pizza'            => [550, 1050, 1350, 2150],
            'Crown Crust Pizza'         => [650, 1100, 1550, 2350],
        ];

        foreach ($specialFlavors as $name => $prices) {
            foreach ($sizes as $i => $size) {
                Product::create([
                    'category_id' => $special->id,
                    'name'        => "$name ({$size['label']})",
                    'description' => "$name — {$size['desc']} (Special Flavor)",
                    'price'       => $prices[$i],
                    'available'   => true,
                ]);
            }
        }

        // ── Burgers & Shawarma ────────────────────────────────────────────────
        $burgerItems = [
            ['name' => 'Zinger Shawarma',    'price' => 330,  'description' => 'Crispy zinger in a shawarma wrap'],
            ['name' => 'Zinger Burger',      'price' => 330,  'description' => 'Crispy zinger chicken burger'],
            ['name' => 'Chicken Shawarma',   'price' => 180,  'description' => 'Classic chicken shawarma wrap'],
            ['name' => 'Anda Shami Burger',  'price' => 150,  'description' => 'Egg & shami patty burger'],
        ];

        foreach ($burgerItems as $item) {
            Product::create([
                'category_id' => $burgers->id,
                'name'        => $item['name'],
                'description' => $item['description'],
                'price'       => $item['price'],
                'available'   => true,
            ]);
        }

        // ── Crispy & Grilled ──────────────────────────────────────────────────
        $grilledItems = [
            ['name' => 'Special Angara Chicken', 'price' => 1500, 'description' => 'Special Angara chicken — price per kg'],
            ['name' => 'Grill Fish',              'price' => 1350, 'description' => 'Special grill fish — price per kg'],
        ];

        foreach ($grilledItems as $item) {
            Product::create([
                'category_id' => $grilled->id,
                'name'        => $item['name'],
                'description' => $item['description'],
                'price'       => $item['price'],
                'available'   => true,
            ]);
        }

        // ── Special Deals ─────────────────────────────────────────────────────
        $dealItems = [
            [
                'name'        => 'Deal 1',
                'price'       => 1000,
                'description' => '2 Small Pizzas + 1 Liter Drink',
            ],
            [
                'name'        => 'Deal 2',
                'price'       => 1950,
                'description' => '2 Medium Pizzas + 1.5 Liter Drink',
            ],
            [
                'name'        => 'Deal 3',
                'price'       => 2650,
                'description' => '2 Large Pizzas + 1.5 Liter Drink',
            ],
            [
                'name'        => 'Deal 4',
                'price'       => 500,
                'description' => '1 Shawarma + 1 Chicken Burger + Half Liter Drink',
            ],
            [
                'name'        => 'Deal 5',
                'price'       => 850,
                'description' => '1 Small Pizza + 1 Zinger Burger + Half Liter Drink',
            ],
            [
                'name'        => 'Deal 6',
                'price'       => 1900,
                'description' => '1 Medium Pizza + 1 Zinger Burger + Large Fries + Half Liter Drink',
            ],
            [
                'name'        => 'Deal 7',
                'price'       => 2650,
                'description' => '1 Small Pizza + 1 Medium Pizza + 1 Large Pizza',
            ],
            [
                'name'        => 'Deal 8',
                'price'       => 2800,
                'description' => '4 Zinger Burgers + 24 Crispy Wings + 2 Regular Fries + 1.5 Liter Drink',
            ],
            [
                'name'        => 'Deal 9',
                'price'       => 2450,
                'description' => '3 Small Pizzas + 12 Nuggets + 1 Family Fries + 1.5 Liter Drink',
            ],
        ];

        foreach ($dealItems as $item) {
            Product::create([
                'category_id' => $deals->id,
                'name'        => $item['name'],
                'description' => $item['description'],
                'price'       => $item['price'],
                'available'   => true,
            ]);
        }
    }
}
