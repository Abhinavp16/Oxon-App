import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veepee_impex/core/services/shipping_address_service.dart';

ShippingAddress address({
  required String id,
  required String slot,
  String line = '12 Market Road',
}) {
  return ShippingAddress(
    id: id,
    slot: slot,
    fullName: 'Test User',
    phone: '9999999999',
    addressLine1: line,
    city: 'Indore',
    state: 'Madhya Pradesh',
    pincode: '452001',
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persists and returns the selected address', () async {
    final primary = address(
      id: 'primary-id',
      slot: ShippingAddressService.slotPrimary,
    );
    final secondary = address(
      id: 'secondary-id',
      slot: ShippingAddressService.slotSecondary,
    );

    await ShippingAddressService.upsertAddress(primary);
    await ShippingAddressService.upsertAddress(secondary);
    await ShippingAddressService.setSelectedAddressId(secondary.id);

    final selected = await ShippingAddressService.getSelectedAddress();
    expect(selected?.id, secondary.id);
  });

  test('repairs a stale selected address id', () async {
    final primary = address(
      id: 'primary-id',
      slot: ShippingAddressService.slotPrimary,
    );
    await ShippingAddressService.upsertAddress(primary);
    await ShippingAddressService.setSelectedAddressId('missing-id');

    final selected = await ShippingAddressService.getSelectedAddress();
    final selectedId = await ShippingAddressService.getSelectedAddressId();

    expect(selected?.id, primary.id);
    expect(selectedId, primary.id);
  });

  test('editing an address keeps its existing slot', () async {
    final primary = address(
      id: 'primary-id',
      slot: ShippingAddressService.slotPrimary,
    );
    await ShippingAddressService.upsertAddress(primary);

    await ShippingAddressService.upsertAddress(
      address(id: primary.id, slot: '', line: '44 Updated Road'),
    );

    final addresses = await ShippingAddressService.getAddresses();
    expect(addresses.single.slot, ShippingAddressService.slotPrimary);
    expect(addresses.single.addressLine1, '44 Updated Road');
  });

  test('clears malformed persisted address data', () async {
    SharedPreferences.setMockInitialValues({
      'shipping_addresses': '{invalid-json',
      'selected_shipping_address_id': 'stale-id',
    });

    expect(await ShippingAddressService.getAddresses(), isEmpty);
    expect(await ShippingAddressService.getSelectedAddressId(), isNull);
  });
}
