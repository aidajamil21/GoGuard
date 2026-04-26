import '../../models/whitelist_entry.dart';

class WhitelistState {
  final List<WhitelistEntry> entries;
  const WhitelistState(this.entries);

  bool contains(String phone) =>
      entries.any((e) => e.phone.replaceAll(RegExp(r'\s'), '') ==
          phone.replaceAll(RegExp(r'\s'), ''));

  WhitelistEntry? findByPhone(String phone) {
    try {
      return entries.firstWhere((e) =>
          e.phone.replaceAll(RegExp(r'\s'), '') ==
          phone.replaceAll(RegExp(r'\s'), ''));
    } catch (_) {
      return null;
    }
  }
}
