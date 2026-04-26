import 'package:flutter_bloc/flutter_bloc.dart';
import 'whitelist_state.dart';
import '../../models/whitelist_entry.dart';

class WhitelistCubit extends Cubit<WhitelistState> {
  WhitelistCubit() : super(WhitelistState(_getDemoContacts()));

  // Demo contacts for testing
  static List<WhitelistEntry> _getDemoContacts() {
    final now = DateTime.now();
    return [
      WhitelistEntry(
        phone: '+60123456780',
        nickname: 'Mum',
        addedAt: now.subtract(const Duration(days: 30)),
      ),
      WhitelistEntry(
        phone: '+60198765432',
        nickname: 'Ali (Office)',
        addedAt: now.subtract(const Duration(days: 15)),
      ),
      WhitelistEntry(
        phone: '+60167891234',
        nickname: 'Sarah',
        addedAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  void addEntry(String phone, String nickname) {
    final cleaned = phone.replaceAll(RegExp(r'\s'), '');
    if (state.contains(cleaned)) return;
    emit(WhitelistState([
      ...state.entries,
      WhitelistEntry(phone: cleaned, nickname: nickname, addedAt: DateTime.now()),
    ]));
  }

  void removeEntry(String phone) {
    emit(WhitelistState(
      state.entries
          .where((e) => e.phone != phone.replaceAll(RegExp(r'\s'), ''))
          .toList(),
    ));
  }
}
