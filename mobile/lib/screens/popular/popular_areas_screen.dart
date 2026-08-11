import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../data/popular_areas.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_preferences_model.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/country_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/shell_provider.dart';
import '../../widgets/home/analyzing_progress_view.dart';
import '../../widgets/home/popular_area_card.dart';

/// Full-screen list of the popular areas within a single region.
///
/// Pushed from the home "Popular in {region}" section's *See all*. Tapping an
/// area runs a real analysis, then pops back and switches the shell to the
/// results tab — the same summary the rest of the app lands on.
class PopularAreasScreen extends ConsumerStatefulWidget {
  final String region;
  final List<PopularArea> areas;

  const PopularAreasScreen({
    super.key,
    required this.region,
    required this.areas,
  });

  @override
  ConsumerState<PopularAreasScreen> createState() => _PopularAreasScreenState();
}

class _PopularAreasScreenState extends ConsumerState<PopularAreasScreen> {
  String? _analyzingLabel;

  Future<void> _analyze(PopularArea area) async {
    final country = ref.read(selectedCountryProvider);
    final countryName = country?.name ?? 'Portugal';
    final profile = ref.read(preferencesProvider).profile.jsonValue;
    setState(() => _analyzingLabel = '${area.name}, ${area.region}');
    await ref.read(analysisProvider.notifier).analyze(
          '${area.name}, ${area.region}, $countryName',
          countryCode: country?.code ?? 'PT',
          profile: profile,
        );
    if (!mounted) return;
    if (ref.read(analysisProvider).status == AnalysisStatus.done) {
      Navigator.of(context).pop();
      ref.read(shellTabProvider.notifier).state = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final l = AppLocalizations.of(context);
    final analysis = ref.watch(analysisProvider);

    if (analysis.isLoading) {
      return Scaffold(
        backgroundColor: p.bg,
        body: AnalyzingProgressView(
          address: _analyzingLabel ?? '',
          status: analysis.status,
          progress: analysis.progress,
        ),
      );
    }

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: p.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l.homePopularTitle,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              l.homePopularAreasSubtitle(widget.region),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: p.textTertiary,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: widget.areas.isEmpty
          ? Center(
              child: Text(
                l.homePopularAreasSubtitle(widget.region),
                style: TextStyle(color: p.textTertiary, fontSize: 13),
              ),
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              itemCount: widget.areas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => PopularAreaCard(
                area: widget.areas[i],
                onTap: () => _analyze(widget.areas[i]),
              ),
            ),
    );
  }
}
