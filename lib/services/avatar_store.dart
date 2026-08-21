import 'package:flutter/foundation.dart';

import '../widgets/mascot.dart';

/// Oyuncunun seçtiği avatarı (maskot görünümü) tüm ekranlar arasında paylaşır.
///
/// Basit bir [ValueNotifier] tabanlı singleton; durum yönetimini sade tutar.
class AvatarStore {
  AvatarStore._();

  static final AvatarStore instance = AvatarStore._();

  /// Seçili avatarın [mascotSkins] içindeki indeksi.
  final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);

  MascotSkin get skin => mascotSkins[selectedIndex.value];

  void select(int index) {
    if (index < 0 || index >= mascotSkins.length) return;
    selectedIndex.value = index;
  }
}
