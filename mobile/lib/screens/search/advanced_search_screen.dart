import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/address_model.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/country_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../services/validation_service.dart';
import '../../widgets/common/loading_overlay.dart';

class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _apartmentCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  @override
  void dispose() {
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _apartmentCtrl.dispose();
    _postalCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  String _buildAddress(CountryConfig? country) {
    final parts = <String>[];
    final street = _streetCtrl.text.trim();
    final number = _numberCtrl.text.trim();
    final apt = _apartmentCtrl.text.trim();
    final postal = _postalCtrl.text.trim();
    final city = _cityCtrl.text.trim();

    if (street.isNotEmpty) {
      parts.add('$street${number.isNotEmpty ? ' $number' : ''}${apt.isNotEmpty ? ', $apt' : ''}');
    }
    if (postal.isNotEmpty) parts.add(postal);
    if (city.isNotEmpty) parts.add(city);
    if (country != null) parts.add(country.name);

    return parts.join(', ');
  }

  Future<void> _search() async {
    if (!_formKey.currentState!.validate()) return;
    final country = ref.read(selectedCountryProvider);
    final profile = ref.read(preferencesProvider).profile.name;
    final address = _buildAddress(country);

    await ref.read(analysisProvider.notifier).analyze(
          address,
          countryCode: country?.code ?? 'PT',
          profile: profile,
        );

    if (mounted) {
      final state = ref.read(analysisProvider);
      if (state.status == AnalysisStatus.done) {
        context.pushNamed('dashboard', extra: state.address);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysis = ref.watch(analysisProvider);
    final countriesAsync = ref.watch(countriesProvider);
    final selectedCountry = ref.watch(selectedCountryProvider);
    final validation = ref.read(validationServiceProvider);

    ref.listen(analysisProvider, (_, next) {
      if (next.status == AnalysisStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Search'),
        actions: [
          TextButton.icon(
            onPressed: analysis.isLoading ? null : _search,
            icon: const Icon(Icons.analytics_rounded),
            label: const Text('Analyze'),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: analysis.isLoading,
        message: analysis.statusMessage,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Location', icon: Icons.location_on_rounded),
                const SizedBox(height: 12),

                // Country selector
                countriesAsync.when(
                  data: (countries) => DropdownButtonFormField<CountryConfig>(
                    initialValue: selectedCountry,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      prefixIcon: Icon(Icons.flag_rounded),
                    ),
                    items: countries
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Text(_flag(c.code)),
                                  const SizedBox(width: 8),
                                  Text(c.name),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (c) {
                      if (c != null) {
                        ref.read(selectedCountryProvider.notifier).select(c);
                      }
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Failed to load countries'),
                ),

                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _streetCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Street',
                          prefixIcon: Icon(Icons.edit_road_rounded),
                          hintText: 'Rua Augusta',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => validation.validateRequired(v, 'Street'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _numberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'No.',
                          hintText: '150',
                        ),
                        keyboardType: TextInputType.text,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _apartmentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Apartment / Floor',
                    prefixIcon: Icon(Icons.apartment_rounded),
                    hintText: '3rd floor, apt 4',
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _postalCtrl,
                        decoration: InputDecoration(
                          labelText: 'Postal Code',
                          prefixIcon: const Icon(Icons.pin_drop_rounded),
                          hintText: selectedCountry?.postalExample ?? '1200-109',
                        ),
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          return validation.validatePostalCode(v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cityCtrl,
                        decoration: InputDecoration(
                          labelText: 'City',
                          prefixIcon: const Icon(Icons.location_city_rounded),
                          hintText: selectedCountry?.defaultCity ?? 'Lisboa',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => validation.validateRequired(v, 'City'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _districtCtrl,
                  decoration: const InputDecoration(
                    labelText: 'District / Region (optional)',
                    prefixIcon: Icon(Icons.map_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 32),

                if (selectedCountry != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Postal code format: ${selectedCountry.postalFormat}  '
                            '(e.g. ${selectedCountry.postalExample})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: analysis.isLoading ? null : _search,
                    icon: const Icon(Icons.analytics_rounded),
                    label: const Text('Analyze Address'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _flag(String code) {
    const flags = {'PT': '🇵🇹', 'ES': '🇪🇸', 'GB': '🇬🇧', 'FR': '🇫🇷', 'DE': '🇩🇪'};
    return flags[code] ?? '🌍';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
