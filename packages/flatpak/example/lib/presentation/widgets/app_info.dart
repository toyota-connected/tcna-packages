import 'package:flutter/material.dart';
import '../../responsive.dart';

class AppInfo extends StatelessWidget {
  const AppInfo({
    super.key,
    required this.version,
    required this.size,
    required this.last_upadate,
    required this.License,
    required this.url,
    required this.content_rating,
  });

  final String version;
  final String size;
  final String last_upadate;
  final String License;
  final String url;
  final String content_rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // left column
        Expanded(
          flex: 1,
          child: Padding(
            padding: Responsive.paddingAll(context, 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Version from releases
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Version",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontFamily: 'general-sans',
                      ),
                    ),
                    Responsive.vGap(context, 4),
                    Text(
                      version,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontFamily: 'general-sans',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Responsive.vGap(context, 16),

                /// Size
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Installed Size",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontFamily: 'general-sans',
                      ),
                    ),
                    Responsive.vGap(context, 4),
                    Text(
                      size,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontFamily: 'general-sans',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Responsive.vGap(context, 16),

                /// Last Update
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Last Update",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontFamily: 'general-sans',
                      ),
                    ),
                    Responsive.vGap(context, 4),
                    Text(
                      last_upadate,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontFamily: 'general-sans',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        Spacer(),

        // right column
        Expanded(
          flex: 1,
          child: Padding(
            padding: Responsive.paddingAll(context, 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// License
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "License",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontFamily: 'general-sans',
                      ),
                    ),
                    Responsive.vGap(context, 4),
                    Text(
                      License,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontFamily: 'general-sans',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                Responsive.vGap(context, 16),

                /// Developer
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Developer",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontFamily: 'general-sans',
                      ),
                    ),
                    Responsive.vGap(context, 4),
                    GestureDetector(
                      /// onTap: onTap, TODO: Add UrlLauncher
                      child: Text(
                        url,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'general-sans',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Responsive.vGap(context, 16),

                /// Content Rating
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Content Rating",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontFamily: 'general-sans',
                      ),
                    ),
                    Responsive.vGap(context, 4),
                    Text(
                      content_rating,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
