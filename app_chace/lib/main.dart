import 'package:app_chace/LRUCache.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text('LRU Cache em Flutter')),
        body: CacheExample(),
      ),
    );
  }
}

class CacheExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cache = LRUCache<String, String>(3); // Limite do cache = 3

    // Adicionando itens ao cache
    cache.put('1', 'Item 1');
    cache.put('2', 'Item 2');
    cache.put('3', 'Item 3');
    cache.put('4', 'Item 4'); // 'Item 1' será removido

    // Acessando os itens do cache
    final item1 = cache.get('1'); // Deve ser null, porque foi removido
    final item2 = cache.get('2'); // Deve ser 'Item 2'
    final item3 = cache.get('3'); // Deve ser 'Item 3'
    final item4 = cache.get('4'); // Deve ser 'Item 4'

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Item 1: $item1'), // Espera-se null
        Text('Item 2: $item2'),
        Text('Item 3: $item3'),
        Text('Item 4: $item4'),
      ],
    );
  }
}
