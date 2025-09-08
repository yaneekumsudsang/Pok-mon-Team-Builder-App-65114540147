import 'package:flutter/material.dart';

class Detail extends StatefulWidget {
  const Detail({super.key});

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('This is the detail page'),
            SizedBox(height: 16),
            Hero(
              tag: 'logo-hero',
              transitionOnUserGestures: true,
              child: Image(
                image: AssetImage('images/logo.png'),
                width: 200,
                height: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}