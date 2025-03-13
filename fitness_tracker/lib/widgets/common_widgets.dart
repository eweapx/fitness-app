import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// A custom button with a standardized style
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isOutlined;
  final bool isFullWidth;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isOutlined = false,
    this.isFullWidth = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? AppColors.primary;
    
    if (isOutlined) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _buildButtonContent(color),
        ),
      );
    } else {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor ?? Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _buildButtonContent(textColor ?? Colors.white),
        ),
      );
    }
  }

  Widget _buildButtonContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}

/// A section card with a title and content
class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading3,
                ),
                if (trailing != null) trailing!,
                if (onTap != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: onTap,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A custom progress bar with label
class LabeledProgressBar extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color? color;
  final bool showPercentage;

  const LabeledProgressBar({
    super.key,
    required this.label,
    required this.value,
    required this.progress,
    this.color,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(
              showPercentage ? '${(progress * 100).toInt()}% | $value' : value,
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.primary),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

/// A stat card with icon, value and label
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color ?? AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A loading indicator with optional message
class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}

/// An empty state widget with icon and message
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              AppButton(
                label: actionLabel!,
                onPressed: onAction!,
                icon: Icons.add,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A circular progress indicator with percentage and label
class CircularPercentIndicator extends StatelessWidget {
  final double percent;
  final String label;
  final String? centerText;
  final Color? color;
  final double radius;
  final double lineWidth;

  const CircularPercentIndicator({
    super.key,
    required this.percent,
    required this.label,
    this.centerText,
    this.color,
    this.radius = 60.0,
    this.lineWidth = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final finalPercent = percent > 1.0 ? 1.0 : percent;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: radius * 2,
              width: radius * 2,
              child: CircularProgressIndicator(
                value: finalPercent,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? AppColors.primary,
                ),
                strokeWidth: lineWidth,
              ),
            ),
            Text(
              centerText ?? '${(finalPercent * 100).toInt()}%',
              style: AppTextStyles.heading3,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

/// A custom app bar with back button and actions
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => bottom == null
      ? const Size.fromHeight(kToolbarHeight)
      : Size.fromHeight(kToolbarHeight + bottom!.preferredSize.height);
}

/// A date selector widget
class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final bool showPrevNext;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.showPrevNext = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showPrevNext)
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            onPressed: () {
              onDateSelected(
                selectedDate.subtract(const Duration(days: 1)),
              );
            },
          ),
        GestureDetector(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (pickedDate != null) {
              onDateSelected(pickedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  _getDisplayDate(selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        if (showPrevNext)
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {
              final tomorrow = selectedDate.add(const Duration(days: 1));
              if (!tomorrow.isAfter(DateTime.now())) {
                onDateSelected(tomorrow);
              }
            },
          ),
      ],
    );
  }

  String _getDisplayDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (selectedDay == yesterday) {
      return 'Yesterday';
    } else if (selectedDay == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}