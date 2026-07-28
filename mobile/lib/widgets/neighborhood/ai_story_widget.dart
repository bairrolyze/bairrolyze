import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/score_model.dart';

// Persona definitions — shapes what the story focuses on
class _Persona {
  final String id;
  final String label;
  final String emoji;
  final List<String> priorities; // category ids in priority order

  const _Persona(this.id, this.label, this.emoji, this.priorities);
}

class AIStoryWidget extends StatefulWidget {
  // We use AnalysisResult directly but only need score + aiSummary
  final dynamic result; // AnalysisResult
  final double topPadding;

  const AIStoryWidget({super.key, required this.result, this.topPadding = 100});

  @override
  State<AIStoryWidget> createState() => _AIStoryWidgetState();
}

class _AIStoryWidgetState extends State<AIStoryWidget>
    with SingleTickerProviderStateMixin {
  static const _personas = [
    _Persona('default', 'Overview', '🏠', ['transportation', 'healthcare', 'education', 'recreation']),
    _Persona('family', 'Family', '👨‍👩‍👧‍👦', ['education', 'safety', 'healthcare', 'recreation']),
    _Persona('professional', 'Professional', '💼', ['transportation', 'recreation', 'shopping', 'healthcare']),
    _Persona('student', 'Student', '🎓', ['transportation', 'recreation', 'shopping', 'education']),
    _Persona('retired', 'Retired', '🌿', ['healthcare', 'recreation', 'safety', 'transportation']),
    _Persona('investor', 'Investor', '📈', ['transportation', 'shopping', 'education', 'healthcare']),
  ];

  int _personaIndex = 0;
  late AnimationController _typeCtrl;
  late Animation<double> _typeAnim;

  @override
  void initState() {
    super.initState();
    _typeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _typeAnim = CurvedAnimation(parent: _typeCtrl, curve: Curves.easeOut);
    Future.delayed(500.ms, () { if (mounted) _typeCtrl.forward(); });
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    super.dispose();
  }

  void _switchPersona(int idx) {
    setState(() => _personaIndex = idx);
    _typeCtrl.reset();
    Future.delayed(100.ms, () { if (mounted) _typeCtrl.forward(); });
  }

  String _generateStory(_Persona persona, LocationScore score) {
    final cats = score.categories;
    final overall = score.overall.round();

    String _adj(double s) {
      if (s >= 85) return 'excellent';
      if (s >= 70) return 'good';
      if (s >= 55) return 'moderate';
      return 'limited';
    }

    String _grade(double s) {
      if (s >= 85) return 'stands out';
      if (s >= 70) return 'performs well';
      if (s >= 55) return 'holds its own';
      return 'has room to grow';
    }

    final top = persona.priorities
        .where((id) => cats.containsKey(id))
        .map((id) => cats[id]!)
        .toList();

    switch (persona.id) {
      case 'family':
        final edu = cats['education'];
        final safe = cats['safety'];
        final health = cats['healthcare'];
        final rec = cats['recreation'];
        return 'For families, this neighbourhood scores $overall out of 100 — '
            '${overall >= 70 ? 'a solid foundation for family life' : 'a work in progress with potential'}. '
            '${edu != null ? 'Education access is ${_adj(edu.score)}, with ${edu.count} schools and learning facilities nearby. ' : ''}'
            '${safe != null ? 'Safety infrastructure ${_grade(safe.score)}, giving parents ${safe.score >= 70 ? 'peace of mind' : 'something to factor in'}. ' : ''}'
            '${health != null ? 'Healthcare is ${_adj(health.score)} — ${health.closest != null ? '${health.closest!.name} is the closest facility at ${health.closest!.walkingMinutes} minutes\' walk' : 'clinics are accessible'}. ' : ''}'
            '${rec != null ? 'Recreational spaces for the kids are ${_adj(rec.score)}.' : ''}';

      case 'professional':
        final transit = cats['transportation'];
        final rec = cats['recreation'];
        return 'For young professionals, this area scores $overall — '
            '${overall >= 70 ? 'a strong base for an active urban lifestyle' : 'functional, with tradeoffs worth considering'}. '
            '${transit != null ? 'Transit connectivity is ${_adj(transit.score)}, ${transit.score >= 70 ? 'making the daily commute manageable' : 'so a car may be useful'}. ' : ''}'
            '${rec != null ? 'After-work recreation options are ${_adj(rec.score)} — ${rec.count} parks, gyms and leisure spots within reach. ' : ''}'
            'The overall amenity density suggests a ${overall >= 70 ? 'lively' : 'quieter'} neighbourhood with ${overall >= 70 ? 'plenty to do' : 'room to develop'}.';

      case 'student':
        final transit = cats['transportation'];
        final shop = cats['shopping'];
        final edu = cats['education'];
        return 'For students, the location scores $overall. '
            '${transit != null ? 'Getting around is ${_adj(transit.score)} — ${transit.count} transit options mean ${transit.score >= 70 ? 'cheap and easy travel' : 'some planning may be needed'}. ' : ''}'
            '${shop != null ? 'Day-to-day shopping is ${_adj(shop.score)}, with ${shop.count} spots for groceries and essentials. ' : ''}'
            '${edu != null ? 'Academic resources ${_grade(edu.score)} with ${edu.count} educational institutions in the area. ' : ''}'
            'Overall, this ${overall >= 65 ? 'is a practical and social base' : 'is affordable with some lifestyle compromises'}.';

      case 'retired':
        final health = cats['healthcare'];
        final rec = cats['recreation'];
        final transit = cats['transportation'];
        return 'For those in retirement, peace of mind matters most — and this neighbourhood scores $overall. '
            '${health != null ? 'Healthcare accessibility is ${_adj(health.score)}, ${health.closest != null ? 'with ${health.closest!.name} just ${health.closest!.walkingMinutes} minutes away' : 'with clinics in reach'}. ' : ''}'
            '${rec != null ? 'Green spaces and recreation score ${rec.score.round()}/100 — ${rec.score >= 70 ? 'lovely for daily walks and relaxation' : 'limited but present'}. ' : ''}'
            '${transit != null ? 'Getting around without a car is ${_adj(transit.score)}.' : ''}';

      case 'investor':
        final transit = cats['transportation'];
        final shop = cats['shopping'];
        return 'From an investment perspective, this location scores $overall. '
            '${transit != null ? 'Transit links are ${_adj(transit.score)} — a key driver of long-term value. ' : ''}'
            '${shop != null ? 'Commercial activity is ${_adj(shop.score)}, suggesting ${shop.score >= 70 ? 'strong footfall and economic activity' : 'an area still maturing commercially'}. ' : ''}'
            'With ${score.categories.values.fold(0, (s, c) => s + c.count)} total amenities indexed, '
            'the density points to a neighbourhood that ${overall >= 70 ? 'already commands attention' : 'may appreciate with continued development'}.';

      default:
        final aiSummary = widget.result.aiSummary as String?;
        if (aiSummary != null && aiSummary.isNotEmpty) return aiSummary;
        return 'This neighbourhood scores $overall out of 100 across ${cats.length} key categories. '
            '${top.isNotEmpty ? '${top.first.label} leads at ${top.first.score.round()}/100. ' : ''}'
            'With ${score.categories.values.fold(0, (s, c) => s + c.count)} local amenities mapped within walking distance, '
            'the area ${overall >= 70 ? 'offers strong everyday convenience' : 'provides the basics with room to grow'}. '
            '${overall >= 80 ? 'A well-rounded choice for most lifestyles.' : overall >= 60 ? 'A decent option worth exploring in person.' : 'Consider the tradeoffs carefully before committing.'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.result.score as LocationScore;
    final persona = _personas[_personaIndex];
    final story = _generateStory(persona, score);

    // Extract top and bottom performing categories
    final sorted = score.categories.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final strengths = sorted.take(3).toList();
    final cautions = sorted.reversed.take(2).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: widget.topPadding + 32, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NARRATIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                    height: 1,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 10),
                const Text(
                  'AI Story',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.0,
                    height: 1.05,
                  ),
                ).animate(delay: 60.ms).fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0),
                const SizedBox(height: 16),
                Text(
                  'Your neighbourhood through a human lens.\nChoose your perspective.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                  ),
                ).animate(delay: 120.ms).fadeIn(duration: 500.ms),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Persona selector
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _personas.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = _personas[i];
                final active = i == _personaIndex;
                return GestureDetector(
                  onTap: () => _switchPersona(i),
                  child: AnimatedContainer(
                    duration: 250.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: active
                          ? const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9C63FF)])
                          : null,
                      color: active ? null : Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(22),
                      border: active ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.emoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 6),
                        Text(
                          p.label,
                          style: TextStyle(
                            color: active ? Colors.white : Colors.white60,
                            fontSize: 13,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ).animate(delay: 200.ms).fadeIn(),

          const SizedBox(height: 20),

          // Story card
          AnimatedBuilder(
            animation: _typeAnim,
            builder: (_, __) {
              final visibleLen = (story.length * _typeAnim.value).round().clamp(0, story.length);
              final displayText = story.substring(0, visibleLen);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.12),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF9C63FF)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(persona.emoji, style: const TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${persona.label} Perspective',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const Text(
                              'AI-generated neighbourhood narrative',
                              style: TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: Color(0xFF6C63FF), size: 11),
                              SizedBox(width: 3),
                              Text('AI', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 10, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      displayText + (_typeAnim.value < 1 ? '▌' : ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.7,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              );
            },
          ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),

          const SizedBox(height: 20),

          // Strengths
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Key Strengths', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: strengths.map((c) => _InsightChip(
                    label: '${c.label}  ${c.score.round()}',
                    color: const Color(0xFF66BB6A),
                    icon: Icons.arrow_upward_rounded,
                  )).toList(),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn(),

          const SizedBox(height: 16),

          // Considerations
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Consider', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cautions.map((c) => _InsightChip(
                    label: '${c.label}  ${c.score.round()}',
                    color: const Color(0xFFFFA726),
                    icon: Icons.info_outline_rounded,
                  )).toList(),
                ),
              ],
            ),
          ).animate(delay: 500.ms).fadeIn(),
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _InsightChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
