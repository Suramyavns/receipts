class Normalizer {
  static String normalize(String raw) => raw
      .replaceAll('‎', '')    // LRM (iOS injects this)
      .replaceAll('‏', '')    // RLM
      .replaceAll(' ', ' ')   // narrow no-break space → regular space
      .replaceAll(' ', ' ')   // non-breaking space → regular space
      .replaceAll('﻿', '')    // BOM
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');
}
