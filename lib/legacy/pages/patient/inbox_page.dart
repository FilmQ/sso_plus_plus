import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/notice.dart';
import '../../providers/notice_providers.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/info_card.dart';

/// The Inbox destination.
///
/// The application delivers every decision here, so the person never has to
/// ask for an answer.
class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<Notice>> notices = ref.watch(noticesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: AsyncValueView<List<Notice>>(
        value: notices,
        onRetry: () => ref.invalidate(noticesProvider),
        builder: (List<Notice> all) {
          if (all.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Your inbox is empty',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: all.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final Notice notice = all[index];
              return InfoCard(
                tone: notice.isRead
                    ? InfoCardTone.plain
                    : InfoCardTone.highlighted,
                onTap: () async {
                  await ref.read(markNoticeReadProvider)(notice);
                  if (context.mounted) {
                    context.go('/claims/${notice.claimNumber}');
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        if (!notice.isRead) ...<Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            notice.kind.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          Formats.shortDate(notice.sentAt),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notice.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(notice.body, style: theme.textTheme.bodySmall),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
