import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workupdate/domain/job_entry.dart';
import 'package:workupdate/utils/globals.dart';

class JobInfoCard extends StatelessWidget {
  const JobInfoCard({
    required this.job,
    super.key,
  });

  final JobEntry job;

  Future<void> _copyToClipboard(BuildContext context, String link) {
    return Clipboard.setData(ClipboardData(text: link)).then<void>(
      (_) {
        showSnackBar(context, message: 'Link copied to clipboard');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    formatTimeAgo(job.publishedAt),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Pay: ${job.budget}',
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined),
                const SizedBox(width: 5),
                Text(job.country),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  text: 'Category: ',
                  children: [
                    TextSpan(
                      text: job.category,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              job.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                job.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final skill in job.skills) ...[
                    Chip(label: Text(skill)),
                    const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
            InkWell(
              onTap: () async {
                await launchUrl(
                  Uri.parse(job.link),
                  mode: LaunchMode.externalApplication,
                );
              },
              onLongPress: () => _copyToClipboard(context, job.link),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'View on Upwork',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                  // textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
