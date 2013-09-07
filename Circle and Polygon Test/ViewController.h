//
//  ViewController.h
//  Circle and Polygon Test
//
//  Created by Robert Ryan on 9/7/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MKMapView;

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *polygonButton;
@property (weak, nonatomic) IBOutlet UIButton *circleButton;
@property (weak, nonatomic) IBOutlet UILabel *intersectLabel;

- (IBAction)didTouchUpInsideCircleButton:(id)sender;
- (IBAction)didTouchUpInsidePolygonButton:(id)sender;

@end
