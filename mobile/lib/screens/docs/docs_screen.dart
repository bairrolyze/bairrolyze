import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import 'doc_article_screen.dart';
import 'docs_content.dart';

class DocsScreen extends StatelessWidget {
  const DocsScreen({super.key});

  static Future<void> show(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DocsScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final p      = AppPalette.of(context);

    // Group articles by category
    final categories = <String, List<DocArticle>>{};
    for (final a in kDocArticles) {
      categories.putIfAbsent(a.category, () => []).add(a);
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.border),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: p.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Guides & Help',
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Intro card ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.18),
                      const Color(0xFF7C3AED).withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.menu_book_rounded,
                          color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Everything you need to know',
                              style: TextStyle(
                                color: p.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(height: 2),
                          Text('${kDocArticles.length} guides covering every feature',
                              style: TextStyle(
                                color: p.textTertiary,
                                fontSize: 12,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Category sections ────────────────────────────────────────────
          for (final entry in categories.entries) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text(
                  entry.key.toUpperCase(),
                  style: TextStyle(
                    color: p.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: entry.value.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final article = entry.value[i];
                  return _ArticleRow(article: article);
                },
              ),
            ),
          ],

          SliverToBoxAdapter(child: SizedBox(height: bottom + 40)),
        ],
      ),
    );
  }
}

// ── Article list row ──────────────────────────────────────────────────────────

class _ArticleRow extends StatelessWidget {
  final DocArticle article;
  const _ArticleRow({required this.article});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DocArticleScreen(article: article)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: article.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(article.icon, color: article.color, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  Text(article.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.textTertiary,
                        fontSize: 12,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: p.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
