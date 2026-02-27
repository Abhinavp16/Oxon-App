import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ShippingAddress {
  final String id;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String city;
  final String state;
  final String pincode;

  const ShippingAddress({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.pincode,
  });

  static String generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      addressLine1: json['addressLine1']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'addressLine1': addressLine1,
      'city': city,
      'state': state,
      'pincode': pincode,
    };
  }

  Map<String, String> toOrderPayload() {
    return {
      'fullName': fullName,
      'phone': phone,
      'addressLine1': addressLine1,
      'city': city,
      'state': state,
      'pincode': pincode,
    };
  }

  String get shortAddress => '$addressLine1, $city';
}

class ShippingAddressService {
  static const _addressesKey = 'shipping_addresses';
  static const _selectedAddressIdKey = 'selected_shipping_address_id';

  static Future<List<ShippingAddress>> getAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_addressesKey);
    if (raw == null || raw.isEmpty) return [];

    final parsed = jsonDecode(raw);
    if (parsed is! List) return [];

    return parsed
        .whereType<Map>()
        .map((e) => ShippingAddress.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> _setAddresses(List<ShippingAddress> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _addressesKey,
      jsonEncode(addresses.map((e) => e.toJson()).toList()),
    );
  }

  static Future<String?> getSelectedAddressId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedAddressIdKey);
  }

  static Future<void> setSelectedAddressId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await prefs.remove(_selectedAddressIdKey);
      return;
    }
    await prefs.setString(_selectedAddressIdKey, id);
  }

  static Future<ShippingAddress?> getSelectedAddress() async {
    final addresses = await getAddresses();
    final selectedId = await getSelectedAddressId();
    if (addresses.isEmpty) return null;

    if (selectedId == null || selectedId.isEmpty) {
      return addresses.first;
    }

    return addresses.firstWhere(
      (a) => a.id == selectedId,
      orElse: () => addresses.first,
    );
  }

  static Future<void> upsertAddress(ShippingAddress address) async {
    final addresses = await getAddresses();
    final index = addresses.indexWhere((a) => a.id == address.id);
    if (index >= 0) {
      addresses[index] = address;
    } else {
      addresses.add(address);
    }
    await _setAddresses(addresses);
  }

  static Future<void> deleteAddress(String id) async {
    final addresses = await getAddresses();
    final updated = addresses.where((a) => a.id != id).toList();
    await _setAddresses(updated);

    final selectedId = await getSelectedAddressId();
    if (selectedId == id) {
      await setSelectedAddressId(updated.isNotEmpty ? updated.first.id : null);
    }
  }
}
