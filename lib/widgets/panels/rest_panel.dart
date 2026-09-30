import 'package:flutter/material.dart';
import 'package:dark_hours/models/time/rest_action.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

class RestPanel extends StatelessWidget {
  final Function(RestAction) onRest;
  final bool isSafeLocation;

  const RestPanel({
    super.key,
    required this.onRest,
    required this.isSafeLocation,
  });

  Color _riskColor(String risk) {
    switch (risk) {
      case 'safe':
        return Colors.green;
      case 'low':
        return Colors.lightGreen;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _riskName(String risk) {
    switch (risk) {
      case 'safe':
        return 'Безопасно';
      case 'low':
        return 'Низкий риск';
      case 'medium':
        return 'Средний риск';
      case 'high':
        return 'Высокий риск';
      default:
        return risk;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 15, 15, 15),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              const Icon(
                Icons.hotel,
                color: Color.fromARGB(255, 200, 180, 100),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'ОТДЫХ',
                style: TextStyle(
                  color: Color.fromARGB(255, 200, 180, 100),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSafeLocation
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSafeLocation ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Text(
                  isSafeLocation ? '🏠 БЕЗОПАСНО' : '⚠️ ОПАСНО',
                  style: TextStyle(
                    color: isSafeLocation ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSafeLocation
                ? 'Здесь можно спокойно отдохнуть.'
                : 'Здесь спать рискованно. Могут ограбить или напасть.',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Варианты отдыха
          ...RestAction.all.map((action) => _buildRestCard(context, action)),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildRestCard(BuildContext context, RestAction action) {
    // В опасной локации — риск увеличивается
    final effectiveRisk = isSafeLocation
        ? (action.riskLevel == 'high' ? 'medium' : 'low')
        : action.riskLevel;

    final riskColor = _riskColor(effectiveRisk);

    return GestureDetector(
      onTap: () {
        AudioService.playTap();
        onRest(action);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 25, 25, 25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: riskColor.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(action.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: riskColor, width: 1),
                  ),
                  child: Text(
                    _riskName(effectiveRisk),
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              action.description,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildEffectChip(
                  '⏱️ ${action.timeMinutes ~/ 60}ч ${action.timeMinutes % 60}м',
                  Colors.blue[400]!,
                ),
                if (action.staminaRestore > 0)
                  _buildEffectChip(
                    '⚡ +${action.staminaRestore}',
                    Colors.green[400]!,
                  ),
                if (action.healthRestore > 0)
                  _buildEffectChip(
                    '❤️ +${action.healthRestore}',
                    Colors.red[400]!,
                  ),
                if (action.sanityRestore > 0)
                  _buildEffectChip(
                    '🧠 +${action.sanityRestore}',
                    Colors.purple[400]!,
                  ),
                _buildEffectChip(
                  '🍞 -${action.hungerCost}',
                  Colors.orange[400]!,
                ),
                _buildEffectChip(
                  '💧 -${action.thirstCost}',
                  Colors.cyan[400]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}