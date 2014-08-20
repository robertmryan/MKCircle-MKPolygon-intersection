### Circle and Polygon Test

This illustrates a technique to detect whether a `MKCircle` and a `MKPolygon` intersect. More accurately, it detects whether the resulting `MKCircleView` and the `MKPolygonView` intersect. 

This test app provides a user interface for adding an arbitrary circle and arbitrary polygon to a `MKMapView`, and the status label updates with "Yes" or "No", indicating whether the circle and polygon intersect or not.

See point #2 at http://stackoverflow.com/a/18668955/1271826 for more information about the techniques employed here.

#### Limitations

- This has not been tested across the Meridian or at the poles.

- Was developed using Xcode 4.6.3 on iOS 6.1 target. Also tested in Xcode 5.1.1 on iOS 7.1 target. This demonstration happens to use autolayout, but you could obviously convert to springs and struts if you need to support iOS 5. This also happens to use storyboards, but you could obviously convert to NIBs if you need to support iOS versions prior to 5.

- This is a proof of concept. Use at your own risk.

---

Robert M. Ryan<br />
August 7, 2013
