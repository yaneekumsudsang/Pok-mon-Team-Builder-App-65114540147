import 'package:flutter/material.dart';
import 'package:myapp/page/select.dart';
import 'package:myapp/page/detail.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _goToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Detail()),
    );
  }

  void _incrementCounter() {
    setState(() => _counter++);
    _goToDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment & Go',
        heroTag: 'logo-hero',
        child: Image.asset('images/logo.png'),
      ),
    );
  }
}