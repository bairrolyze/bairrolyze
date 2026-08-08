import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/country_provider.dart';

final validationServiceProvider = Provider<ValidationService>((ref) {
  return ValidationService(ref);
});

class ValidationService {
  final Ref _ref;

  ValidationService(this._ref);

  String? validatePostalCode(String? value, AppLocalizations l) {
    if (value == null || value.isEmpty) return null; // optional field
    final country = _ref.read(selectedCountryProvider);
    if (country == null) return null;
    if (!RegExp(country.postalPattern).hasMatch(value)) {
      return l.validationPostalInvalid(country.postalFormat);
    }
    return null;
  }

  /// [field] is an already-localized field label (e.g. "Street" / "Rua").
  String? validateRequired(String? value, String field, AppLocalizations l) {
    if (value == null || value.trim().isEmpty) return l.validationRequired(field);
    return null;
  }

  String? validateAddress(String? value, AppLocalizations l) {
    if (value == null || value.trim().isEmpty) return l.validationAddressRequired;
    if (value.trim().length < 5) return l.validationAddressTooShort;
    return null;
  }
}
