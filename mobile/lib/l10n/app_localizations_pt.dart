// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get settingsTitle => 'Perfil';

  @override
  String get settingsSectionProfile => 'PERFIL';

  @override
  String get settingsSectionCountry => 'PAÍS';

  @override
  String get settingsSectionLanguage => 'IDIOMA';

  @override
  String get settingsSectionSearchRadius => 'RAIO DE PESQUISA';

  @override
  String get settingsSectionAppearance => 'APARÊNCIA';

  @override
  String get settingsSectionAiFeatures => 'FUNCIONALIDADES IA';

  @override
  String get settingsSectionHelp => 'AJUDA';

  @override
  String get profileGeneral => 'Geral';

  @override
  String get profileFamily => 'Família';

  @override
  String get profileStudent => 'Estudante';

  @override
  String get profilePro => 'Pro';

  @override
  String get profileRetired => 'Reformado';

  @override
  String get profileInvestor => 'Investidor';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Português';

  @override
  String settingsRadiusLabel(String km) {
    return 'raio de $km km';
  }

  @override
  String settingsRadiusMeters(int meters) {
    return '${meters}m';
  }

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get aiSummaryTitle => 'Resumo IA do Bairro';

  @override
  String get aiSummarySubtitle => 'Com tecnologia OpenAI';

  @override
  String get helpGuidesTitle => 'Guias e Ajuda';

  @override
  String get helpGuidesSubtitle =>
      '8 guias detalhados para cada funcionalidade';

  @override
  String get helpTourTitle => 'Visita Rápida';

  @override
  String get helpTourSubtitle => 'Introdução em 5 ecrãs ao Bairrolyze';

  @override
  String get profileProfessional => 'Profissional';

  @override
  String get prioritySchools => 'Boas escolas';

  @override
  String get priorityCommute => 'Trajeto curto';

  @override
  String get prioritySocial => 'Comércio e vida noturna';

  @override
  String get priorityHealthcare => 'Saúde por perto';

  @override
  String get prioritySafety => 'Seguro e tranquilo';

  @override
  String get priorityRental => 'Potencial de arrendamento';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get onboardingSkip => 'Ignorar';

  @override
  String get onboardingWelcomeTitle => 'Vamos personalizar as tuas pontuações';

  @override
  String get onboardingWelcomeSubtitle =>
      'O Bairrolyze avalia cada morada em função do que é importante para ti.';

  @override
  String get onboardingGetStarted => 'Começar';

  @override
  String get onboardingPrioritiesTitle =>
      'O que é mais importante onde vais viver?';

  @override
  String get onboardingPickUpTo3 => 'Escolhe até 3.';

  @override
  String get onboardingThatsTheMax => 'É o máximo';

  @override
  String onboardingConfirmPrioritize(String profile) {
    return 'Perfeito — vamos priorizar $profile.';
  }

  @override
  String get onboardingYourPriorities => 'As tuas prioridades';

  @override
  String get onboardingBalancedProfile =>
      'Vamos usar um perfil geral e equilibrado — podes ajustá-lo a qualquer momento nas definições.';

  @override
  String get onboardingStartExploring => 'Começar a explorar';

  @override
  String get commonClear => 'Limpar';

  @override
  String get homeLocationServicesOff =>
      'Ativa os serviços de localização para usar isto.';

  @override
  String get homeLocationPermissionNeeded =>
      'É necessária permissão de localização para detetar a tua zona.';

  @override
  String get homeLocationFailed =>
      'Não foi possível obter a tua localização atual.';

  @override
  String get homeSearchHint => 'Pesquisa qualquer morada, cidade ou zona';

  @override
  String get homeUseMyLocation => 'Usar a minha localização atual';

  @override
  String get homeHeroSubtitle => 'A Forma Mais Inteligente de Escolher Casa';

  @override
  String get homeCtaAnalyse => 'Analisar Bairro';

  @override
  String get homePopularTitle => 'Pesquisas Populares';

  @override
  String homePopularSubtitle(String country) {
    return 'Locais mais visitados em $country';
  }

  @override
  String get homePopularSeeAll => 'Ver tudo';

  @override
  String get homePopularTrending => 'Em alta';

  @override
  String homePopularAreasSubtitle(String region) {
    return 'Zonas populares que as pessoas estão a explorar em $region';
  }

  @override
  String get homeRecentTitle => 'Pesquisas Recentes';

  @override
  String get homeTrustedBy =>
      'Escolhido por milhares de utilizadores em todo o mundo';

  @override
  String get featureSmartDataTitle => 'Dados Inteligentes';

  @override
  String get featureSmartDataDesc => 'Fontes fiáveis e em tempo real';

  @override
  String get featureAiAnalysisTitle => 'Análise IA';

  @override
  String get featureAiAnalysisDesc =>
      'Mais de 25 fatores analisados em segundos';

  @override
  String get featureAccurateScoreTitle => 'Pontuação Precisa';

  @override
  String get featureAccurateScoreDesc =>
      'Uma pontuação clara para decidir com confiança';

  @override
  String get featurePrivateSecureTitle => 'Privado e Seguro';

  @override
  String get featurePrivateSecureDesc =>
      'As tuas pesquisas e dados ficam protegidos';

  @override
  String get homeAnalyseTitle => 'O que analisamos';

  @override
  String get homeAnalyseSubtitle =>
      'Sete sinais que avaliamos para cada morada · desliza para explorar';

  @override
  String get catTransportLabel => 'Transportes';

  @override
  String get catTransportDesc =>
      'Estações de comboio, autocarros, tempos de deslocação e caminhabilidade por perto.';

  @override
  String get catEducationLabel => 'Educação';

  @override
  String get catEducationDesc =>
      'Escolas, universidades, bibliotecas e opções de ensino por perto.';

  @override
  String get catHealthLabel => 'Saúde';

  @override
  String get catHealthDesc =>
      'Hospitais, clínicas, farmácias e acesso a cuidados de saúde do dia a dia.';

  @override
  String get catSafetyLabel => 'Segurança';

  @override
  String get catSafetyDesc =>
      'Serviços de emergência e estatísticas reais de criminalidade, quando disponíveis.';

  @override
  String get catLifestyleLabel => 'Estilo de Vida';

  @override
  String get catLifestyleDesc =>
      'Lojas, mercados, cafés e as conveniências do dia a dia ao teu alcance.';

  @override
  String get catNatureLabel => 'Natureza';

  @override
  String get catNatureDesc => 'Parques, jardins e espaços verdes ao ar livre.';

  @override
  String get catInvestmentLabel => 'Investimento';

  @override
  String get catInvestmentDesc =>
      'Tendências de preços, procura de arrendamento e potencial de valorização a longo prazo.';

  @override
  String get homeHowTitle => 'Como funciona';

  @override
  String get homeHowSubtitle => 'De uma morada a uma pontuação em três passos';

  @override
  String get homeHowBody =>
      'Recolhemos dados em tempo real do OpenStreetMap e avaliamos cada categoria em função do teu perfil, para que o resultado reflita o que realmente importa para ti.';

  @override
  String get homeStepLocate => 'Localizar';

  @override
  String get homeStepAnalyse => 'Analisar';

  @override
  String get homeStepScore => 'Pontuar';

  @override
  String get commonViewMap => 'Ver mapa';

  @override
  String get commonShare => 'Partilhar';

  @override
  String get commonDismiss => 'Dispensar';

  @override
  String get dashAnalyzing => 'A analisar...';

  @override
  String get dashTitle => 'Painel';

  @override
  String get dashNoData => 'Sem dados de análise disponíveis';

  @override
  String get dashSearchAddress => 'Pesquisar uma morada';

  @override
  String get dashCategoryScores => 'Pontuações por categoria';

  @override
  String get dashNearbyPlaces => 'Locais próximos';

  @override
  String dashViewAllPlaces(int count) {
    return 'Ver todos os $count locais no mapa';
  }

  @override
  String get dashOpenMap => 'Abrir mapa';

  @override
  String dashShareMessage(String address, int score) {
    return '$address — Pontuação: $score/100';
  }

  @override
  String get dashLivingIndex => 'Índice de Vida';

  @override
  String get dashLivingIndexSubtitle =>
      'A tua vista principal — DNA, Cronologia, História e mais';

  @override
  String get pillDna => 'DNA';

  @override
  String get pillRadius => 'Raio';

  @override
  String get pillTimeline => 'Cronologia';

  @override
  String get pillStory => 'História';

  @override
  String get pillFuture => 'Futuro';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonAnalyze => 'Analisar';

  @override
  String get commonClearAll => 'Limpar tudo';

  @override
  String get savedTitle => 'Guardados';

  @override
  String get savedEmptyTitle => 'Ainda não há locais guardados';

  @override
  String get savedEmptyBody =>
      'Toca no marcador em qualquer análise para a guardar aqui e aceder rapidamente.';

  @override
  String get historyTitle => 'Histórico de Pesquisas';

  @override
  String get historyClearTooltip => 'Limpar histórico';

  @override
  String get historyEmptyTitle => 'Ainda não há histórico de pesquisas';

  @override
  String get historyEmptyBody => 'As tuas moradas analisadas aparecem aqui';

  @override
  String get historyClearTitle => 'Limpar Histórico';

  @override
  String get historyClearBody => 'Remover todo o histórico de pesquisas?';

  @override
  String timeMinutesAgo(int minutes) {
    return 'há $minutes min';
  }

  @override
  String timeHoursAgo(int hours) {
    return 'há $hours h';
  }

  @override
  String timeDaysAgo(int days) {
    return 'há $days d';
  }

  @override
  String validationRequired(String field) {
    return 'Preenche o campo $field';
  }

  @override
  String get validationAddressRequired => 'A morada é obrigatória';

  @override
  String get validationAddressTooShort => 'A morada é demasiado curta';

  @override
  String validationPostalInvalid(String format) {
    return 'Formato inválido. Esperado: $format';
  }

  @override
  String get advTitle => 'Pesquisa Avançada';

  @override
  String get advSectionLocation => 'Localização';

  @override
  String get advFailedCountries => 'Falha ao carregar países';

  @override
  String get advAnalyzeAddress => 'Analisar Morada';

  @override
  String get advHintApartment => '3º andar, apt 4';

  @override
  String advPostalHelp(String format, String example) {
    return 'Formato do código postal: $format  (ex.: $example)';
  }

  @override
  String get fieldCountry => 'País';

  @override
  String get fieldStreet => 'Rua';

  @override
  String get fieldNumber => 'Nº';

  @override
  String get fieldApartment => 'Apartamento / Andar';

  @override
  String get fieldPostalCode => 'Código Postal';

  @override
  String get fieldCity => 'Cidade';

  @override
  String get fieldDistrict => 'Distrito / Região (opcional)';

  @override
  String get explorerTitle => 'Explorar';

  @override
  String get explorerSubtitle =>
      'Encontra os bairros que combinam com a forma como queres viver.';

  @override
  String get explorerFeatured => 'EM DESTAQUE';

  @override
  String explorerBestFor(String profile) {
    return 'Melhor para $profile';
  }

  @override
  String get explorerBestMatch => 'Melhor correspondência';

  @override
  String get explorerCityAll => 'Todas as zonas';

  @override
  String explorerTrendingIn(String region) {
    return 'Em alta em $region';
  }

  @override
  String get explorerStepProfile => '1. Escolhe o teu perfil';

  @override
  String get explorerStepArea => '2. Escolhe a tua zona';

  @override
  String explorerSearchHint(String country) {
    return 'Procurar zonas em $country';
  }

  @override
  String explorerNoAreas(String country) {
    return 'Nenhuma zona encontrada em $country';
  }

  @override
  String explorerSearchPrompt(String country) {
    return 'Procura qualquer zona em $country acima para analisar.';
  }

  @override
  String get explorerProfileFamilyDesc => 'Ótimo para crescer & vida familiar';

  @override
  String get explorerProfileStudentDesc => 'Perto de campus & transportes';

  @override
  String get explorerProfileProfessionalDesc => 'Bem servido & conveniente';

  @override
  String get explorerProfileRetiredDesc => 'Tranquilo & sossegado';

  @override
  String get explorerProfileInvestorDesc => 'Procura forte & valorização';

  @override
  String get filterAll => 'Todos';

  @override
  String get tagTransport => 'Transportes';

  @override
  String get tagFamily => 'Família';

  @override
  String get tagInvestment => 'Investimento';

  @override
  String get tagNature => 'Natureza';

  @override
  String get tagCulture => 'Cultura';

  @override
  String get statTransit => 'Transportes';

  @override
  String get statEducation => 'Educação';

  @override
  String get statSafety => 'Segurança';

  @override
  String get nbParqueNacoesDesc =>
      'Zona ribeirinha moderna, com excelentes transportes e arquitetura contemporânea.';

  @override
  String get nbParqueNacoesHighlight =>
      'A mais bem servida de transportes em Lisboa';

  @override
  String get nbPrincipeRealDesc =>
      'Bairro sofisticado no alto da colina, conhecido pelas boutiques, galerias e vida de café.';

  @override
  String get nbPrincipeRealHighlight => 'Melhor pontuação de caminhabilidade';

  @override
  String get nbCascaisDesc =>
      'Vila costeira de prestígio, com marina, praias e uma qualidade de vida excecional.';

  @override
  String get nbCascaisHighlight => 'Melhor qualidade de vida junto ao mar';

  @override
  String get nbBaixaChiadoDesc =>
      'O coração de Lisboa — grandiosidade histórica a par de uma animada vida comercial e cultural.';

  @override
  String get nbBaixaChiadoHighlight => 'Centro histórico, ótimos transportes';

  @override
  String get nbBoavistaDesc =>
      'Corredor empresarial e residencial de prestígio no Porto, com excelentes serviços urbanos.';

  @override
  String get nbBoavistaHighlight =>
      'O principal distrito de investimento do Porto';

  @override
  String get nbFozDouroDesc =>
      'Bairro ribeirinho exclusivo, com vistas de mar, parques e restaurantes requintados.';

  @override
  String get nbFozDouroHighlight => 'A morada mais desejada do Porto';

  @override
  String get nbSantoAntonioDesc =>
      'Bairro central de Lisboa, com excelentes cuidados de saúde, escolas e segurança.';

  @override
  String get nbSantoAntonioHighlight =>
      'O melhor para famílias no centro de Lisboa';

  @override
  String get nbBragaCentroDesc =>
      'Joia do Norte que alia o encanto histórico à energia de uma cidade universitária.';

  @override
  String get nbBragaCentroHighlight => 'O centro urbano com maior crescimento';

  @override
  String get amenityTransportation => 'Transportes';

  @override
  String get amenityEducation => 'Escolas';

  @override
  String get amenityHealthcare => 'Saúde';

  @override
  String get amenityShopping => 'Compras';

  @override
  String get amenitySafety => 'Segurança';

  @override
  String get amenityReligion => 'Religião';

  @override
  String get amenityRecreation => 'Parques';

  @override
  String get mapTitleFallback => 'Mapa';

  @override
  String get mapCenterTooltip => 'Centrar mapa';

  @override
  String mapPlacesFound(int total) {
    return '$total locais encontrados';
  }

  @override
  String mapPlacesNearby(int total) {
    return '$total locais por perto';
  }

  @override
  String mapCategoryCount(int total, String category) {
    return '$total $category';
  }

  @override
  String amenityCountLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String amenityMinWalk(int minutes) {
    return '$minutes min a pé';
  }

  @override
  String amenityMinDrive(int minutes) {
    return '$minutes min de carro';
  }

  @override
  String get paywallBadge => 'Torna-te Pro';

  @override
  String get paywallTitle => 'Desbloqueia todo o Bairrolyze';

  @override
  String get paywallSubtitle =>
      'Toma decisões com confiança, com todas as informações à mão.';

  @override
  String get paywallRestore => 'Restaurar compras';

  @override
  String get paywallCancelAnytime =>
      'Cancela quando quiseres. Faturação mensal.';

  @override
  String get paywallMostPopular => 'MAIS POPULAR';

  @override
  String paywallStartPro(String price) {
    return 'Começar Pro — $price/mês';
  }

  @override
  String paywallTryPremium(String price) {
    return 'Experimentar Premium — $price/mês';
  }

  @override
  String get paywallFreePrice => '€0 / para sempre';

  @override
  String paywallPerMonth(String price) {
    return '$price / mês';
  }

  @override
  String get tierFree => 'Grátis';

  @override
  String get tierPro => 'Pro';

  @override
  String get tierPremium => 'Premium';

  @override
  String get featFree2Comparisons => '2 comparações de imóveis';

  @override
  String get featFree1Alert => '1 alerta de bairro';

  @override
  String get featFreeCoreAnalysis => 'Análise essencial e mapas';

  @override
  String get featProUnlimitedComparisons => 'Comparações ilimitadas';

  @override
  String get featPro10Alerts => '10 alertas de bairro';

  @override
  String get featProPriority => 'Análise prioritária';

  @override
  String get featProTimeline => 'Cronologia histórica';

  @override
  String get featPremiumEverythingPro => 'Tudo do Pro';

  @override
  String get featPremium99Alerts => '99 alertas com notificações push';

  @override
  String get featPremiumAiInsights => 'Análises de investimento com IA';

  @override
  String get featPremiumForecasting => 'Previsão de tendências';

  @override
  String get paywallErrProductUnavailable =>
      'Produto indisponível. Tenta novamente.';

  @override
  String get paywallErrGeneric => 'Algo correu mal. Tenta novamente.';

  @override
  String get paywallErrNoPurchases =>
      'Não foram encontradas compras ativas nesta conta.';

  @override
  String get paywallErrPaymentPending =>
      'O pagamento está pendente. Verifica o teu método de pagamento.';

  @override
  String get paywallErrRegion => 'Produto indisponível na tua região.';

  @override
  String get paywallErrPurchaseFailed => 'A compra falhou. Tenta novamente.';
}
