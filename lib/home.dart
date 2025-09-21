import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pocketbase/pocketbase.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stockQuantity;
  final String category;
  final String imageUrl;
  final String brand;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.category,
    required this.imageUrl,
    required this.brand,
    required this.rating,
  });

  /// แปลงจาก PocketBase RecordModel -> Product
  factory Product.fromRecord(RecordModel r) {
    final d = r.data;

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return Product(
      id: r.id,
      name: (d['name'] ?? '').toString(),
      description: (d['description'] ?? '').toString(),
      price: _toDouble(d['price']),
      stockQuantity: _toInt(d['stockQuantity'] ?? d['stock_quantity']),
      category: (d['category'] ?? '').toString(),
      imageUrl: (d['imageUrl'] ?? d['image_url'] ?? '').toString(),
      brand: (d['brand'] ?? '').toString(),
      rating: _toDouble(d['rating']),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// เปลี่ยน URL ให้ตรงกับที่คุณรัน PocketBase
  final PocketBase pb = PocketBase('http://127.0.0.1:8090');

  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;
  String? error;
  String searchQuery = '';
  String selectedCategory = 'ทั้งหมด';

  final categories = const [
    {'icon': Icons.phone_android, 'label': 'มือถือ'},
    {'icon': Icons.checkroom, 'label': 'แฟชั่น'},
    {'icon': Icons.tv, 'label': 'เครื่องใช้ไฟฟ้า'},
    {'icon': Icons.sports_esports, 'label': 'เกม'},
    {'icon': Icons.kitchen, 'label': 'ของใช้ในบ้าน'},
    {'icon': Icons.computer, 'label': 'คอมพิวเตอร์'},
    {'icon': Icons.child_care, 'label': 'เด็ก'},
    {'icon': Icons.local_cafe, 'label': 'เครื่องดื่ม'},
    {'icon': Icons.book, 'label': 'หนังสือ'},
    {'icon': Icons.headset, 'label': 'อุปกรณ์เสริม'},
    {'icon': Icons.bolt, 'label': 'อุปกรณ์ไฟฟ้า'},
    {'icon': Icons.beach_access, 'label': 'ท่องเที่ยว'},
    {'icon': Icons.sports_basketball, 'label': 'กีฬา'},
    {'icon': Icons.pets, 'label': 'สัตว์เลี้ยง'},
    {'icon': Icons.more_horiz, 'label': 'อื่นๆ'},
  ];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // ตรวจสุขภาพเซิร์ฟเวอร์ (optional)
      await pb.health.check();

      final resultList = await pb.collection('product').getList(
        page: 1,
        perPage: 100,
        sort: '-created',
      );

      final loaded = resultList.items.map(Product.fromRecord).toList();

      setState(() {
        products = loaded;
        filteredProducts = loaded;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void filterProducts() {
    setState(() {
      filteredProducts = products.where((p) {
        final q = searchQuery.trim().toLowerCase();
        final matchesSearch = q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q);

        final matchesCategory =
            selectedCategory == 'ทั้งหมด' || p.category == selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void onCategorySelected(String category) {
    selectedCategory = category;
    filterProducts();
  }

  void onSearchChanged(String query) {
    searchQuery = query;
    filterProducts();
  }

  // --------------------- CRUD ---------------------

  Future<void> createProduct() async {
    final data = await _openProductDialog();
    if (data == null) return;

    final priceNum = double.tryParse(data['price']!) ?? 0.0;

    await pb.collection('product').create(body: {
      'name': data['name'],
      'price': priceNum,         // ใน PB เป็น number → ส่งเป็น number
      'imageUrl': data['imageUrl'],
    });

    await loadProducts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สร้างสินค้าแล้ว')),
      );
    }
  }

  Future<void> updateProduct(Product p) async {
    final data = await _openProductDialog(initial: p);
    if (data == null) return;

    final priceNum = double.tryParse(data['price']!) ?? 0.0;

    await pb.collection('product').update(p.id, body: {
      'name': data['name'],
      'price': priceNum,
      'imageUrl': data['imageUrl'],
    });

    await loadProducts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตสินค้าแล้ว')),
      );
    }
  }

  Future<void> deleteProduct(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบสินค้า'),
        content: Text('ลบ “${p.name}” ใช่ไหม?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (ok == true) {
      await pb.collection('product').delete(p.id);
      await loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบสินค้าแล้ว')),
        );
      }
    }
  }

  /// ฟอร์มเดียวใช้ทั้ง Create/Update (บันทึกเฉพาะ name/price/imageUrl)
  Future<Map<String, String>?> _openProductDialog({Product? initial}) {
    final nameCtrl  = TextEditingController(text: initial?.name ?? '');
    final priceCtrl = TextEditingController(text: initial?.price.toString() ?? '');
    final imageCtrl = TextEditingController(text: initial?.imageUrl ?? '');

    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(initial == null ? 'Create Product' : 'Update Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'Image URL')),
              const SizedBox(height: 4),
              const Text(
                'บันทึกเฉพาะ name, price, imageUrl (ฟิลด์อื่นจะแสดงได้ถ้ามีใน PB)',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = priceCtrl.text.trim();
              final image = imageCtrl.text.trim();
              if (name.isEmpty || price.isEmpty || image.isEmpty) return;
              Navigator.pop(context, {'name': name, 'price': price, 'imageUrl': image});
            },
            child: Text(initial == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final banners = [
      Colors.orange[200],
      Colors.orange[300],
      Colors.orange[400],
    ];

    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, color: Colors.white, size: 32),
                      const SizedBox(width: 8),
                      const Text(
                        'DSSI Shop',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        tooltip: 'Create',
                        onPressed: createProduct,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: loadProducts,
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ยังไม่มีการแจ้งเตือนใหม่')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาสินค้า...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.orange[400],
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadProducts,
        child: ListView(
          children: [
            // Banner
            SizedBox(
              height: 140,
              child: PageView.builder(
                itemCount: banners.length,
                controller: PageController(viewportFraction: 0.9),
                itemBuilder: (context, index) => Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: banners[index],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      'โปรโมชันพิเศษ ${index + 1}',
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Category chips
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FilterChip(
                    label: const Text('ทั้งหมด'),
                    selected: selectedCategory == 'ทั้งหมด',
                    onSelected: (_) => onCategorySelected('ทั้งหมด'),
                    selectedColor: Colors.orange[200],
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat['label'] as String),
                          selected: selectedCategory == cat['label'],
                          onSelected: (_) =>
                              onCategorySelected(cat['label'] as String),
                          selectedColor: Colors.orange[200],
                        ),
                      )),
                ],
              ),
            ),

            // Horizontal category nav
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 18),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = selectedCategory == cat['label'];
                  return GestureDetector(
                    onTap: () => onCategorySelected(cat['label'] as String),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              isSelected ? Colors.orange : Colors.orange[200],
                          radius: 28,
                          child: Icon(
                            cat['icon'] as IconData,
                            color:
                                isSelected ? Colors.white : Colors.deepOrange,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            color:
                                isSelected ? Colors.orange : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // States
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(50),
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              )
            else if (error != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'เกิดข้อผิดพลาด',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('$error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loadProducts,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),
              )
            else if (filteredProducts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(50),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'ไม่พบสินค้าที่ค้นหา',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.grid_view,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'สินค้าทั้งหมด (${filteredProducts.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final p = filteredProducts[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // เนื้อการ์ด
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // image
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  child: CachedNetworkImage(
                                    imageUrl: p.imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.orange),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image_not_supported,
                                          size: 50, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // info
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p.brand,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            color: Colors.amber, size: 14),
                                        Text(
                                          p.rating.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'คงเหลือ ${p.stockQuantity}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '฿${p.price.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 28,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'เพิ่ม ${p.name} ในตะกร้า'),
                                                  duration:
                                                      const Duration(seconds: 2),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'ซื้อ',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ปุ่มแก้ไข/ลบ มุมขวาบน
                        Positioned(
                          top: 4,
                          right: 4,
                          child: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') {
                                updateProduct(p);
                              } else if (v == 'delete') {
                                deleteProduct(p);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                            icon: const Icon(Icons.more_vert, size: 20),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Divider(),
                  const Text('ติดต่อเรา: support@dssishop.com | 02-xxx-xxxx'),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.facebook, color: Colors.blue),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.purple),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.alternate_email,
                            color: Colors.blueAccent),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('© 2024 DSSI Shop | เงื่อนไขการใช้งาน'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'chat',
            backgroundColor: Colors.orange,
            child: const Icon(Icons.chat),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('เปิดแชทกับผู้ขาย')),
              );
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'share',
            backgroundColor: Colors.orange[300],
            child: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('แชร์หน้านี้')),
              );
            },
          ),
        ],
      ),
    );
  }
}