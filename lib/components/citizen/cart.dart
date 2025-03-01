import 'package:flutter/material.dart';


class Cart extends StatelessWidget {
  final List<Product> products = [
    Product(
      name: 'Plant',
      price: 200,
      description: 'A beautiful indoor plant to brighten up your space.',
      rating: 4.5,
      imageUrl: 'https://cdn.pixabay.com/photo/2014/12/11/11/14/blumenstock-564132_960_720.jpg',
    ),
    Product(
      name: 'Glass',
      price: 50,
      description: 'A high-quality glass for everyday use.',
      rating: 4.0,
      imageUrl: 'https://media.istockphoto.com/id/467521964/photo/isolated-shot-of-disposable-coffee-cup-on-white-background.jpg?s=2048x2048&w=is&k=20&c=CpgJrxWRGtA7ID1IBqAv21o6GTAa1EJOmA2v39rgMq0=',
    ),
    Product(
      name: 'Paper',
      price: 25,
      description: 'Recycled paper for all your writing needs.',
      rating: 4.8,
      imageUrl: 'https://cdn.pixabay.com/photo/2024/01/15/20/51/plate-8510868_1280.jpg',
    ),
    // Add more products as needed
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
              ),
            ),
            Spacer(),
            Row(
              children: [
                Icon(
                  Icons.currency_bitcoin_outlined,
                  color: Colors.yellow,
                  size: 30.0,
                ),
                SizedBox(width: 8.0), // Add space between icon and text
                Text(
                  "200 Pts",
                  style: TextStyle(
                    color: Colors.white, // Ensures text is readable
                    fontWeight: FontWeight.bold, // Adjust size as needed
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.green, // Green background color
      ),
      // title: Text('Cart'),
      // backgroundColor: Colors.green,

      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              contentPadding: const EdgeInsets.all(8.0),
              leading: Image.network(
                product.imageUrl,
                width: 125,
                height: 160,
                fit: BoxFit.cover,
              ),
              title: Text(product.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\$${product.price.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  Text(product.description),
                  const SizedBox(height: 4),
                  Text('Rating: ${product.rating.toStringAsFixed(1)} ★'),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  // Implement the "Buy Now" functionality here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Buy Now'),
              ),
            ),
          );
        },
      ),
    );
  }
}

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


// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Cart(),
//     );
//   }
// }
//
// class Cart extends StatelessWidget {
//   final List<Product> products = [
//     Product(
//       name: 'Plant',
//       price: 200 ,
//         imageUrl: 'https://via.placeholder.com/150?text=Product+1',
//     ),
//
//     Product(
//       name: 'Glass',
//       price: 50,
//       imageUrl: 'https://via.placeholder.com/150?text=Product+2',
//     ),
//     Product(
//       name: 'Paper',
//       price: 25,
//       imageUrl: 'https://via.placeholder.com/150?text=Product+3',
//     ),
//     // Add more products as needed
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Cart'),
//         backgroundColor: Colors.green,
//       ),
//       body: ListView.builder(
//         itemCount: products.length,
//         itemBuilder: (context, index) {
//           final product = products[index];
//           return Card(
//             margin: EdgeInsets.all(8.0),
//             child: ListTile(
//               contentPadding: EdgeInsets.all(8.0),
//               leading: CachedNetworkImage(
//                 imageUrl: product.imageUrl,
//                 placeholder: (context, url) => CircularProgressIndicator(),
//                 errorWidget: (context, url, error) => Icon(Icons.error),
//                 width: 100,
//                 height: 100,
//                 fit: BoxFit.cover,
//               ),
//               title: Text(product.name),
//               subtitle: Text('\~${product.price.toStringAsFixed(2)}'),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class Product {
//   final String name;
//   final double price;
//   final String imageUrl;
//
//   Product({
//     required this.name,
//     required this.price,
//     required this.imageUrl,
//   });
// }
//
//
//
//
