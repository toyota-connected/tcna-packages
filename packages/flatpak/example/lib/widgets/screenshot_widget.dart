import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../responsive.dart';

class Screenshot extends StatefulWidget {
  final List<String> images;
  final List<String>? captions;

  const Screenshot({
    super.key,
    required this.images,
    required this.captions,
  });

  @override
  State<StatefulWidget> createState() => _screenshotstate();
}

class _screenshotstate extends State<Screenshot> {
  int _current = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: CarouselSlider(
          items: widget.images.map((imagePath) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.symmetric(
                    horizontal: Responsive.responsiveValue(
                      context,
                      mobile: 4.0,
                      tablet: 6.0,
                      desktop: 8.0,
                    ),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      Responsive.responsiveValue(
                        context,
                        mobile: 8.0,
                        tablet: 12.0,
                        desktop: 16.0,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Responsive.responsiveValue(
                        context,
                        mobile: 8.0,
                        tablet: 12.0,
                        desktop: 16.0,
                      ),
                    ),
                    child: Image.network(
                      imagePath,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                );
              },
            );
          }).toList(),
          carouselController: _controller,
          options: CarouselOptions(
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 16/9,
              viewportFraction: Responsive.isMobile(context) ? 0.9 : 0.8,
              autoPlayInterval: Duration(seconds: 4),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              }),
        ),
      ),
      if (widget.captions != null &&
          widget.captions!.isNotEmpty &&
          _current < widget.captions!.length)
        Padding(
          padding: EdgeInsets.all(
            Responsive.responsiveValue(
              context,
              mobile: 8.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
          ),
          child: Text(
            widget.captions![_current],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: Responsive.responsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              ),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.images.asMap().entries.map((entry) {
          return GestureDetector(
            onTap: () => _controller.animateToPage(entry.key),
            child: Container(
              width: Responsive.responsiveValue(
                context,
                mobile: 8.0,
                tablet: 10.0,
                desktop: 12.0,
              ),
              height: Responsive.responsiveValue(
                context,
                mobile: 8.0,
                tablet: 10.0,
                desktop: 12.0,
              ),
              margin: EdgeInsets.symmetric(
                vertical: Responsive.responsiveValue(
                  context,
                  mobile: 6.0,
                  tablet: 8.0,
                  desktop: 10.0,
                ),
                horizontal: Responsive.responsiveValue(
                  context,
                  mobile: 3.0,
                  tablet: 4.0,
                  desktop: 5.0,
                ),
              ),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black)
                      .withValues(alpha: _current == entry.key ? 0.9 : 0.4)),
            ),
          );
        }).toList(),
      ),
    ]);
  }
}