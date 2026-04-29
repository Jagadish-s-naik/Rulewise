import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/locale_provider.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final currentLocale = localeProvider.locale ?? Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectLanguage),
      ),
      body: ListView.builder(
        itemCount: L10n.all.length,
        itemBuilder: (context, index) {
          final locale = L10n.all[index];
          final languageName = L10n.getLanguageName(locale.languageCode);
          
          return ListTile(
            title: Text(languageName),
            trailing: currentLocale.languageCode == locale.languageCode
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
            onTap: () {
              context.read<LocaleProvider>().setLocale(locale);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
