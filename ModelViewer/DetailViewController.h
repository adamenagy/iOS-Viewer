//
//  DetailViewController.h
//  ModelViewer
//
//  Created by Adam Nagy on 24/05/2012.
//  Copyright (c) 2012 Autodek. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <GLKit/GLKit.h>

#import "ServerConnection.h"

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, GLKViewDelegate> 

@property (weak, nonatomic) IBOutlet UIBarButtonItem *statusButton;

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) NSMutableArray * bodies;

@property (strong, nonatomic) Point3d * minPt;
@property (strong, nonatomic) Point3d * maxPt;

@end
