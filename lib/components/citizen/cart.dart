import 'package:flutter/material.dart';

class Cart extends StatelessWidget {
  final List<Product> products = [
    Product(
      name: 'Plant',
      price: 200,
      description: 'A beautiful indoor plant to brighten up your space.',
      rating: 4.5,
      imageUrl:
      'https://cdn.pixabay.com/photo/2014/12/11/11/14/blumenstock-564132_960_720.jpg',
    ),
    Product(
      name: 'Glass',
      price: 50,
      description: 'A high-quality glass for everyday use.',
      rating: 4.0,
      imageUrl:
      'https://media.istockphoto.com/id/467521964/photo/isolated-shot-of-disposable-coffee-cup-on-white-background.jpg?s=2048x2048&w=is&k=20&c=CpgJrxWRGtA7ID1IBqAv21o6GTAa1EJOmA2v39rgMq0=',
    ),
    Product(
      name: 'Paper',
      price: 25,
      description: 'Recycled paper for all your writing needs.',
      rating: 4.8,
      imageUrl:
      'https://cdn.pixabay.com/photo/2024/01/15/20/51/plate-8510868_1280.jpg',
    ),
  ];

  Cart({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text(
              "Cart",
              style: TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            Spacer(),
            Row(
              children: [
                SizedBox(width: 8.0),
                Text(
                  "200 Pts",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 5,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                "\$${product.price.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 20),
                                  Text(
                                    "${product.rating.toStringAsFixed(1)}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Buy Now Button
                    ElevatedButton(
                      onPressed: () {
                        // Implement the "Buy Now" functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        elevation: 3,
                      ),
                      child: const Text(
                        "Buy",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Product Model
class Product {
  final String name;
  final double price;
  final String description;
  final double rating;
  final String imageUrl;

  Product({
    required this.name,
    required this.price,
    required this.description,
    required this.rating,
    required this.imageUrl,
  });
}
