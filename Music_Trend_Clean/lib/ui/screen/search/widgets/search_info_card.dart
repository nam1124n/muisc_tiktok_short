import 'package:flutter/material.dart';
import 'package:login_flutter/domain/entities/search_plan_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';

class SearchInfoCard extends StatelessWidget {
  final SearchPlanEntity plan;

  const SearchInfoCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chips = [
      ...plan.keywords,
      ...plan.artistHints,
      ...plan.titleHints,
      ...plan.tagHints,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.searchSourceLabel(plan.provider.toUpperCase())),
          const SizedBox(height: 6),
          Text(plan.reason),
          if (chips.isNotEmpty) const SizedBox(height: 10),
          if (chips.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .map(
                    (chip) => Chip(
                      label: Text(chip),
                      backgroundColor: const Color(0xFFEDE4FF),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
