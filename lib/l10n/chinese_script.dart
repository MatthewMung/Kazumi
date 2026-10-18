import 'package:flutter/widgets.dart';
import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';
import 'package:kazumi/services/storage/storage.dart';

enum ChineseScriptPreference {
  system,
  simplified,
  traditional;

  static ChineseScriptPreference parse(String value) =>
      values.firstWhere((item) => item.name == value, orElse: () => system);

  String get label => switch (this) {
    system => '跟随系统',
    simplified => '简体中文',
    traditional => '繁體中文',
  };
}

/// Converts presentation text only. Stored metadata, rules and user input stay
/// unchanged. Search conversion is independent of the selected display script.
class ChineseScript extends ChangeNotifier with WidgetsBindingObserver {
  ChineseScript._();

  static final instance = ChineseScript._();
  static const _cacheLimit = 2048;
  static const _cacheCharacterLimit = 262144;
  static final _hasHan = RegExp(r'[\u3400-\u9fff]');
  final _cache = <String, String>{};
  int _cachedCharacters = 0;
  ZhConverter? _toTraditional;
  ZhConverter? _toSimplified;
  ChineseScriptPreference _preference = ChineseScriptPreference.system;
  bool _initialized = false;

  ChineseScriptPreference get preference => _preference;

  static bool usesTraditional(Locale locale) =>
      locale.languageCode == 'zh' &&
      (locale.scriptCode == 'Hant' ||
          (locale.scriptCode != 'Hans' &&
              const {'TW', 'HK', 'MO'}.contains(locale.countryCode)));

  bool get isTraditional => switch (_preference) {
    ChineseScriptPreference.traditional => true,
    ChineseScriptPreference.simplified => false,
    ChineseScriptPreference.system => usesTraditional(
      WidgetsBinding.instance.platformDispatcher.locale,
    ),
  };

  Locale get locale => isTraditional
      ? const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'HK',
        )
      : const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'CN',
        );

  Future<void> initialize() async {
    if (_initialized) return;
    // Initialize once, before rendering. Conversion is synchronous thereafter.
    _toTraditional = await ZhConverter.create(OpenCCConfig.s2hk);
    try {
      _toSimplified = await ZhConverter.create(OpenCCConfig.t2s);
    } catch (_) {
      _toTraditional?.dispose();
      _toTraditional = null;
      rethrow;
    }
    _preference = ChineseScriptPreference.parse(
      GStorage.getSetting(SettingsKeys.chineseScript),
    );
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> setPreference(ChineseScriptPreference value) async {
    if (_preference == value) return;
    await GStorage.putSetting(SettingsKeys.chineseScript, value.name);
    _preference = value;
    _clearCache();
    notifyListeners();
  }

  String searchKeyword(String text) => _toSimplified?.convert(text) ?? text;

  String? displayNullable(String? text) => text == null ? null : display(text);

  String display(String text) {
    if (text.isEmpty || !_initialized || !_hasHan.hasMatch(text)) return text;
    if (text.startsWith('http://') ||
        text.startsWith('https://') ||
        text.startsWith('kazumi://') ||
        text.startsWith('file://')) {
      return text;
    }
    final cached = _cache.remove(text);
    if (cached != null) {
      _cache[text] = cached;
      return cached;
    }
    final result = (isTraditional ? _toTraditional : _toSimplified)!.convert(
      text,
    );
    final size = text.length + result.length;
    if (size <= _cacheCharacterLimit) {
      while (_cache.isNotEmpty &&
          (_cache.length >= _cacheLimit ||
              _cachedCharacters + size > _cacheCharacterLimit)) {
        final key = _cache.keys.first;
        _cachedCharacters -= key.length + _cache.remove(key)!.length;
      }
      _cache[text] = result;
      _cachedCharacters += size;
    }
    return result;
  }

  void _clearCache() {
    _cache.clear();
    _cachedCharacters = 0;
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_preference != ChineseScriptPreference.system) return;
    _clearCache();
    notifyListeners();
  }
}

class ChineseScriptScope extends InheritedNotifier<ChineseScript> {
  const ChineseScriptScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static ChineseScript of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ChineseScriptScope>()
          ?.notifier ??
      ChineseScript.instance;
}
