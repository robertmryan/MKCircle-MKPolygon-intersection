//
//  ViewController.m
//  Circle and Polygon Test
//
//  Created by Robert Ryan on 9/7/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>

@interface ViewController ()

@property (nonatomic, weak) MKCircle *circle;
@property (nonatomic, weak) id<MKOverlay> polygon;

@property (nonatomic, weak) MKCircleView *circleView;
@property (nonatomic, weak) MKPolygonView *polygonView;

@property (nonatomic, weak) UIGestureRecognizer *gesture;
@property (nonatomic, strong) NSMutableArray *locations;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.mapView.userTrackingMode = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineView *view = [[MKPolylineView alloc] initWithOverlay:overlay];
        view.lineWidth = 3.0;
        view.strokeColor = [UIColor blueColor];

        return view;
    } else if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonView *view = [[MKPolygonView alloc] initWithOverlay:overlay];
        view.lineWidth = 3.0;
        view.strokeColor = [UIColor blueColor];
        view.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.8];
        self.polygonView = view;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateIntersectLabel];
        });

        return view;
    } else if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleView *view = [[MKCircleView alloc] initWithOverlay:overlay];
        view.lineWidth = 3.0;
        view.strokeColor = [UIColor blueColor];
        view.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.8];
        self.circleView = view;

        [self updateIntersectLabel];

        return view;
    }

    return nil;
}

#pragma mark - Insection label

- (void)updateIntersectLabel
{
    NSString *string = [self circleAndPolygonIntersect] ? @"Yes" : @"No";

    if (![self.intersectLabel.text isEqualToString:string]) {
        self.intersectLabel.text = string;
    }
}

- (BOOL)circleAndPolygonIntersect
{
    if (!self.circleView || !self.polygonView)
        return NO;

    CGPoint center = [self.mapView convertCoordinate:self.circle.coordinate toPointToView:self.mapView];
    CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:self.circle.coordinate.latitude
                                                            longitude:self.circle.coordinate.longitude];
    CGFloat radius = [self radiusInPoints:self.circle];

    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint lastPoint;
    for (NSInteger i = 0; i < [self.locations count]; i++) {
        // if point is in the circle, then we're done

        if ([centerLocation distanceFromLocation:self.locations[i]] < self.circle.radius)
            return YES;

        // otherwise add line to path

        CGPoint point = [self.mapView convertCoordinate:[self.locations[i] coordinate] toPointToView:self.mapView];
        if (i == 0) {
            [path moveToPoint:point];
        } else {
            CGFloat angle1 = [self angleFromVertex:lastPoint toPoint:point     andPoint:center];
            CGFloat angle2 = [self angleFromVertex:point     toPoint:lastPoint andPoint:center];

            // if the line segment intersected the circle, then we're done

            if (angle1 < M_PI_2 && angle2 < M_PI_2 &&
                [self distanceOfPoint:center fromLineFrom:lastPoint to:point] < radius) {
                return YES;
            }

            [path addLineToPoint:point];
        }
        lastPoint = point;
    }

    if ([path containsPoint:center])
        return YES;

    return NO;
}

- (CGFloat)distanceOfPoint:(CGPoint)point fromLineFrom:(CGPoint)lineStart to:(CGPoint)lineEnd
{
    CGFloat a = lineStart.y - lineEnd.y;
    CGFloat b = lineEnd.x - lineStart.x;
    CGFloat c = lineStart.x * lineEnd.y - lineEnd.x * lineStart.y;

    return fabsf(a * point.x + b * point.y + c) / sqrtf(a*a + b*b);
}

- (CGFloat)radiusInPoints:(MKCircle *)circle
{
    CLLocationCoordinate2D newCoordinate = [self coordinateFromCoord:circle.coordinate
                                                          atDistance:circle.radius
                                                    atBearingDegrees:0.0];
    CGPoint center = [self.mapView convertCoordinate:circle.coordinate toPointToView:self.mapView];
    CGPoint newPoint = [self.mapView convertCoordinate:newCoordinate toPointToView:self.mapView];

    return fabsf(newPoint.y - center.y);
}

// use the law of cosines: http://en.wikipedia.org/wiki/Law_of_cosines

- (CGFloat)angleFromVertex:(CGPoint)pointC toPoint:(CGPoint)pointA andPoint:(CGPoint)pointB
{
    CGFloat a = hypotf(pointB.x - pointC.x, pointB.y - pointC.y);
    CGFloat b = hypotf(pointC.x - pointA.x, pointC.y - pointA.y);
    CGFloat c = hypotf(pointA.x - pointB.x, pointA.y - pointB.y);

    return acosf((a*a + b*b - c*c) / (2.0 * a * b));
}

// from http://stackoverflow.com/questions/6633850/calculate-new-coordinate-x-meters-and-y-degree-away-from-one-coordinate/6634982#6634982

- (double)radiansFromDegrees:(double)degrees
{
    return degrees * (M_PI/180.0);
}

- (double)degreesFromRadians:(double)radians
{
    return radians * (180.0/M_PI);
}

- (CLLocationCoordinate2D)coordinateFromCoord:(CLLocationCoordinate2D)fromCoord
                                   atDistance:(double)distance
                             atBearingDegrees:(double)bearingDegrees
{
    double distanceRadians = distance / 1000.0 / 6371.0;
    //6,371 = Earth's radius in km
    double bearingRadians = [self radiansFromDegrees:bearingDegrees];
    double fromLatRadians = [self radiansFromDegrees:fromCoord.latitude];
    double fromLonRadians = [self radiansFromDegrees:fromCoord.longitude];

    double toLatRadians = asin( sin(fromLatRadians) * cos(distanceRadians)
                               + cos(fromLatRadians) * sin(distanceRadians) * cos(bearingRadians) );

    double toLonRadians = fromLonRadians + atan2(sin(bearingRadians)
                                                 * sin(distanceRadians) * cos(fromLatRadians), cos(distanceRadians)
                                                 - sin(fromLatRadians) * sin(toLatRadians));

    // adjust toLonRadians to be in the range -180 to +180...
    toLonRadians = fmod((toLonRadians + 3*M_PI), (2*M_PI)) - M_PI;

    CLLocationCoordinate2D result;
    result.latitude = [self degreesFromRadians:toLatRadians];
    result.longitude = [self degreesFromRadians:toLonRadians];

    return result;
}

#pragma mark - Gesture recognizers

- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    static CGPoint startPoint;
    CGPoint point = [gesture locationInView:self.mapView];
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];

    if (!self.locations) {
        startPoint = point;
        self.locations = [NSMutableArray arrayWithObject:location];
    } else {
        if (hypot(startPoint.x - point.x, startPoint.y - point.y) > 30.0 || [self.locations count] < 2) {
            [self.locations addObject:location];
            NSInteger count = [self.locations count];
            CLLocationCoordinate2D coordinates[count];
            for (NSInteger i = 0; i < count; i++) {
                CLLocation *location = self.locations[i];
                coordinates[i] = location.coordinate;
            }

            MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coordinates count:count];
            [self.mapView addOverlay:polyline];
            if (self.polygon)
                [self.mapView removeOverlay:self.polygon];
            self.polygon = polyline;
        } else {
            [self.locations addObject:self.locations[0]];
            NSInteger count = [self.locations count];
            CLLocationCoordinate2D coordinates[count];
            for (NSInteger i = 0; i < count; i++) {
                CLLocation *location = self.locations[i];
                coordinates[i] = location.coordinate;
            }

            MKPolygon *polygon = [MKPolygon polygonWithCoordinates:coordinates count:count];
            [self.mapView addOverlay:polygon];
            if (self.polygon)
                [self.mapView removeOverlay:self.polygon];
            self.polygon = polygon;

            [self configureForEditing:NO];
        }
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
    static CLLocation *center;
    CGPoint point = [gesture locationInView:self.mapView];
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];

    if (gesture.state == UIGestureRecognizerStateBegan) {
        center = location;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        MKCircle *circle = [MKCircle circleWithCenterCoordinate:center.coordinate
                                                         radius:[center distanceFromLocation:location]];
        [self.mapView addOverlay:circle];
        if (self.circle)
            [self.mapView removeOverlay:self.circle];
        self.circle = circle;
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        [self configureForEditing:NO];
    }
}

#pragma mark - Buttons

- (IBAction)didTouchUpInsideCircleButton:(id)sender
{
    static BOOL hasShownAlert = NO;

    if (!hasShownAlert) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:@"Tap where you want the center of the circle and drag to the appropriate size. Release finger to complete the circle."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];

        hasShownAlert = YES;
    }

    if (self.circle) {
        [self.mapView removeOverlay:self.circle];
        self.circle = nil;
        self.circleView = nil;
    }

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.mapView addGestureRecognizer:pan];

    self.gesture = pan;

    [self configureForEditing:YES];
}

- (IBAction)didTouchUpInsidePolygonButton:(id)sender
{
    static BOOL hasShownAlert = NO;

    if (!hasShownAlert) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:@"Tap on the corners of the polygon. Tap on the first corner to complete the polygon."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];

        hasShownAlert = YES;
    }

    if (self.polygon) {
        [self.mapView removeOverlay:self.polygon];
        self.polygon = nil;
        self.polygonView = nil;
        self.locations = nil;
    }

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.mapView addGestureRecognizer:tap];

    self.gesture = tap;

    [self configureForEditing:YES];
}

- (void)configureForEditing:(BOOL)editing
{
    self.mapView.scrollEnabled = !editing;
    self.mapView.zoomEnabled = !editing;
    self.polygonButton.hidden = editing;
    self.circleButton.hidden = editing;
    
    if (!editing && self.gesture)
        [self.mapView removeGestureRecognizer:self.gesture];
    
    [self updateIntersectLabel];
}

@end
