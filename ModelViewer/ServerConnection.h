//
//  ServerConnection.h
//  RevitServerClient
//
//  Created by Adam Nagy on 02/04/2012.
//  Copyright (c) 2012 Autodek. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Point3d

@interface Point3d : NSObject
{
    double x;
    double y;
    double z;
}

@property double x;
@property double y;
@property double z;
- (Point3d *)initWith:(double)xVal y:(double)yVal z:(double)zVal;

@end

#pragma mark - FacetData

@interface FacetData : NSObject

@property (strong, nonatomic) NSMutableArray * pts;
@property (strong, nonatomic) NSMutableArray * normals;

@end

#pragma mark - FaceData

@interface FaceData : NSObject

@property (strong, nonatomic) NSMutableArray * facets;
@property GLfloat red;
@property GLfloat green;
@property GLfloat blue;
@end

@interface ServerConnection : NSObject 

// Constants used to represent your AWS Credentials.
#define ACCESS_KEY_ID          @""
#define SECRET_KEY             @""

// Constants for the Bucket and Object name.
#define PICTURE_BUCKET         @"nagyad"

+ (void)showAlert:(NSString *)message withTitle:(NSString *)title;

+ (NSMutableArray *)getItemNames;

+ (NSMutableArray *)getFacets:(NSString *)withName;

@end
