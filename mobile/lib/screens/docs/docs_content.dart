import 'package:flutter/material.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class DocSection {
  final String? heading;
  final String? body;
  final String? tip;
  final List<(String, String)>? table;

  const DocSection({this.heading, this.body, this.tip, this.table});
}

class DocArticle {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String category;
  final List<DocSection> sections;

  const DocArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
    required this.sections,
  });
}

// ── Article content ───────────────────────────────────────────────────────────

const _blue   = Color(0xFF3B82F6);
const _green  = Color(0xFF10B981);
const _purple = Color(0xFF7C3AED);
const _orange = Color(0xFFF59E0B);
const _red    = Color(0xFFEF4444);
const _cyan   = Color(0xFF06B6D4);

const kDocArticles = <DocArticle>[

  // ── Getting Started ────────────────────────────────────────────────────────

  DocArticle(
    id: 'getting-started',
    title: 'Getting Started',
    subtitle: 'Search your first address and get insights in 30 seconds',
    icon: Icons.rocket_launch_rounded,
    color: _blue,
    category: 'Getting Started',
    sections: [
      DocSection(
        body: 'HomeScope analyses any address in Portugal and scores it across 7 key dimensions of liveability — so you can make confident property decisions backed by data.',
      ),
      DocSection(heading: 'Step 1 — Open the Search tab'),
      DocSection(
        body: 'The Search screen is your starting point. You\'ll see the headline "Move smarter. Invest wiser." and a search field below it.',
      ),
      DocSection(heading: 'Step 2 — Type an address'),
      DocSection(
        body: 'Tap the search field and type any address, neighbourhood name, or city. As you type, live suggestions appear from OpenStreetMap. Tap a suggestion to fill the field automatically.',
      ),
      DocSection(
        tip: 'You can search by street name, postcode, or neighbourhood — e.g. "Bairro Alto, Lisboa" or "Rua Augusta".',
      ),
      DocSection(heading: 'Step 3 — Tap Get Insights'),
      DocSection(
        body: 'Tap the blue Get Insights button. HomeScope analyses the location across 7 dimensions and opens your Neighbourhood Report in seconds.',
      ),
      DocSection(heading: 'Step 4 — Read your report'),
      DocSection(
        body: 'The report shows your overall score, a category breakdown, an AI-written summary, and a historical timeline. Tap any category card to see more detail.',
      ),
    ],
  ),

  DocArticle(
    id: 'reading-your-report',
    title: 'Reading Your Report',
    subtitle: 'Understand every section of the Neighbourhood Report',
    icon: Icons.bar_chart_rounded,
    color: _green,
    category: 'Getting Started',
    sections: [
      DocSection(
        body: 'The Neighbourhood Report gives you a complete picture of any location across 7 scored dimensions. Here\'s what each section means.',
      ),
      DocSection(heading: 'Overall Score'),
      DocSection(
        body: 'A single score out of 100 summarising all 7 dimensions. 80+ is excellent, 60–79 is good, below 60 suggests trade-offs worth investigating.',
      ),
      DocSection(heading: 'The 7 Dimensions'),
      DocSection(
        table: [
          ('🚇 Transport',    'Metro, bus, rail, and cycling access'),
          ('🎓 Education',    'Schools, universities, and libraries'),
          ('🏥 Health',       'Hospitals, clinics, and pharmacies'),
          ('🛡 Safety',       'Emergency services and safety indicators'),
          ('🛍 Lifestyle',    'Restaurants, cafés, shops, and culture'),
          ('🌳 Nature',       'Parks, green spaces, and recreation'),
          ('💼 Investment',   'Property trend signals and market data'),
        ],
      ),
      DocSection(heading: 'AI Summary'),
      DocSection(
        body: 'An AI-generated paragraph describing the neighbourhood\'s character — written to give you the feel of the area, not just numbers.',
      ),
      DocSection(heading: 'Historical Timeline'),
      DocSection(
        body: 'The Timeline tab shows how scores have evolved over time, with a chart view, category evolution bars, and key milestones.',
      ),
      DocSection(heading: 'Time Machine'),
      DocSection(
        body: 'Below the timeline, the Time Machine visualises a typical day in the neighbourhood — morning activity, afternoon pace, and evening energy.',
      ),
      DocSection(
        tip: 'Tap the Compare button in the action bar to add this location to a side-by-side comparison (Pro feature).',
      ),
    ],
  ),

  // ── Features ───────────────────────────────────────────────────────────────

  DocArticle(
    id: 'explore-tab',
    title: 'Explore Neighbourhoods',
    subtitle: 'Browse hand-picked areas without searching',
    icon: Icons.explore_rounded,
    color: _orange,
    category: 'Features',
    sections: [
      DocSection(
        body: 'The Explore tab gives you a curated map of notable neighbourhoods in Portugal — great for discovering areas you haven\'t considered yet.',
      ),
      DocSection(heading: 'Browse the grid'),
      DocSection(
        body: 'Scroll through the grid of neighbourhood cards. Each card shows the area name, its main character, and a quick tag for what it\'s known for.',
      ),
      DocSection(heading: 'Filter by category'),
      DocSection(
        body: 'Use the filter chips at the top to narrow down by what matters to you: Transport, Family, Investment, Nature, or Culture.',
      ),
      DocSection(heading: 'Open a neighbourhood'),
      DocSection(
        body: 'Tap any card to open the full Neighbourhood Report for that area — same score breakdown, AI summary, and timeline as a manual search.',
      ),
      DocSection(
        tip: 'Explore is great for investors: filter by Investment to see which areas have the strongest property signals.',
      ),
    ],
  ),

  DocArticle(
    id: 'compare-properties',
    title: 'Compare Properties',
    subtitle: 'Side-by-side score comparison across locations',
    icon: Icons.compare_arrows_rounded,
    color: _blue,
    category: 'Features',
    sections: [
      DocSection(
        body: 'With Pro, you can add up to 10 properties to a comparison list and see all their scores side by side — making it easy to spot which location wins on what dimension.',
      ),
      DocSection(heading: 'Adding a property to Compare'),
      DocSection(
        body: 'After getting insights for an address, tap the Compare chip in the action bar below the score. The property is added to your comparison list.',
      ),
      DocSection(heading: 'Opening the Compare view'),
      DocSection(
        body: 'Tap the Compare button again (now showing how many properties you have saved) to open the full side-by-side table.',
      ),
      DocSection(heading: 'Reading the comparison table'),
      DocSection(
        body: 'The table shows each property as a column, with all 7 dimension scores as rows. The highest score in each row is highlighted so you can see the winner at a glance.',
      ),
      DocSection(
        tip: 'Free users can compare up to 2 properties. Upgrade to Pro for up to 10.',
      ),
    ],
  ),

  DocArticle(
    id: 'neighbourhood-alerts',
    title: 'Neighbourhood Alerts',
    subtitle: 'Get notified when scores change in areas you follow',
    icon: Icons.notifications_active_rounded,
    color: _purple,
    category: 'Features',
    sections: [
      DocSection(
        body: 'Neighbourhood Alerts let you follow areas and get notified when their scores change — useful for tracking investments or monitoring a neighbourhood before you buy.',
      ),
      DocSection(heading: 'Setting an alert'),
      DocSection(
        body: 'Open a Neighbourhood Report and tap the Follow chip in the action bar. Choose the alert type: score drop, score rise, or any change.',
      ),
      DocSection(heading: 'Alert types'),
      DocSection(
        table: [
          ('Any change',   'Notified whenever the overall score moves'),
          ('Score drop',   'Only notified if the score falls'),
          ('Score rise',   'Only notified if the score improves'),
          ('Category',     'Alerts for a specific dimension only'),
        ],
      ),
      DocSection(heading: 'Managing alerts'),
      DocSection(
        body: 'All active alerts are listed in the Alerts screen (accessible from the action bar or from You tab). Tap an alert to edit or remove it.',
      ),
      DocSection(
        table: [
          ('Free',     '1 alert'),
          ('Pro',      'Up to 10 alerts'),
          ('Premium',  'Up to 99 alerts with push notifications'),
        ],
      ),
    ],
  ),

  DocArticle(
    id: 'timeline-history',
    title: 'Timeline & Time Machine',
    subtitle: 'See how a neighbourhood has changed over time',
    icon: Icons.timeline_rounded,
    color: _cyan,
    category: 'Features',
    sections: [
      DocSection(
        body: 'The Timeline tab inside any Neighbourhood Report shows the history of that location\'s scores and brings the area to life through the Time Machine.',
      ),
      DocSection(heading: 'Score Journey chart'),
      DocSection(
        body: 'A line chart showing how the overall score has grown or declined over the past 7 periods. Useful for spotting improving or declining areas.',
      ),
      DocSection(heading: 'Category Evolution'),
      DocSection(
        body: 'Horizontal bars for each of the 7 dimensions show relative change — which categories drove the overall trend.',
      ),
      DocSection(heading: 'Key Milestones'),
      DocSection(
        body: 'A vertical timeline of notable events affecting the neighbourhood — new transport links, development approvals, and infrastructure changes.',
      ),
      DocSection(heading: 'Time Machine'),
      DocSection(
        body: 'Below the timeline, the Time Machine visualises a typical 24-hour day in the neighbourhood: the morning rush, afternoon quiet, and evening energy — giving you a feel for daily life.',
      ),
      DocSection(
        tip: 'The Timeline tab is available to all users. Historical data goes back up to 7 periods.',
      ),
    ],
  ),

  // ── Settings ───────────────────────────────────────────────────────────────

  DocArticle(
    id: 'settings-profile',
    title: 'Settings & Profile',
    subtitle: 'Customise HomeScope to match your priorities',
    icon: Icons.tune_rounded,
    color: _red,
    category: 'Settings',
    sections: [
      DocSection(
        body: 'The You tab lets you personalise HomeScope so the analysis reflects what matters most to you.',
      ),
      DocSection(heading: 'Profile'),
      DocSection(
        body: 'Choose a profile to weight the scoring towards your situation:',
      ),
      DocSection(
        table: [
          ('🏠 General',     'Balanced across all dimensions'),
          ('👨‍👩‍👧 Family',    'Weights Education and Safety higher'),
          ('🎓 Student',     'Weights Transport and Lifestyle'),
          ('💼 Professional','Weights Transport and Investment'),
          ('🌿 Retired',     'Weights Nature, Health, and Safety'),
          ('📈 Investor',    'Weights Investment and Transport'),
        ],
      ),
      DocSection(heading: 'Country'),
      DocSection(
        body: 'Select your target country from the dropdown. This filters address search results and optimises data sources for that region.',
      ),
      DocSection(heading: 'Search Radius'),
      DocSection(
        body: 'Set how wide an area HomeScope scans when analysing amenities. Drag the slider between 500m and 5km. A larger radius suits rural areas; a smaller one suits dense cities.',
      ),
      DocSection(heading: 'Appearance'),
      DocSection(
        body: 'Switch between System (follows your device), Light, and Dark themes.',
      ),
      DocSection(heading: 'AI Features'),
      DocSection(
        body: 'Toggle the AI Neighbourhood Summary on or off. When on, OpenAI generates a paragraph describing the area\'s character.',
      ),
    ],
  ),

  DocArticle(
    id: 'go-pro',
    title: 'Go Pro',
    subtitle: 'Unlock the full HomeScope toolkit',
    icon: Icons.workspace_premium_rounded,
    color: _purple,
    category: 'Settings',
    sections: [
      DocSection(
        body: 'HomeScope has three tiers. Here\'s what each unlocks:',
      ),
      DocSection(heading: 'Free'),
      DocSection(
        table: [
          ('Property comparisons',  '2'),
          ('Neighbourhood alerts',  '1'),
          ('Core analysis & maps',  '✓'),
          ('AI summary',            '✓'),
        ],
      ),
      DocSection(heading: 'Pro — €7.99/mo'),
      DocSection(
        table: [
          ('Property comparisons',  'Unlimited'),
          ('Neighbourhood alerts',  '10'),
          ('Priority analysis',     '✓'),
          ('Historical timeline',   '✓'),
        ],
      ),
      DocSection(heading: 'Premium — €14.99/mo'),
      DocSection(
        table: [
          ('Everything in Pro',        '✓'),
          ('Neighbourhood alerts',     '99 with push'),
          ('AI investment insights',   '✓'),
          ('Trend forecasting',        '✓'),
        ],
      ),
      DocSection(heading: 'How to upgrade'),
      DocSection(
        body: 'Tap any Pro-gated feature (Compare, Alerts) and you\'ll be taken to the upgrade screen. Or go to You tab → tap your profile card → Upgrade.',
      ),
      DocSection(heading: 'Restoring purchases'),
      DocSection(
        body: 'If you reinstall the app or switch devices, tap Restore purchases on the upgrade screen to recover your subscription.',
      ),
    ],
  ),

];
