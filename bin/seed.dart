// bin/seed.dart
import 'dart:async';
import 'dart:math';

import 'package:pocketbase/pocketbase.dart';
import 'package:faker/faker.dart';

Future<void> main() async {
  final pb = PocketBase('http://127.0.0.1:8090'); // เปลี่ยนถ้ารันบน host/port อื่น
  final adminEmail = 'yanee.ku.65@ubu.ac.th';
  final adminPassword = '0658714672';

  try {
    print('Authenticating as admin...');
    await pb.admins.authWithPassword(adminEmail, adminPassword);
    print('Authenticated: ${pb.authStore.isValid}');

    // ตรวจสอบว่าคอลเลกชัน product มีอยู่จริง (ถ้าไม่มีก็จะ error)
    final collectionName = 'product';
    final check = await pb.collection(collectionName).getList(perPage: 1);
    print('Collection "$collectionName" reachable. Existing items: ${check.totalItems}');

    final faker = Faker();
    final rand = Random();

    const total = 100;
    final batchSize = 10; // สร้างเป็นชุดเพื่อไม่ให้ท่วม server
    for (var offset = 0; offset < total; offset += batchSize) {
      final futures = <Future>[];
      final end = (offset + batchSize).clamp(0, total);
      for (var i = offset; i < end; i++) {
        final name = faker.food.dish(); // ชื่อสินค้า
        final price = (rand.nextInt(490) + 10); // 10 - 499
        final imageUrl = 'https://picsum.photos/seed/product_$i/600/400';

        final body = {
          'name': name,
          'price': price.toString(), // หากฟิลด์ของคุณเป็น number ให้ใส่ int (PocketBase รับได้ทั้ง)
          'imageUrl': imageUrl,
        };

        futures.add(_createRecord(pb, collectionName, body, i + 1));
      }

      // รอให้ชุดนี้เสร็จแล้วค่อยสร้างชุดถัดไป
      await Future.wait(futures);
      print('Created items ${offset + 1}..$end');
    }

    print('Seeding finished.');
  } catch (e, st) {
    print('Error: $e\n$st');
  } finally {
    pb.authStore.clear();
  }
}

Future<void> _createRecord(PocketBase pb, String collection, Map<String, dynamic> body, int index) async {
  try {
    final rec = await pb.collection(collection).create(body: body);
    print('[$index] created id=${rec.id}');
  } catch (e) {
    print('Failed to create [$index]: $e');
  }
}
