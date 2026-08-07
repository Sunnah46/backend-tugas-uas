<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $categories = [
            ['category_name' => 'Seminar', 'description' => 'Seminar Nasional'],
            ['category_name' => 'Workshop', 'description' => 'Pelatihan'],
            ['category_name' => 'Webinar', 'description' => 'Seminar Online'],
            ['category_name' => 'Lomba', 'description' => 'Kompetisi'],
            ['category_name' => 'Pelatihan', 'description' => 'Pelatihan Sertifikasi'],
        ];

        foreach ($categories as $category) {
            Category::updateOrCreate(['category_name' => $category['category_name']], $category);
        }
    }
}
