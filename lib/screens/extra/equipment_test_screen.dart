import 'package:flutter/material.dart';
import 'package:dark_hours/models/items/weapon.dart';
import 'package:dark_hours/models/items/tool.dart';
import 'package:dark_hours/models/items/consumable.dart';
import 'package:dark_hours/models/items/armor.dart';
import 'package:dark_hours/models/items/resource.dart';
import 'package:dark_hours/models/items/recipe.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

class EquipmentTestScreen extends StatefulWidget {
  const EquipmentTestScreen({super.key});

  @override
  State<EquipmentTestScreen> createState() => _EquipmentTestScreenState();
}

class _EquipmentTestScreenState extends State<EquipmentTestScreen> {
  List<Weapon> _weapons = [];
  List<Tool> _tools = [];
  List<Consumable> _consumables = [];
  List<Armor> _armor = [];
  List<GameResource> _resources = [];
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Если пришли из меню — menu_theme уже играет
    AudioService.playMusic('audio/music/menu_theme.mp3');
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final weapons = await Weapon.loadAll();
    final tools = await Tool.loadAll();
    final consumables = await Consumable.loadAll();
    final armor = await Armor.loadAll();
    final resources = await GameResource.loadAll();
    final recipes = await Recipe.loadAll();
    setState(() {
      _weapons = weapons;
      _tools = tools;
      _consumables = consumables;
      _armor = armor;
      _resources = resources;
      _recipes = recipes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 10, 10, 10),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              AudioService.playClick();
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'СНАРЯЖЕНИЕ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: const Color.fromARGB(255, 200, 180, 100),
            labelColor: const Color.fromARGB(255, 200, 180, 100),
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(text: '🗡️ Оружие (${_weapons.length})'),
              Tab(text: '🔧 Инстр. (${_tools.length})'),
              Tab(text: '🍞 Расход. (${_consumables.length})'),
              Tab(text: '🦺 Броня (${_armor.length})'),
              Tab(text: '🪵 Ресурсы (${_resources.length})'),
              Tab(text: '⚙️ Рецепты (${_recipes.length})'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 200, 180, 100),
                ),
              )
            : TabBarView(
                children: [
                  _buildWeaponList(),
                  _buildToolList(),
                  _buildConsumableList(),
                  _buildArmorList(),
                  _buildResourceList(),
                  _buildRecipeList(),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            AudioService.playClick();
            _loadData();
          },
          backgroundColor: const Color.fromARGB(255, 200, 180, 100),
          foregroundColor: Colors.black,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  // ====== ОРУЖИЕ ======
  Widget _buildWeaponList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _weapons.length,
      itemBuilder: (context, index) {
        final w = _weapons[index];
        return Card(
          color: const Color.fromARGB(255, 20, 20, 20),
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: Text(w.icon, style: const TextStyle(fontSize: 32)),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    w.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRarityBadge(w.rarityColor, w.rarityName),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  w.description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildChip('⚔️ ${w.damage}', Colors.red[500]!),
                    _buildChip('💪 ${w.requiredStrength}', Colors.orange[500]!),
                    _buildChip('⚖️ ${w.weight} кг', Colors.grey[400]!),
                    _buildChip('🛡️ ${w.durability}', Colors.blue[500]!),
                    if (w.ammoType != null)
                      _buildChip('🔫 ${w.ammoType}', Colors.green[500]!),
                    _buildChip('📦 ${w.typeName}', Colors.purple[300]!),
                  ],
                ),
                if (w.specialAbility != 'Нет') ...[
                  const SizedBox(height: 4),
                  Text(
                    '✨ ${w.specialAbility}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 200, 180, 100),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // ====== ИНСТРУМЕНТЫ ======
  Widget _buildToolList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _tools.length,
      itemBuilder: (context, index) {
        final t = _tools[index];
        return Card(
          color: const Color.fromARGB(255, 20, 20, 20),
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: Text(t.icon, style: const TextStyle(fontSize: 32)),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    t.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRarityBadge(t.rarityColor, t.rarityName),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  t.description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildChip('⚖️ ${t.weight} кг', Colors.grey[400]!),
                    _buildChip('🛡️ ${t.durability}', Colors.blue[500]!),
                    _buildChip('📦 ${t.typeName}', Colors.purple[300]!),
                    _buildChip('🎯 ${t.uses} раз', Colors.orange[500]!),
                    if (t.fuelRequired == true)
                      _buildChip('⛽ Топливо', Colors.red[500]!),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '✨ ${t.specialAbility}',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 200, 180, 100),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // ====== РАСХОДНИКИ ======
  Widget _buildConsumableList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _consumables.length,
      itemBuilder: (context, index) {
        final c = _consumables[index];
        return Card(
          color: const Color.fromARGB(255, 20, 20, 20),
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: Text(c.icon, style: const TextStyle(fontSize: 32)),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    c.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRarityBadge(c.rarityColor, c.rarityName),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  c.description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (c.hungerRestore > 0)
                      _buildChip('🍞 +${c.hungerRestore}', Colors.orange[500]!),
                    if (c.thirstRestore > 0)
                      _buildChip('💧 +${c.thirstRestore}', Colors.blue[400]!),
                    if (c.healthRestore > 0)
                      _buildChip('❤️ +${c.healthRestore}', Colors.red[500]!),
                    if (c.sanityRestore > 0)
                      _buildChip('🧠 +${c.sanityRestore}', Colors.purple[300]!),
                    if (c.hungerRestore < 0)
                      _buildChip('🍞 ${c.hungerRestore}', Colors.grey[500]!),
                    if (c.thirstRestore < 0)
                      _buildChip('💧 ${c.thirstRestore}', Colors.grey[500]!),
                    if (c.healthRestore < 0)
                      _buildChip('❤️ ${c.healthRestore}', Colors.grey[500]!),
                    if (c.sanityRestore < 0)
                      _buildChip('🧠 ${c.sanityRestore}', Colors.grey[500]!),
                    _buildChip('⚖️ ${c.weight} кг', Colors.grey[400]!),
                    _buildChip('📦 ${c.categoryName}', Colors.purple[300]!),
                    if (c.spoilDays > 0)
                      _buildChip('⏳ ${c.spoilDays} дн.', Colors.red[400]!),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // ====== БРОНЯ ======
  Widget _buildArmorList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _armor.length,
      itemBuilder: (context, index) {
        final a = _armor[index];
        return Card(
          color: const Color.fromARGB(255, 20, 20, 20),
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: Text(a.icon, style: const TextStyle(fontSize: 32)),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    a.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRarityBadge(a.rarityColor, a.rarityName),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  a.description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildChip('🛡️ ${a.protection}', Colors.blue[400]!),
                    _buildChip('🔥 ${a.warmth}', Colors.orange[400]!),
                    _buildChip('⚖️ ${a.weight} кг', Colors.grey[400]!),
                    _buildChip('💪 ${a.durability}', Colors.green[500]!),
                    _buildChip('📍 ${a.slotName}', Colors.purple[300]!),
                    if (a.extraSlots != null)
                      _buildChip('🎒 +${a.extraSlots} кг', Colors.teal[300]!),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // ====== РЕСУРСЫ ======
  Widget _buildResourceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _resources.length,
      itemBuilder: (context, index) {
        final r = _resources[index];
        return Card(
          color: const Color.fromARGB(255, 20, 20, 20),
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: Text(r.icon, style: const TextStyle(fontSize: 32)),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    r.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRarityBadge(r.rarityColor, r.rarityName),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  r.description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildChip('⚖️ ${r.weight} кг', Colors.grey[400]!),
                    _buildChip('📦 x${r.stackMax}', Colors.orange[400]!),
                    _buildChip('🏷️ ${r.categoryName}', Colors.purple[300]!),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // ====== РЕЦЕПТЫ ======
  Widget _buildRecipeList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _recipes.length,
      itemBuilder: (context, index) {
        final r = _recipes[index];
        return Card(
          color: const Color.fromARGB(255, 20, 20, 20),
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: Text(r.resultIcon, style: const TextStyle(fontSize: 32)),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    r.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRarityBadge(r.rarityColor, r.rarityName),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  r.description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '🧪 Ингредиенты:',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                ...r.ingredients.map(
                  (i) => Text(
                    '  • ${i.id} × ${i.count}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildChip('⏱️ ${r.timeMinutes} мин', Colors.orange[400]!),
                    _buildChip('🧠 ${r.requiredIntelligence}', Colors.blue[400]!),
                    _buildChip('💪 ${r.requiredStrength}', Colors.red[400]!),
                    _buildChip('🏷️ ${r.categoryName}', Colors.purple[300]!),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // ====== ОБЩИЕ ЭЛЕМЕНТЫ ======
  Widget _buildRarityBadge(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color, width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10),
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color.withOpacity(0.5), width: 1.0),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}