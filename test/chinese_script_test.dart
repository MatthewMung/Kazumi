import 'dart:io';

import 'package:flutter/material.dart' as flutter;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/l10n/material.dart';
import 'package:kazumi/request/apis/bangumi_api.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/search_parser.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final script = ChineseScript.instance;
  late Directory directory;
  late PathProviderPlatform originalPaths;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('kazumi_script_test_');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(directory.path);
    Hive.init(directory.path);
    await GStorage.init();
    await script.initialize();
  });

  tearDownAll(() async {
    await Hive.close();
    PathProviderPlatform.instance = originalPaths;
    expect(
      directory.absolute.path.startsWith(Directory.systemTemp.absolute.path),
      isTrue,
    );
    expect(
      directory.uri.pathSegments.where((part) => part.isNotEmpty).last,
      startsWith('kazumi_script_test_'),
    );
    await directory.delete(recursive: true);
  });

  test('recognizes traditional system locales and explicit Hans', () {
    expect(ChineseScript.usesTraditional(const Locale('zh', 'HK')), isTrue);
    expect(ChineseScript.usesTraditional(const Locale('zh', 'TW')), isTrue);
    expect(ChineseScript.usesTraditional(const Locale('zh', 'MO')), isTrue);
    expect(
      ChineseScript.usesTraditional(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ),
      isTrue,
    );
    expect(
      ChineseScript.usesTraditional(
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'HK',
        ),
      ),
      isFalse,
    );
    expect(ChineseScript.usesTraditional(const Locale('en', 'HK')), isFalse);
    expect(
      ChineseScriptPreference.parse('unknown'),
      ChineseScriptPreference.system,
    );
  });

  test(
    'persists script selection, converts phrases, invalidates cached text',
    () async {
      const original = '头发发展，动画设置';
      await script.setPreference(ChineseScriptPreference.traditional);
      expect(script.display(original), '頭髮發展，動畫設置');
      expect(script.display(original), '頭髮發展，動畫設置');
      expect(GStorage.getSetting(SettingsKeys.chineseScript), 'traditional');
      await script.setPreference(ChineseScriptPreference.simplified);
      expect(script.display(original), original);
      expect(script.display('頭髮發展，動畫設置'), original);
      expect(script.display('Kazumi 2.3.9 🎬'), 'Kazumi 2.3.9 🎬');
      expect(
        script.display('https://example.org/動畫'),
        'https://example.org/動畫',
      );
      expect(script.displayNullable(null), isNull);
      expect(original, '头发发展，动画设置');
    },
  );

  test(
    'traditional search works in both display modes and preserves filters',
    () async {
      const input = '葬送的芙莉蓮 tag:奇幻 sort:score';
      for (final preference in [
        ChineseScriptPreference.traditional,
        ChineseScriptPreference.simplified,
      ]) {
        await script.setPreference(preference);
        final filter = SearchParser(input).toFilterState();
        final params = BangumiApi.buildBangumiSearchParams(
          filter.keyword,
          tags: filter.tags,
          sort: filter.sort,
        );
        expect(params['keyword'], '葬送的芙莉莲');
        expect(params['sort'], 'score');
        expect((params['filter'] as Map)['tag'], ['奇幻']);
        expect(script.searchKeyword('進擊的巨人'), '进击的巨人');
        expect(script.searchKeyword('SPY×FAMILY 2'), 'SPY×FAMILY 2');
        expect(script.searchKeyword('葬送のフリーレン'), '葬送のフリーレン');
        expect(input, '葬送的芙莉蓮 tag:奇幻 sort:score');
      }
    },
  );

  testWidgets(
    'constant text, rich text and selectable summaries update without changing input',
    (tester) async {
      await script.setPreference(ChineseScriptPreference.simplified);
      final input = TextEditingController(text: '葬送的芙莉蓮');
      await tester.pumpWidget(
        ChineseScriptScope(
          notifier: script,
          child: flutter.MaterialApp(
            home: flutter.Scaffold(
              body: Column(
                children: [
                  const Text('显示设置'),
                  const Text.rich(
                    TextSpan(
                      text: '头发',
                      children: [TextSpan(text: '发展')],
                    ),
                  ),
                  const SelectableText('动画简介'),
                  const Text('https://example.org/动画', convert: false),
                  TextField(controller: input),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('显示设置'), findsOneWidget);
      await script.setPreference(ChineseScriptPreference.traditional);
      await tester.pumpAndSettle();
      expect(find.text('顯示設置'), findsOneWidget);
      expect(find.text('頭髮發展'), findsOneWidget);
      expect(find.text('動畫簡介'), findsOneWidget);
      expect(input.text, '葬送的芙莉蓮');
      expect(find.text('https://example.org/动画'), findsOneWidget);
      await script.setPreference(ChineseScriptPreference.simplified);
      await tester.pumpAndSettle();
      expect(find.text('显示设置'), findsOneWidget);
      expect(find.text('动画简介'), findsOneWidget);
      await tester.pumpWidget(const flutter.SizedBox());
      input.dispose();
    },
  );
}

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
  @override
  Future<String?> getTemporaryPath() async => path;
}
