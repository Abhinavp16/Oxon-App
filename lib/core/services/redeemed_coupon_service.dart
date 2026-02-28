import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RedeemedCoupon {
  final String code;
  final String title;
  final String rule;
  final int redeemedAt;

  const RedeemedCoupon({
    required this.code,
    required this.title,
    required this.rule,
    required this.redeemedAt,
  });

  factory RedeemedCoupon.fromJson(Map<String, dynamic> json) {
    return RedeemedCoupon(
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      rule: json['rule']?.toString() ?? '',
      redeemedAt: (json['redeemedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'title': title,
      'rule': rule,
      'redeemedAt': redeemedAt,
    };
  }
}

class RedeemedCouponService {
  static const _key = 'redeemed_coupons';

  static Future<List<RedeemedCoupon>> getCoupons() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final parsed = jsonDecode(raw);
    if (parsed is! List) return [];
    return parsed
        .whereType<Map>()
        .map((e) => RedeemedCoupon.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.redeemedAt.compareTo(a.redeemedAt));
  }

  static Future<void> redeemCoupon({
    required String code,
    required String title,
    required String rule,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) return;

    final current = await getCoupons();
    final exists = current.any((c) => c.code == normalizedCode);
    if (!exists) {
      current.insert(
        0,
        RedeemedCoupon(
          code: normalizedCode,
          title: title.trim(),
          rule: rule.trim(),
          redeemedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await _save(current);
    }
  }

  static Future<void> _save(List<RedeemedCoupon> coupons) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(coupons.map((c) => c.toJson()).toList()),
    );
  }
}
