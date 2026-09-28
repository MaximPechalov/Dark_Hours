import 'inventory_item.dart';

class Inventory {
  final List<InventoryItem> items = [];
  final double maxWeight;

  Inventory({this.maxWeight = 30.0});

  double get currentWeight {
    return items.fold(0.0, (sum, item) => sum + item.totalWeight);
  }

  bool get isOverloaded => currentWeight > maxWeight;

  bool addItem(InventoryItem item) {
    if (currentWeight + item.weight > maxWeight) {
      return false;
    }

    final existingIndex = items.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      items[existingIndex] = items[existingIndex].copyWith(
        count: items[existingIndex].count + item.count,
      );
    } else {
      items.add(item);
    }
    return true;
  }

  bool removeItem(String id) {
    final index = items.indexWhere((i) => i.id == id);
    if (index < 0) return false;

    final item = items[index];
    if (item.count > 1) {
      items[index] = item.copyWith(count: item.count - 1);
    } else {
      items.removeAt(index);
    }
    return true;
  }

  /// Удалить предмет полностью
  void removeAll(String id) {
    items.removeWhere((i) => i.id == id);
  }

  bool hasItem(String id) {
    return items.any((i) => i.id == id);
  }

  int countOf(String id) {
    try {
      return items.firstWhere((i) => i.id == id).count;
    } catch (e) {
      return 0;
    }
  }

  InventoryItem? getById(String id) {
    try {
      return items.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> toJson() {
    return items.map((i) => i.toJson()).toList();
  }

  static Inventory fromJson(List<dynamic> json) {
    final inv = Inventory();
    for (final itemJson in json) {
      inv.items.add(InventoryItem.fromJson(itemJson));
    }
    return inv;
  }
}