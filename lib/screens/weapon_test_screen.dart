import 'package:flutter/material.dart';
import '../models/weapon.dart';

class WeaponTestScreen extends StatefulWidget {
  const WeaponTestScreen({super.key});

  @override
  State<WeaponTestScreen> createState() => _WeaponTestScreenState();
}

class _WeaponTestScreenState extends State<WeaponTestScreen> {
  List<Weapon> _weapons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeapons();
  }

  Future<void> _loadWeapons() async {
    setState(() => _isLoading = true);
    _weapons = await Weapon.loadAll();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'ОРУЖИЕ',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 16,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 200, 180, 100),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _weapons.length,
              itemBuilder: (context, index) {
                final weapon = _weapons[index];
                return Card(
                  color: const Color.fromARGB(255, 20, 20, 20),
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    leading: Text(
                      weapon.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Row(
                      children: [
                        Text(
                          weapon.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: weapon.rarityColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(
                              color: weapon.rarityColor,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            weapon.rarityName,
                            style: TextStyle(
                              color: weapon.rarityColor,
                              fontSize: 10,
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          weapon.description,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _buildChip(
                              '⚔️ ${weapon.damage}',
                              Colors.red[500]!,
                            ),
                            _buildChip(
                              '💪 ${weapon.requiredStrength}',
                              Colors.orange[500]!,
                            ),
                            _buildChip(
                              '⚖️ ${weapon.weight} кг',
                              Colors.grey[400]!,
                            ),
                            _buildChip(
                              '🛡️ ${weapon.durability}',
                              Colors.blue[500]!,
                            ),
                            if (weapon.ammoType != null)
                              _buildChip(
                                '🔫 ${weapon.ammoType}',
                                Colors.green[500]!,
                              ),
                          ],
                        ),
                        if (weapon.specialAbility != 'Нет')
                          const SizedBox(height: 4),
                        if (weapon.specialAbility != 'Нет')
                          Text(
                            '✨ ${weapon.specialAbility}',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 200, 180, 100),
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
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadWeapons,
        backgroundColor: const Color.fromARGB(255, 200, 180, 100),
        foregroundColor: Colors.black,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontFamily: 'RobotoMono',
        ),
      ),
    );
  }
}
