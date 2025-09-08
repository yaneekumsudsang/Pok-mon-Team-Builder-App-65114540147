import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

// --- โมเดลสำหรับโปเกมอน ---
class Poke {
  final int id;
  final String name;
  const Poke(this.id, this.name);

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String get displayNo => id.toString().padLeft(4, '0');

  // แปลง Object เป็น Map เพื่อบันทึกลง Storage
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  // สร้าง Object จาก Map ที่อ่านจาก Storage
  static Poke fromMap(Map<String, dynamic> map) {
    return Poke(map['id'], map['name']);
  }
}

// --- โมเดลสำหรับทีม ---
class Team {
  final String name;
  final List<Poke> pokemons;

  Team({required this.name, required this.pokemons});

  // แปลง Object เป็น Map เพื่อบันทึกลง Storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pokemons': pokemons.map((p) => p.toMap()).toList(),
    };
  }

  // สร้าง Object จาก Map ที่อ่านจาก Storage
  static Team fromMap(Map<String, dynamic> map) {
    return Team(
      name: map['name'],
      pokemons: (map['pokemons'] as List)
          .map((p) => Poke.fromMap(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

// --- หน้าหลักสำหรับเลือกโปเกมอน ---
class SelectPage extends StatefulWidget {
  const SelectPage({super.key});

  @override
  State<SelectPage> createState() => _SelectPageState();
}

class _SelectPageState extends State<SelectPage> with TickerProviderStateMixin {
  // Key สำหรับบันทึกข้อมูลใน GetStorage
  static const _teamNameKey = 'team_name';
  static const _selectedPokemonKey = 'selected_pokemons';
  static const _allTeamsKey = 'all_teams';
  final _box = GetStorage();

  String _teamName = 'My Team';
  final List<Poke> _pokemons = [];
  final List<Poke> _selectedTeam = [];
  bool _loading = true;
  String? _error;

  final _searchController = TextEditingController();
  List<Poke> _filteredPokemons = [];

  late AnimationController _fabAnimationController;
  late AnimationController _chipAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _chipAnimation;

  @override
  void initState() {
    super.initState();
    _teamName = _box.read<String>(_teamNameKey) ?? 'My Team';
    
    // Animation controllers
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _chipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
    _chipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chipAnimationController, curve: Curves.easeInOut),
    );

    _loadPokemon().then((_) {
      _loadSelectedPokemons();
      _filterPokemons();
      _chipAnimationController.forward();
    });

    _searchController.addListener(_filterPokemons);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    _chipAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPokemon({int limit = 151}) async {
    try {
      setState(() { _loading = true; _error = null; });
      final res = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=$limit'));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List).cast<Map<String, dynamic>>();
      final reg = RegExp(r'/pokemon/(\d+)/?$');

      final list = <Poke>[];
      for (final item in results) {
        final url = item['url'] as String;
        final m = reg.firstMatch(url);
        if (m != null) {
          final id = int.parse(m.group(1)!);
          final name = _titleCase(item['name'] as String);
          list.add(Poke(id, name));
        }
      }

      setState(() { 
        _pokemons..clear()..addAll(list); 
        _loading = false; 
      });
      _fabAnimationController.forward();
    } catch (e) {
      setState(() { _error = 'โหลดข้อมูลไม่สำเร็จ: $e'; _loading = false; });
    }
  }

  static String _titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _loadSelectedPokemons() {
    final storedMaps = _box.read<List<dynamic>>(_selectedPokemonKey) ?? [];
    setState(() {
      _selectedTeam.clear();
      for (var map in storedMaps) {
        if (map is Map<String, dynamic>) {
          _selectedTeam.add(Poke.fromMap(map));
        }
      }
    });
  }

  void _saveSelectedPokemons() {
    final listToSave = _selectedTeam.map((p) => p.toMap()).toList();
    _box.write(_selectedPokemonKey, listToSave);
  }

  Future<void> _saveCurrentTeamToAllTeams() async {
    final currentTeam = Team(name: _teamName, pokemons: List.from(_selectedTeam));

    final allTeamsData = _box.read<List<dynamic>>(_allTeamsKey) ?? [];
    final allTeams = allTeamsData
      .map((teamData) => Team.fromMap(teamData as Map<String, dynamic>))
      .toList();

    allTeams.add(currentTeam);

    final listToSave = allTeams.map((team) => team.toMap()).toList();
    await _box.write(_allTeamsKey, listToSave);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('บันทึกทีม "$_teamName" สำเร็จ!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
    }

    _resetTeam();
  }

  void _resetTeam() {
    setState(() {
      _selectedTeam.clear();
    });
    _saveSelectedPokemons();
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.white),
              SizedBox(width: 8),
              Text('ทีมปัจจุบันถูกรีเซ็ตแล้ว!'),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
    }
  }

  void _toggle(int index) {
    setState(() {
      final pokemonToToggle = _pokemons[index];
      final isSelected = _selectedTeam.any((p) => p.id == pokemonToToggle.id);
      if (isSelected) {
        _selectedTeam.removeWhere((p) => p.id == pokemonToToggle.id);
      } else {
        if (_selectedTeam.length < 3) {
          _selectedTeam.add(pokemonToToggle);
        }
      }
      _saveSelectedPokemons();
    });
  }

  void _filterPokemons() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPokemons = _pokemons.where((poke) {
        return poke.name.toLowerCase().contains(query) ||
               poke.id.toString().contains(query);
      }).toList();
    });
  }

  bool _isPokemonSelected(Poke pokemon) {
    return _selectedTeam.any((p) => p.id == pokemon.id);
  }

  Future<void> _editTeamName() async {
    final controller = TextEditingController(text: _teamName);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 12),
            const Text('แก้ไขชื่อทีม'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: InputDecoration(
            hintText: 'My Awesome Team',
            labelText: 'ชื่อทีม',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            prefixIcon: const Icon(Icons.sports_esports),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final trimmedName = controller.text.trim();
              Navigator.pop(context, trimmedName.isEmpty ? _teamName : trimmedName);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (newName != null && newName != _teamName) {
      setState(() => _teamName = newName);
      await _box.write(_teamNameKey, _teamName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('บันทึกชื่อทีมแล้ว'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reachedLimit = _selectedTeam.length >= 3;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _teamName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade600,
                        Colors.purple.shade500,
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    tooltip: 'แก้ชื่อทีม',
                    onPressed: _editTeamName,
                    icon: const Icon(Icons.edit, color: Colors.white),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    tooltip: 'ดูทีมทั้งหมด',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AllTeamsPage()),
                      );
                    },
                    icon: const Icon(Icons.shield_outlined, color: Colors.white),
                  ),
                ),
              ],
            ),
            // Correctly use conditional spread operator inside the list
            if (_loading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'กำลังโหลด Pokémon...',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, 
                          color: Colors.red.shade600, 
                          size: 48
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!, 
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadPokemon,
                          icon: const Icon(Icons.refresh),
                          label: const Text('ลองใหม่'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24, 
                              vertical: 12
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              // Search Bar
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ค้นหา Pokémon...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search, color: Colors.blue.shade600),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _filterPokemons();
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),

              // Selected Pokemon Chips
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _chipAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _chipAnimation.value,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.groups, color: Colors.blue.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'ทีมของคุณ (${_selectedTeam.length}/3)',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (_selectedTeam.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8.0),
                                      child: ActionChip(
                                        label: const Text('รีเซ็ตทีม'),
                                        avatar: const Icon(Icons.refresh, size: 18),
                                        backgroundColor: Colors.red.shade50,
                                        side: BorderSide(color: Colors.red.shade200),
                                        labelStyle: TextStyle(color: Colors.red.shade700),
                                        onPressed: _resetTeam,
                                      ),
                                    ),
                                  ..._selectedTeam.map((p) {
                                    final indexInPokemons = _pokemons.indexWhere((poke) => poke.id == p.id);
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Chip(
                                        avatar: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                spreadRadius: 1,
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            backgroundImage: NetworkImage(p.imageUrl),
                                            backgroundColor: Colors.white,
                                          ),
                                        ),
                                        label: Text(
                                          '${p.displayNo} ${p.name}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        backgroundColor: Colors.amber.shade50,
                                        side: BorderSide(color: Colors.amber.shade200),
                                        deleteIcon: const Icon(Icons.close, size: 18),
                                        onDeleted: () => _toggle(indexInPokemons),
                                      ),
                                    );
                                  }).toList(),
                                  if (_selectedTeam.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16, 
                                        vertical: 8
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_circle_outline, 
                                            color: Colors.grey.shade600,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'ยังไม่ได้เลือก Pokémon',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Pokemon Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = _filteredPokemons[i];
                      final isChecked = _isPokemonSelected(p);
                      final indexInPokemons = _pokemons.indexWhere((poke) => poke.id == p.id);
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isChecked ? 0.3 : 0.1),
                              spreadRadius: isChecked ? 3 : 1,
                              blurRadius: isChecked ? 12 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isChecked
                                ? [Colors.amber.shade300, Colors.orange.shade400]
                                : [Colors.white, Colors.grey.shade50],
                          ),
                          border: Border.all(
                            color: isChecked 
                                ? Colors.amber.shade600 
                                : Colors.grey.shade200,
                            width: isChecked ? 3 : 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: (!isChecked && reachedLimit) ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('เลือกได้สูงสุด 3 ตัวเท่านั้น!'),
                                    ],
                                  ),
                                  backgroundColor: Colors.orange.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                ),
                              );
                            } : () => _toggle(indexInPokemons),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Pokemon Image
                                  Expanded(
                                    flex: 3,
                                    child: Image.network(
                                      p.imageUrl,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Pokemon Number
                                  Text(
                                    p.displayNo,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Pokemon Name
                                  Text(
                                    p.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _filteredPokemons.length,
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 100, // เพิ่มพื้นที่ด้านล่าง
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _selectedTeam.isEmpty
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
              ),
              child: ScaleTransition(
                scale: _fabAnimation,
                child: ElevatedButton.icon(
                  onPressed: _saveCurrentTeamToAllTeams,
                  icon: const Icon(Icons.save_alt),
                  label: Text(
                    'บันทึกทีม (${_selectedTeam.length}/3)',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// --- หน้าสำหรับแสดงทีมทั้งหมด ---
class AllTeamsPage extends StatefulWidget {
  const AllTeamsPage({super.key});

  @override
  State<AllTeamsPage> createState() => _AllTeamsPageState();
}

class _AllTeamsPageState extends State<AllTeamsPage> {
  final _box = GetStorage();
  static const _allTeamsKey = 'all_teams';
  final List<Team> _allTeams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllTeams();
  }

  void _loadAllTeams() {
    setState(() {
      _isLoading = true;
    });
    try {
      final allTeamsData = _box.read<List<dynamic>>(_allTeamsKey) ?? [];
      final teams = allTeamsData
          .map((teamData) => Team.fromMap(teamData as Map<String, dynamic>))
          .toList();
      setState(() {
        _allTeams.clear();
        _allTeams.addAll(teams);
      });
    } catch (e) {
      // จัดการข้อผิดพลาด เช่น data corruption
      print('Failed to load teams: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteTeam(int index) async {
    setState(() {
      _allTeams.removeAt(index);
    });
    final listToSave = _allTeams.map((team) => team.toMap()).toList();
    await _box.write(_allTeamsKey, listToSave);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ลบทีมสำเร็จ')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทีมทั้งหมด'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allTeams.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'ยังไม่มีทีมที่บันทึกไว้',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _allTeams.length,
                  itemBuilder: (context, index) {
                    final team = _allTeams[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: ListTile(
                        title: Text(team.name),
                        subtitle: Text(
                          team.pokemons.map((p) => p.name).join(', '),
                        ),
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            team.pokemons.first.imageUrl,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTeam(index),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
