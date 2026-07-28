import 'package:flutter/material.dart';

import 'docs_content.dart';

const _kBg       = Color(0xFF060B14);
const _kSurface  = Color(0xFF0D1625);
const _kSurface2 = Color(0xFF131F33);
const _kBorder   = Color(0xFF1A2845);

class DocArticleScreen extends StatelessWidget {
  final DocArticle article;
  const DocArticleScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ),
                ),

                // Article hero
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              article.color,
                              article.color.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: article.color.withValues(alpha: 0.30),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(article.icon,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(height: 16),

                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: article.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: article.color.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          article.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: article.color,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        article.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        article.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.48),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Container(height: 1, color: _kBorder),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Content sections ─────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 48),
            sliver: SliverList.separated(
              itemCount: article.sections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) =>
                  _SectionWidget(section: article.sections[i], accentColor: article.color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section renderer ──────────────────────────────────────────────────────────

class _SectionWidget extends StatelessWidget {
  final DocSection section;
  final Color accentColor;

  const _SectionWidget({required this.section, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    // Section heading
    if (section.heading != null && section.body == null &&
        section.tip == null && section.table == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(
          section.heading!,
          style: TextStyle(
            color: accentColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      );
    }

    // Body text (optionally with heading)
    if (section.body != null && section.table == null && section.tip == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.heading != null) ...[
            const SizedBox(height: 16),
            Text(section.heading!,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
          ],
          Text(
            section.body!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14.5,
              height: 1.65,
            ),
          ),
        ],
      );
    }

    // Tip box
    if (section.tip != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_rounded,
                color: accentColor, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                section.tip!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 13.5,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Table
    if (section.table != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: section.table!.asMap().entries.map((entry) {
            final isLast = entry.key == section.table!.length - 1;
            return Container(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.05))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      entry.value.$1,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.$2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
