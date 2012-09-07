//
//  MasterViewController.h
//  ModelViewer
//
//  Created by Adam Nagy on 24/05/2012.
//  Copyright (c) 2012 Autodek. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController * detailViewController;

@property (strong, nonatomic) NSMutableArray * names;

@end
