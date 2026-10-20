import 'package:core_theme/core_theme.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart';

Widget _home() => Builder(
      builder: (context) {
        final c = SuiteColors.of(context);
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.lg,
            AppSpacing.gutter,
            AppSpacing.xl,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tuesday, 20 October',
                        style: AppTextStyles.label.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Good evening, Sara',
                        style: AppTextStyles.h2.copyWith(color: c.textPrimary),
                      ),
                    ],
                  ),
                ),
                const IconBadge(monogram: 'S', size: 40),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            HeroMetricCard(
              label: 'Left to spend · October',
              trailing: const DeltaBadge(
                delta: 0,
                label: '11 days left',
                polarity: DeltaPolarity.neutral,
              ),
              value: const MoneyText(
                48250.75,
                currency: 'Rs',
                style: AppTextStyles.hero,
              ),
              delta: const DeltaBadge(
                delta: -8.4,
                polarity: DeltaPolarity.upIsBad,
              ),
              deltaCaption: 'less spent than this time last month',
              trend: const [
                12,
                18,
                15,
                22,
                26,
                24,
                31,
                29,
                35,
                38,
                36,
                41,
              ],
              footer: const [
                StatTile(label: 'Income', value: 'Rs 185,000'),
                StatTile(label: 'Spent', value: 'Rs 136,749'),
                StatTile(label: 'Saved', value: '26%'),
              ],
            ),
            const SizedBox(height: AppSpacing.smd),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Groceries',
                    icon: Icons.shopping_basket_outlined,
                    value: const MoneyText(
                      18420,
                      currency: 'Rs',
                      decimals: 0,
                      style: AppTextStyles.numberMedium,
                    ),
                    caption: 'of Rs 24,000',
                    visual: const AppProgressBar(value: 0.77, marker: 0.64),
                  ),
                ),
                const SizedBox(width: AppSpacing.smd),
                Expanded(
                  child: MetricCard(
                    label: 'Dining out',
                    icon: Icons.restaurant_outlined,
                    value: const MoneyText(
                      9860,
                      currency: 'Rs',
                      decimals: 0,
                      style: AppTextStyles.numberMedium,
                    ),
                    caption: 'of Rs 8,000',
                    visual: const AppProgressBar(value: 1.23, marker: 0.64),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.smd),
            VaultCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'This week',
                          style: AppTextStyles.label.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                      const DeltaBadge(
                        delta: 12.5,
                        polarity: DeltaPolarity.upIsBad,
                        subtle: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const MoneyText(
                    21305.5,
                    currency: 'Rs',
                    style: AppTextStyles.numberLarge,
                  ),
                  const SizedBox(height: AppSpacing.mdl),
                  const MiniBarChart(
                    values: [3200, 1800, 4100, 2500, 5300, 2900, 1505],
                    labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                    highlightIndex: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(
              title: 'Recent',
              subtitle: '4 transactions today',
              actionLabel: 'See all',
              onAction: () {},
            ),
            RowGroup(
              children: [
                AppListRow(
                  leading: IconBadge(
                    icon: Icons.local_cafe_outlined,
                    color: c.chart[2],
                  ),
                  title: 'Coffee Lab',
                  subtitle: 'Dining · Card',
                  trailing: const MoneyText(-650, currency: 'Rs'),
                  trailingSubtitle: '09:12',
                ),
                AppListRow(
                  leading: IconBadge(
                    icon: Icons.work_outline_rounded,
                    color: c.positive,
                  ),
                  title: 'Salary — Northwind',
                  subtitle: 'Income · Bank transfer',
                  trailing: const MoneyText(
                    185000,
                    currency: 'Rs',
                    tone: MoneyTone.signed,
                    showPlus: true,
                  ),
                  trailingSubtitle: '08:00',
                ),
                AppListRow(
                  leading: IconBadge(
                    icon: Icons.directions_car_outlined,
                    color: c.chart[1],
                  ),
                  title: 'Fuel',
                  subtitle: 'Transport · Cash',
                  trailing: const MoneyText(-4200, currency: 'Rs'),
                  trailingSubtitle: 'Yesterday',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Where it went'),
            VaultCard(
              child: Row(
                children: [
                  DonutChart(
                    size: 128,
                    segments: const [
                      DonutSegment(value: 42),
                      DonutSegment(value: 24),
                      DonutSegment(value: 18),
                      DonutSegment(value: 10),
                      DonutSegment(value: 6),
                    ],
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '74%',
                          style: AppTextStyles.numberMedium.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                        Text(
                          'of budget',
                          style: AppTextStyles.caption.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.mdl),
                  Expanded(
                    child: Column(
                      children: [
                        for (final (i, l, v) in [
                          (0, 'Housing', '42%'),
                          (1, 'Transport', '24%'),
                          (2, 'Food', '18%'),
                          (3, 'Health', '10%'),
                          (4, 'Other', '6%'),
                        ])
                          ChartLegendRow(
                            color: c.chart[i],
                            label: l,
                            value: Text(
                              v,
                              style: AppTextStyles.numberSmall.copyWith(
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

Widget _components() => Builder(
      builder: (context) {
        final c = SuiteColors.of(context);
        Widget label(String t) => Padding(
              padding: const EdgeInsets.only(top: 22, bottom: 10),
              child: Text(
                t.toUpperCase(),
                style: AppTextStyles.overline.copyWith(color: c.textTertiary),
              ),
            );
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            label('Inputs'),
            AppTextField(
              controller: TextEditingController(text: 'sara@offlyne.app'),
              label: 'Email',
            ),
            const SizedBox(height: 12),
            const AppTextField(
              label: 'Master password',
              obscureText: true,
              helper: 'At least 12 characters',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: TextEditingController(text: '12,5OO'),
              label: 'Amount',
              prefixText: 'Rs ',
              errorText: 'Use digits only',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: TextEditingController(text: 'Groceries'),
              label: 'Note',
              fieldStyle: AppFieldStyle.underline,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: TextEditingController(text: 'k7#Qv9!pL2xW'),
              label: 'Generated',
              monospace: true,
              fieldStyle: AppFieldStyle.outlined,
            ),
            const SizedBox(height: 16),
            AppSearchField(
              hint: 'Search transactions',
              trailing: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded, size: 20),
              ),
            ),
            label('Selection'),
            AppSegmentedControl<int>(
              segments: const [
                AppSegment(value: 0, label: 'Week'),
                AppSegment(value: 1, label: 'Month'),
                AppSegment(value: 2, label: 'Year'),
              ],
              selected: 1,
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppChip(label: 'All', selected: true, onTap: () {}),
                AppChip(label: 'Food', color: c.chart[2], count: 12),
                AppChip(label: 'Transport', color: c.chart[1], count: 4),
                const AppChip(label: 'Recurring', icon: Icons.repeat_rounded),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(value: true, onChanged: (_) {}),
                Switch(value: false, onChanged: (_) {}),
                Checkbox(value: true, onChanged: (_) {}),
                Expanded(child: Slider(value: 0.6, onChanged: (_) {})),
              ],
            ),
            label('Buttons'),
            VaultButton(label: 'Save transaction', onPressed: () {}),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: VaultButton(
                    label: 'Export',
                    icon: Icons.ios_share_rounded,
                    variant: VaultButtonVariant.secondary,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: VaultButton(
                    label: 'Delete',
                    variant: VaultButtonVariant.destructive,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                VaultButton(
                  label: 'Add',
                  icon: Icons.add_rounded,
                  compact: true,
                  isFullWidth: false,
                  onPressed: () {},
                ),
                const SizedBox(width: 10),
                const VaultButton(
                  label: 'Saving',
                  isLoading: true,
                  compact: true,
                  isFullWidth: false,
                  onPressed: null,
                ),
                const SizedBox(width: 10),
                TextButton(onPressed: () {}, child: const Text('Not now')),
              ],
            ),
            label('Feedback'),
            AppBanner(
              title: '3 weak passwords',
              message: 'Reused on more than one site.',
              kind: BannerKind.warning,
              onTap: () {},
            ),
            const SizedBox(height: 8),
            const AppBanner(
              title: 'Backup complete',
              message: 'Encrypted · 2.4 MB · just now',
              kind: BannerKind.success,
            ),
            const SizedBox(height: 12),
            const AppProgressBar(value: 0.42),
            const SizedBox(height: 12),
            const SegmentedBar(values: [42, 24, 18, 10, 6]),
            const SizedBox(height: 12),
            const RowGroup(children: [SkeletonRow(), SkeletonRow()]),
            label('Rows'),
            RowGroup(
              children: [
                SettingsTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Unlock with fingerprint',
                  trailing: Switch(value: true, onChanged: (_) {}),
                ),
                SettingsTile(
                  icon: Icons.backup_outlined,
                  title: 'Backups',
                  subtitle: 'Weekly · last run 2 days ago',
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  trailing: Text(
                    'System',
                    style: AppTextStyles.label.copyWith(color: c.textSecondary),
                  ),
                ),
              ],
            ),
            label('Empty'),
            VaultCard(
              child: AppEmptyState(
                compact: true,
                icon: Icons.receipt_long_outlined,
                title: 'No transactions yet',
                message: 'Add one, or capture from a notification.',
                action: VaultButton(
                  label: 'Add transaction',
                  compact: true,
                  isFullWidth: false,
                  onPressed: () {},
                ),
              ),
            ),
            const SizedBox(height: 12),
            BottomActionBar(
              summary: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: AppTextStyles.caption.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                  const MoneyText(
                    12500,
                    currency: 'Rs',
                    style: AppTextStyles.number,
                  ),
                ],
              ),
              primary: VaultButton(
                label: 'Split',
                isFullWidth: false,
                onPressed: () {},
              ),
            ),
          ],
        );
      },
    );

void main() {
  setUpAll(loadGalleryFonts);

  testWidgets(
    'gallery: home dashboard',
    (tester) => renderBoard(tester, 'home', _home, height: 1640),
    skip: galleryOut == null,
  );

  testWidgets(
    'gallery: components',
    (tester) => renderBoard(tester, 'components', _components, height: 1980),
    skip: galleryOut == null,
  );

  for (final (name, accent) in [
    ('vaultly', AppAccents.vaultly),
    ('reflect', AppAccents.reflect),
    ('warden', AppAccents.warden),
  ]) {
    testWidgets(
      'gallery: home in $name accent',
      (tester) => renderBoard(
        tester,
        'home-$name',
        _home,
        accent: accent,
        height: 900,
      ),
      skip: galleryOut == null,
    );
  }
}
